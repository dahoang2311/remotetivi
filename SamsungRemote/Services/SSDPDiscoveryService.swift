import Foundation
import Network
import Combine
#if canImport(Darwin)
import Darwin
#endif

/// Discovers Samsung Smart TVs on the local Wi-Fi network using SSDP (UPnP) and fast REST subnet probing.
final class SSDPDiscoveryService: ObservableObject {
    @Published var discoveredDevices: [SamsungDevice] = []
    @Published var isScanning: Bool = false
    
    private var udpConnection: NWConnection?
    private var scanCancellables = Set<AnyCancellable>()
    private var seenIPs = Set<String>()
    private let discoveryQueue = DispatchQueue(label: "com.samsungremote.discovery", qos: .userInitiated)
    
    // SSDP M-SEARCH broadcast target
    private let ssdpHost = "239.255.255.250"
    private let ssdpPort: UInt16 = 1900
    
    // SSDP Search Targets
    private let searchTargets = [
        "urn:samsung.com:device:RemoteControlReceiver:1",
        "urn:dial-multiscreen-org:service:dial:1",
        "ssdp:all"
    ]
    
    /// Starts local network discovery for Samsung TVs.
    func startDiscovery(timeout: TimeInterval = 6.0) {
        guard !isScanning else { return }
        
        DispatchQueue.main.async {
            self.isScanning = true
            self.discoveredDevices.removeAll()
            self.seenIPs.removeAll()
        }
        
        // 1. Send SSDP M-SEARCH broadcast via UDP
        sendSSDPDiscovery()
        
        // 2. Perform parallel fast subnet scan on common Wi-Fi IP ranges to bypass router multicast blocks
        probeLocalSubnet()
        
        // Automatic scan stop timer
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.stopDiscovery()
        }
    }
    
    /// Stops the network discovery scan.
    func stopDiscovery() {
        udpConnection?.cancel()
        udpConnection = nil
        DispatchQueue.main.async {
            self.isScanning = false
        }
    }
    
    // MARK: - SSDP UDP Multicast
    
    private func sendSSDPDiscovery() {
        guard let host = NWEndpoint.Host(ssdpHost).asNWHost(),
              let port = NWEndpoint.Port(rawValue: ssdpPort) else {
            return
        }
        
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        
        let connection = NWConnection(host: host, port: port, using: params)
        self.udpConnection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            if case .ready = state {
                // Send M-SEARCH for each target
                for target in self.searchTargets {
                    let searchPacket = "M-SEARCH * HTTP/1.1\r\n" +
                                       "HOST: 239.255.255.250:1900\r\n" +
                                       "MAN: \"ssdp:discover\"\r\n" +
                                       "MX: 3\r\n" +
                                       "ST: \(target)\r\n\r\n"
                    
                    if let data = searchPacket.data(using: .utf8) {
                        connection.send(content: data, completion: .idempotent)
                    }
                }
                self.receiveSSDPResponses(on: connection)
            }
        }
        
        connection.start(queue: discoveryQueue)
    }
    
    private func receiveSSDPResponses(on connection: NWConnection) {
        connection.receiveMessage { [weak self] content, context, isComplete, error in
            guard let self = self else { return }
            
            if let data = content, let response = String(data: data, encoding: .utf8) {
                self.parseSSDPResponse(response)
            }
            
            if error == nil && self.isScanning {
                self.receiveSSDPResponses(on: connection)
            }
        }
    }
    
    private func parseSSDPResponse(_ response: String) {
        // Look for LOCATION header containing IP address (e.g., LOCATION: http://192.168.1.150:8001/...)
        let lines = response.components(separatedBy: "\r\n")
        for line in lines {
            if line.uppercased().hasPrefix("LOCATION:") {
                let parts = line.components(separatedBy: " ")
                if parts.count > 1, let url = URL(string: parts[1]), let host = url.host {
                    verifyAndAddDevice(ip: host)
                }
            }
        }
    }
    
    // MARK: - Local Subnet Prober (Resiliency against router UDP multicast blocking)
    
    private func probeLocalSubnet() {
        guard let localIP = getWiFiAddress() else { return }
        let components = localIP.components(separatedBy: ".")
        guard components.count == 4 else { return }
        
        let baseSubnet = "\(components[0]).\(components[1]).\(components[2])"
        let currentHostNum = Int(components[3]) ?? 0
        
        // Prioritize scanning likely TV IPs near the phone and standard DHCP ranges
        var candidateIPs: [String] = []
        for offset in 1...254 {
            if offset != currentHostNum {
                candidateIPs.append("\(baseSubnet).\(offset)")
            }
        }
        
        // Scan with bounded concurrency
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 20)
        
        discoveryQueue.async { [weak self] in
            guard let self = self else { return }
            for ip in candidateIPs {
                guard self.isScanning else { break }
                semaphore.wait()
                group.enter()
                
                self.checkSamsungREST(ip: ip) {
                    semaphore.signal()
                    group.leave()
                }
            }
        }
    }
    
    private func checkSamsungREST(ip: String, completion: @escaping () -> Void) {
        guard !seenIPs.contains(ip), let url = URL(string: "http://\(ip):8001/api/v2/") else {
            completion()
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.2
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer { completion() }
            guard let self = self, error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                return
            }
            
            if let info = try? JSONDecoder().decode(SamsungDeviceInfoResponse.self, from: data) {
                let name = info.name ?? "Samsung Smart TV"
                let model = info.device?.modelName ?? "Tizen TV"
                let mac = info.device?.wifiMac ?? info.device?.mac ?? ""
                let uuid = info.id ?? UUID().uuidString
                
                let device = SamsungDevice(
                    uuid: uuid,
                    name: name,
                    ipAddress: ip,
                    macAddress: mac,
                    modelName: model
                )
                
                self.addDiscoveredDevice(device)
            }
        }.resume()
    }
    
    private func verifyAndAddDevice(ip: String) {
        guard !seenIPs.contains(ip) else { return }
        
        SamsungTVService.fetchDeviceInfo(ip: ip) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let device):
                self.addDiscoveredDevice(device)
            case .failure:
                // Add fallback placeholder with IP if REST info fetch was limited
                let fallback = SamsungDevice(
                    uuid: UUID().uuidString,
                    name: "Samsung TV (\(ip))",
                    ipAddress: ip,
                    modelName: "Smart TV"
                )
                self.addDiscoveredDevice(fallback)
            }
        }
    }
    
    private func addDiscoveredDevice(_ device: SamsungDevice) {
        discoveryQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.seenIPs.contains(device.ipAddress) else { return }
            self.seenIPs.insert(device.ipAddress)
            
            DispatchQueue.main.async {
                if !self.discoveredDevices.contains(where: { $0.ipAddress == device.ipAddress }) {
                    self.discoveredDevices.append(device)
                    HapticManager.shared.triggerSelection()
                }
            }
        }
    }
    
    // MARK: - Wi-Fi IP Helper
    
    private func getWiFiAddress() -> String? {
        #if canImport(Darwin)
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(firstAddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            guard let ifaAddr = ptr.pointee.ifa_addr else { continue }
            
            // Check for running, non-loopback IPv4 interface (typically en0 for Wi-Fi)
            if (flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING) {
                if ifaAddr.pointee.sa_family == UInt8(AF_INET) {
                    let name = String(cString: ptr.pointee.ifa_name)
                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(ifaAddr, socklen_t(ifaAddr.pointee.sa_len), &hostname, socklen_t(hostname.count),
                                       nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            address = String(cString: hostname)
                        }
                    }
                }
            }
        }
        return address
        #else
        return nil
        #endif
    }
}

private extension String {
    func asNWHost() -> NWEndpoint.Host? {
        return NWEndpoint.Host(self)
    }
}

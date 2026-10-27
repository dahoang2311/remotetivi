import Foundation
import Network

/// Sends Wake-On-LAN (WOL) magic packets over UDP to turn on Samsung Smart TVs in standby mode.
final class WakeOnLANService {
    static let shared = WakeOnLANService()
    
    private init() {}
    
    /// Parses a MAC address string (e.g. "A0:B1:C2:D3:E4:F5", "A0-B1-C2-D3-E4-F5", or "A0B1C2D3E4F5") into 6 bytes.
    static func parseMacAddress(_ macString: String) -> [UInt8]? {
        let cleaned = macString
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard cleaned.count == 12 else { return nil }
        
        var bytes = [UInt8]()
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2)
            let byteString = cleaned[index..<nextIndex]
            if let byte = UInt8(byteString, radix: 16) {
                bytes.append(byte)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
    
    /// Builds the standard 102-byte Magic Packet: 6 bytes of 0xFF followed by 16 repetitions of target MAC.
    static func buildMagicPacket(macBytes: [UInt8]) -> Data? {
        guard macBytes.count == 6 else { return nil }
        var packet = [UInt8](repeating: 0xFF, count: 6)
        for _ in 0..<16 {
            packet.append(contentsOf: macBytes)
        }
        return Data(packet)
    }
    
    /// Helper function for Wake-on-LAN: broadcasts magic packet to port 9 and port 7.
    static func sendWakeOnLAN(macAddress: String, completion: ((Bool) -> Void)? = nil) {
        shared.wake(macAddress: macAddress, completion: completion)
    }
    
    /// Sends a Wake-on-LAN magic packet to broadcast address (ports 9 & 7).
    func wake(macAddress: String, targetHost: String = "255.255.255.255", completion: ((Bool) -> Void)? = nil) {
        guard let macBytes = Self.parseMacAddress(macAddress),
              let packet = Self.buildMagicPacket(macBytes: macBytes) else {
            completion?(false)
            return
        }
        
        let ports: [UInt16] = [9, 7]
        let group = DispatchGroup()
        var overallSuccess = false
        
        for portNum in ports {
            guard let host = NWEndpoint.Host(targetHost).asHost(),
                  let port = NWEndpoint.Port(rawValue: portNum) else {
                continue
            }
            
            group.enter()
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            
            let connection = NWConnection(host: host, port: port, using: params)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.send(content: packet, completion: .contentProcessed({ error in
                        connection.cancel()
                        if error == nil { overallSuccess = true }
                        group.leave()
                    }))
                case .failed, .cancelled:
                    group.leave()
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .userInitiated))
        }
        
        group.notify(queue: .main) {
            completion?(overallSuccess)
        }
    }
}

private extension String {
    func asHost() -> NWEndpoint.Host? {
        return NWEndpoint.Host(self)
    }
}

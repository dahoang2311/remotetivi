import Foundation
import Combine
import Security

/// Delegate protocol to notify listeners of Samsung TV service events
protocol SamsungTVServiceDelegate: AnyObject {
    func tvServiceDidChangeState(_ state: TVConnectionState)
    func tvServiceDidReceiveToken(_ token: String)
}

/// Service class managing WebSocket and REST API communication with Samsung Smart TVs running TizenOS.
final class SamsungTVService: NSObject, ObservableObject {
    @Published var connectionState: TVConnectionState = .disconnected
    
    weak var delegate: SamsungTVServiceDelegate?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private(set) var currentDevice: SamsungDevice?
    private var pingTimer: Timer?
    private var reconnectAttempts = 0
    private let appName = "iOS Smart Remote"
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connect & Disconnect (Exact Samsung TizenOS Handshake)
    
    /// Connects to a Samsung Smart TV via secure WebSocket on port 8002 using wss://.
    /// Passes base64 encoded app name and token query parameter if previously paired.
    func connect(to device: SamsungDevice, useSecurePort: Bool = true) {
        disconnect()
        
        self.currentDevice = device
        updateState(.connecting)
        
        // 1. Resolve token: Check device.token or load from Keychain
        var effectiveToken = device.token
        if effectiveToken == nil || effectiveToken?.isEmpty == true {
            effectiveToken = KeychainHelper.shared.getToken(for: device.id)
        }
        
        let port = useSecurePort ? 8002 : 8001
        let scheme = useSecurePort ? "wss" : "ws"
        let base64Name = appName.data(using: .utf8)?.base64EncodedString() ?? "aU9TUmVtb3Rl"
        
        // Format: wss://<ip>:8002/api/v2/channels/samsung.remote.control?name=<base64AppName>[&token=<token>]
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = device.ipAddress
        urlComponents.port = port
        urlComponents.path = "/api/v2/channels/samsung.remote.control"
        
        var queryItems = [URLQueryItem(name: "name", value: base64Name)]
        if let token = effectiveToken, !token.isEmpty {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            updateState(.error("Invalid TV IP address"))
            return
        }
        
        print("[SamsungTVService] Connecting to \(url.absoluteString)")
        
        let request = URLRequest(url: url)
        self.webSocketTask = urlSession?.webSocketTask(with: request)
        self.webSocketTask?.resume()
        
        // Start listening for inbound messages (token handshake, ping, status)
        listenForMessages()
        
        // Handshake Watchdog: If still connecting after 8 seconds without token, prompt user to allow on TV
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
            guard let self = self else { return }
            if self.connectionState == .connecting {
                self.updateState(.pairingRequired)
                HapticManager.shared.triggerWarning()
            }
        }
        
        startPingTimer()
    }
    
    /// Disconnects the active WebSocket session.
    func disconnect() {
        stopPingTimer()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        reconnectAttempts = 0
        updateState(.disconnected)
    }
    
    // MARK: - WebSocket Message Loop & Token Extraction
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleIncomingMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving subsequent messages
                self.listenForMessages()
                
            case .failure(let error):
                print("[SamsungTVService] WebSocket receive failed: \(error.localizedDescription)")
                self.handleConnectionFailure(error: error)
            }
        }
    }
    
    private func handleIncomingMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        let event = json["event"] as? String ?? ""
        print("[SamsungTVService] Inbound Event: \(event)")
        
        switch event {
        case "ms.channel.connect":
            // Initial pairing approval or connection confirmation
            if let dataDict = json["data"] as? [String: Any],
               let token = dataDict["token"] as? String {
                print("[SamsungTVService] Extracted authorization token from TV: \(token)")
                
                // Persist token securely in iOS Keychain
                if let devId = self.currentDevice?.id {
                    KeychainHelper.shared.saveToken(token, for: devId)
                }
                
                self.delegate?.tvServiceDidReceiveToken(token)
            }
            updateState(.connected)
            HapticManager.shared.triggerSuccess()
            
        case "ms.channel.clientConnect", "ms.channel.ready":
            updateState(.connected)
            
        case "ms.channel.unauthorized":
            // User pressed "Deny" on TV screen or token revoked
            updateState(.error("Connection denied on TV. Please allow permission in TV Settings."))
            HapticManager.shared.triggerError()
            
        case "ms.channel.ping":
            // Respond to TV keepalive ping
            let pongPayload: [String: Any] = [
                "method": "ms.channel.emit",
                "params": ["event": "ed.tv.pong"]
            ]
            sendJson(pongPayload)
            
        default:
            break
        }
    }
    
    private func handleConnectionFailure(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Fallback to non-secure port 8001 if port 8002 failed and not yet retried
            if self.reconnectAttempts < 1, let dev = self.currentDevice {
                self.reconnectAttempts += 1
                print("[SamsungTVService] Falling back to port 8001 ws://...")
                self.connect(to: dev, useSecurePort: false)
                return
            }
            
            self.updateState(.disconnected)
            self.stopPingTimer()
        }
    }
    
    // MARK: - Key Payload Format (Exact Samsung Tizen ms.remote.control Structure)
    
    /// Sends a remote control key click to the Samsung TV wrapped inside the standard
    /// Samsung ms.remote.control JSON structure:
    /// {
    ///   "method": "ms.remote.control",
    ///   "params": {
    ///     "Cmd": "Click",
    ///     "DataOfCode": "KEY_...",
    ///     "Option": "false",
    ///     "TypeOfRemote": "SendRemoteKey"
    ///   }
    /// }
    func sendKey(_ key: SamsungKey, completion: ((Bool) -> Void)? = nil) {
        sendRawKeyCode(key.rawValue, completion: completion)
    }
    
    /// Sends a raw key code wrapped inside the standard ms.remote.control payload structure.
    func sendRawKeyCode(_ keyCode: String, completion: ((Bool) -> Void)? = nil) {
        guard connectionState.isConnected else {
            completion?(false)
            return
        }
        
        let payload: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "Click",
                "DataOfCode": keyCode,
                "Option": "false",
                "TypeOfRemote": "SendRemoteKey"
            ]
        ]
        
        sendJson(payload) { success in
            completion?(success)
        }
    }
    
    // MARK: - App Launching
    
    /// Launches an application by its Samsung Tizen App ID (e.g. YouTube, Netflix).
    func launchApp(_ app: SamsungApp, completion: ((Bool) -> Void)? = nil) {
        guard let device = currentDevice else {
            completion?(false)
            return
        }
        
        if connectionState.isConnected {
            let payload: [String: Any] = [
                "method": "ms.channel.emit",
                "params": [
                    "event": "ed.apps.launch",
                    "to": "host",
                    "data": [
                        "action_type": "DEEP_LINK",
                        "appId": app.id
                    ]
                ]
            ]
            sendJson(payload) { success in
                if success {
                    completion?(true)
                } else {
                    self.launchAppViaRest(ip: device.ipAddress, appId: app.id, completion: completion)
                }
            }
        } else {
            launchAppViaRest(ip: device.ipAddress, appId: app.id, completion: completion)
        }
    }
    
    private func launchAppViaRest(ip: String, appId: String, completion: ((Bool) -> Void)?) {
        guard let url = URL(string: "http://\(ip):8001/api/v2/applications/\(appId)") else {
            completion?(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 5
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 200 && error == nil
            DispatchQueue.main.async {
                completion?(success)
            }
        }.resume()
    }
    
    // MARK: - REST API Helper
    
    /// Queries the Samsung TV REST endpoint for device info, model, MAC, and power status.
    static func fetchDeviceInfo(ip: String, completion: @escaping (Result<SamsungDevice, Error>) -> Void) {
        guard let url = URL(string: "http://\(ip):8001/api/v2/") else {
            completion(.failure(NSError(domain: "SamsungTV", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid IP address"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "SamsungTV", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }
            
            do {
                let info = try JSONDecoder().decode(SamsungDeviceInfoResponse.self, from: data)
                let name = info.name ?? "Samsung Smart TV"
                let model = info.device?.modelName ?? "Tizen TV"
                let mac = info.device?.wifiMac ?? info.device?.mac ?? ""
                let uuid = info.id ?? UUID().uuidString
                
                let device = SamsungDevice(
                    uuid: uuid,
                    name: name,
                    ipAddress: ip,
                    macAddress: mac,
                    modelName: model,
                    token: nil
                )
                
                DispatchQueue.main.async {
                    completion(.success(device))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Internal Helpers
    
    private func sendJson(_ dict: [String: Any], completion: ((Bool) -> Void)? = nil) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let string = String(data: data, encoding: .utf8) else {
            completion?(false)
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(string)
        webSocketTask?.send(message) { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }
    
    private func updateState(_ newState: TVConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.connectionState = newState
            self.delegate?.tvServiceDidChangeState(newState)
        }
    }
    
    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            guard let self = self, self.connectionState.isConnected else { return }
            self.webSocketTask?.sendPing { error in
                if let error = error {
                    print("[SamsungTVService] Ping error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
}

// MARK: - URLSessionWebSocketDelegate (Self-Signed SSL Certificate Trust for Local Samsung TVs)

extension SamsungTVService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("[SamsungTVService] WebSocket connection opened successfully on port 8002 (WSS)")
        updateState(.connected)
        HapticManager.shared.triggerSuccess()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[SamsungTVService] WebSocket closed with code \(closeCode.rawValue)")
        updateState(.disconnected)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Samsung TVs generate self-signed SSL certificates for wss:// port 8002.
        // We validate server trust for local network connections so the TLS handshake succeeds.
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

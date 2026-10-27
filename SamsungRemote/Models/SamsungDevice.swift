import Foundation

/// Represents a Samsung Smart TV discovered on the local network or added manually.
struct SamsungDevice: Identifiable, Codable, Equatable, Hashable {
    var id: String { uuid.isEmpty ? "\(ipAddress):\(macAddress)" : uuid }
    
    var uuid: String
    var name: String
    var ipAddress: String
    var macAddress: String
    var modelName: String
    var token: String?
    var isPaired: Bool {
        return token != nil && !(token?.isEmpty ?? true)
    }
    
    init(
        uuid: String = UUID().uuidString,
        name: String = "Samsung Smart TV",
        ipAddress: String,
        macAddress: String = "",
        modelName: String = "Tizen TV",
        token: String? = nil
    ) {
        self.uuid = uuid
        self.name = name
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.modelName = modelName
        self.token = token
    }
    
    // Default placeholder for preview
    static let preview = SamsungDevice(
        uuid: "PREVIEW-DEVICE-001",
        name: "Living Room Samsung TV",
        ipAddress: "192.168.1.150",
        macAddress: "A0:B1:C2:D3:E4:F5",
        modelName: "Neo QLED 4K (QN90B)",
        token: "12345678"
    )
}

/// Information returned from Samsung REST API /api/v2/
struct SamsungDeviceInfoResponse: Codable {
    let id: String?
    let name: String?
    let version: String?
    let device: DeviceDetail?
    
    struct DeviceDetail: Codable {
        let type: String?
        let modelName: String?
        let mac: String?
        let wifiMac: String?
        let tokenAuthSupport: String?
        let powerState: String?
    }
}

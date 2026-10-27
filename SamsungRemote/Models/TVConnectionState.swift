import SwiftUI

/// Represents the connection state with the Samsung Smart TV.
enum TVConnectionState: Equatable {
    case disconnected
    case connecting
    case pairingRequired // TV is showing "Allow remote connection" prompt
    case connected
    case error(String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
    
    var isConnecting: Bool {
        if case .connecting = self { return true }
        if case .pairingRequired = self { return true }
        return false
    }
    
    var statusTitle: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .pairingRequired:
            return "Allow on TV Screen"
        case .connected:
            return "Connected"
        case .error(let msg):
            return "Error: \(msg)"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .disconnected:
            return Color(white: 0.4)
        case .connecting:
            return Color.orange
        case .pairingRequired:
            return Color.yellow
        case .connected:
            return Color.green
        case .error:
            return Color.red
        }
    }
    
    var statusIcon: String {
        switch self {
        case .disconnected:
            return "tv.slash"
        case .connecting:
            return "arrow.triangle.2.circlepath"
        case .pairingRequired:
            return "hand.tap.fill"
        case .connected:
            return "tv"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

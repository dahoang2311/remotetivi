import SwiftUI

/// Top visual status pill showing real-time TV connection status and active device name.
struct ConnectionStatusBadge: View {
    let state: TVConnectionState
    let deviceName: String?
    let onTap: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Pulsing Status Dot
                ZStack {
                    if state.isConnecting || state.isConnected {
                        Circle()
                            .fill(state.statusColor.opacity(0.3))
                            .frame(width: 14, height: 14)
                            .scaleEffect(isPulsing ? 1.5 : 1.0)
                            .opacity(isPulsing ? 0.0 : 0.8)
                            .animation(
                                .easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                                value: isPulsing
                            )
                    }
                    
                    Circle()
                        .fill(state.statusColor)
                        .frame(width: 8, height: 8)
                }
                
                // Device Name or Status Title
                VStack(alignment: .leading, spacing: 1) {
                    Text(deviceName ?? "No TV Selected")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(state.statusTitle)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(state.statusColor)
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color(white: 0.14).opacity(0.85))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.96))
        .onAppear {
            isPulsing = true
        }
    }
}

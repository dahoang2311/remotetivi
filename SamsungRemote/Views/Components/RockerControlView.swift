import SwiftUI

/// Vertical rocker control for Volume (VOL + / VOL -) and Channel (CH ∧ / CH ∨).
struct RockerControlView: View {
    let topIcon: String
    let bottomIcon: String
    let label: String
    let onTopAction: () -> Void
    let onBottomAction: () -> Void
    
    var width: CGFloat = 58
    var height: CGFloat = 138
    
    var body: some View {
        ZStack {
            // Rocker Capsule Body
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.19),
                            Color(white: 0.13)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
            
            // Vertical split content
            VStack(spacing: 0) {
                // Top Button
                Button(action: onTopAction) {
                    VStack {
                        Spacer()
                        Image(systemName: topIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.88))
                
                // Center Label & Subtle Divider
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                    
                    Text(label)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .fixedSize()
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                }
                .padding(.horizontal, 6)
                
                // Bottom Button
                Button(action: onBottomAction) {
                    VStack {
                        Spacer()
                        Image(systemName: bottomIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.88))
            }
        }
        .frame(width: width, height: height)
    }
}

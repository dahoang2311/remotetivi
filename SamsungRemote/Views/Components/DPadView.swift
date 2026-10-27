import SwiftUI

/// Premium circular D-Pad controller matching Apple TV / Samsung SolarCell remote ergonomics.
struct DPadView: View {
    let onDirection: (SamsungKey) -> Void
    var size: CGFloat = 224
    
    @State private var activeDirection: SamsungKey? = nil
    
    var body: some View {
        ZStack {
            // Outer Ring Background with subtle glass reflection and border
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.18),
                            Color(white: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 8)
            
            // Directional Buttons (Up, Down, Left, Right)
            VStack {
                // Up Button
                dpadDirectionButton(
                    key: .up,
                    icon: "chevron.up",
                    alignment: .top
                )
                .frame(width: size * 0.44, height: size * 0.30)
                
                Spacer()
                
                // Down Button
                dpadDirectionButton(
                    key: .down,
                    icon: "chevron.down",
                    alignment: .bottom
                )
                .frame(width: size * 0.44, height: size * 0.30)
            }
            .frame(width: size, height: size)
            
            HStack {
                // Left Button
                dpadDirectionButton(
                    key: .left,
                    icon: "chevron.left",
                    alignment: .leading
                )
                .frame(width: size * 0.30, height: size * 0.44)
                
                Spacer()
                
                // Right Button
                dpadDirectionButton(
                    key: .right,
                    icon: "chevron.right",
                    alignment: .trailing
                )
                .frame(width: size * 0.30, height: size * 0.44)
            }
            .frame(width: size, height: size)
            
            // Center OK / Enter Button
            Button(action: {
                onDirection(.enter)
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.28),
                                    Color(white: 0.19)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size * 0.38, height: size * 0.38)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    Text("OK")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Subviews
    
    private func dpadDirectionButton(
        key: SamsungKey,
        icon: String,
        alignment: Alignment
    ) -> some View {
        Button(action: {
            onDirection(key)
        }) {
            ZStack(alignment: alignment) {
                Color.clear
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.85))
                    .padding(alignment == .top ? .top :
                             alignment == .bottom ? .bottom :
                             alignment == .leading ? .leading : .trailing, 14)
            }
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.88))
    }
}

/// Subtle spring press animation for D-Pad buttons
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.92
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

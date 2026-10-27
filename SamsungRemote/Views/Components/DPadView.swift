import SwiftUI

/// Premium circular D-Pad controller matching Apple TV / Samsung SolarCell remote ergonomics.
struct DPadView: View {
    let onDirection: (SamsungKey) -> Void
    var size: CGFloat = 224
    
    @State private var activeDirection: SamsungKey? = nil
    
    var body: some View {
        ZStack {
            // Outer Ring: Vibrant Sky-to-Royal Blue Circular D-Pad
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.62, blue: 0.98),
                            Color(red: 0.07, green: 0.44, blue: 0.92)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color.blue.opacity(0.35), radius: 14, x: 0, y: 6)
            
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
            
            // Center OK / Enter Button (Thin circular white border ring with "ok")
            Button(action: {
                onDirection(.enter)
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.58, blue: 0.96),
                                    Color(red: 0.08, green: 0.45, blue: 0.90)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.42, height: size * 0.42)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.55), lineWidth: 1.5)
                        )
                    
                    Text("ok")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.90))
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

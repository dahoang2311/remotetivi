import SwiftUI

/// Tactile remote button with iOS dark aesthetic, glassmorphism, pressed state, and haptic feedback.
struct RemoteButton: View {
    let icon: String?
    let title: String?
    let action: () -> Void
    var width: CGFloat? = nil
    var height: CGFloat = 54
    var tintColor: Color = .white
    var backgroundColor: Color = Color(white: 0.16)
    var borderColor: Color? = nil
    var borderWidth: CGFloat = 1
    var isPill: Bool = false
    var isCircle: Bool = false
    var glowColor: Color? = nil
    
    init(
        icon: String? = nil,
        title: String? = nil,
        width: CGFloat? = nil,
        height: CGFloat = 54,
        tintColor: Color = .white,
        backgroundColor: Color = Color(white: 0.16),
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1,
        isPill: Bool = false,
        isCircle: Bool = false,
        glowColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.width = width
        self.height = height
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.isPill = isPill
        self.isCircle = isCircle
        self.glowColor = glowColor
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                // Background & Glass styling
                if isCircle {
                    if backgroundColor == .clear {
                        Circle()
                            .stroke(borderColor ?? Color.white.opacity(0.12), lineWidth: borderWidth)
                    } else {
                        Circle()
                            .fill(buttonGradient)
                            .overlay(
                                Circle()
                                    .stroke(borderColor ?? Color.white.opacity(0.12), lineWidth: borderWidth)
                            )
                    }
                } else if isPill {
                    if backgroundColor == .clear {
                        Capsule()
                            .stroke(borderColor ?? Color.white.opacity(0.12), lineWidth: borderWidth)
                    } else {
                        Capsule()
                            .fill(buttonGradient)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor ?? Color.white.opacity(0.12), lineWidth: borderWidth)
                            )
                    }
                } else {
                    if backgroundColor == .clear {
                        RoundedRectangle(cornerRadius: height / 2.8, style: .continuous)
                            .stroke(borderColor ?? Color.white.opacity(0.12), lineWidth: borderWidth)
                    } else {
                        RoundedRectangle(cornerRadius: height / 2.8, style: .continuous)
                            .fill(buttonGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: height / 2.8, style: .continuous)
                                    .stroke(borderColor ?? Color.white.opacity(0.12), lineWidth: borderWidth)
                            )
                    }
                }
                
                // Content
                HStack(spacing: 6) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 19, weight: .semibold))
                    }
                    if let title = title {
                        Text(title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(tintColor)
            }
            .frame(width: width, height: height)
            .shadow(color: glowColor?.opacity(0.4) ?? Color.black.opacity(0.35),
                    radius: glowColor != nil ? 10 : 6, x: 0, y: 3)
        }
        .buttonStyle(TactileButtonStyle(scale: 0.92))
    }
    
    private var buttonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                backgroundColor.opacity(0.85),
                backgroundColor.opacity(0.65)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Custom button style that provides interactive tactile pressed animation
struct TactileButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.92
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

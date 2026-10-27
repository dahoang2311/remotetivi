import SwiftUI

/// Slide-up numeric keypad for entering TV channels and digital codes.
struct NumericKeypadSheet: View {
    let onKeyPress: (SamsungKey) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    // Keypad layout: 3 columns x 4 rows
    private let keyRows: [[SamsungKey]] = [
        [.num1, .num2, .num3],
        [.num4, .num5, .num6],
        [.num7, .num8, .num9],
        [.dot, .num0, .previousChannel]
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Drag Indicator Pill
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                
                // Header
                HStack {
                    Text("Number Pad")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 24)
                
                // Keypad Grid
                VStack(spacing: 14) {
                    ForEach(keyRows, id: \.self) { row in
                        HStack(spacing: 16) {
                            ForEach(row) { key in
                                keypadButton(key)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Color Shortcuts Row (Red, Green, Yellow, Blue for TV Teletext / Smart Hub)
                HStack(spacing: 16) {
                    colorKeyButton(color: .red, key: .red)
                    colorKeyButton(color: .green, key: .green)
                    colorKeyButton(color: .yellow, key: .yellow)
                    colorKeyButton(color: .cyan, key: .blue)
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
                
                Spacer(minLength: 12)
            }
        }
    }
    
    private func keypadButton(_ key: SamsungKey) -> some View {
        Button(action: {
            onKeyPress(key)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(white: 0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                
                if let symbol = key.sfSymbol {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text(key.displayName)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(height: 60)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.90))
    }
    
    private func colorKeyButton(color: Color, key: SamsungKey) -> some View {
        Button(action: {
            onKeyPress(key)
        }) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.92))
    }
}

import SwiftUI

/// Interactive smart keyboard sheet allowing users to type full words and sentences on iPhone
/// and transmit them directly to Samsung Smart TV (e.g. YouTube search, Netflix, Browser).
struct SmartKeyboardSheet: View {
    let onSendText: (String) -> Void
    let onSendKey: (SamsungKey) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var inputText: String = ""
    @State private var isLiveTypingEnabled: Bool = false
    @FocusState private var isInputFocused: Bool
    
    // Quick search suggestions
    private let quickSuggestions = ["Nhạc thiếu nhi", "Hoạt hình", "Karaoke", "Bóng đá"]
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Drag Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)
                
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bàn phím nhập chữ TV")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Gõ chữ hoặc dùng micro điện thoại để tìm kiếm trên TV")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)
                
                // Text Input Field Box
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.white.opacity(0.5))
                        .font(.system(size: 16))
                    
                    TextField("Nhập từ khóa tìm kiếm (YouTube, Phim...)", text: $inputText)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .focused($isInputFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            submitText()
                        }
                        .onChange(of: inputText) { newValue in
                            if isLiveTypingEnabled && !newValue.isEmpty {
                                // Live typing mode: send last character
                                if let lastChar = newValue.last {
                                    onSendText(String(lastChar))
                                }
                            }
                        }
                    
                    if !inputText.isEmpty {
                        Button(action: {
                            inputText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.white.opacity(0.5))
                                .font(.system(size: 17))
                        }
                    }
                    
                    // Send Button
                    Button(action: {
                        submitText()
                    }) {
                        HStack(spacing: 4) {
                            Text("Gửi")
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(inputText.isEmpty ? Color.gray.opacity(0.4) : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(white: 0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                // Quick Search Suggestions Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickSuggestions, id: \.self) { suggestion in
                            Button(action: {
                                inputText = suggestion
                                submitText()
                            }) {
                                Text(suggestion)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color(white: 0.16))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle(scale: 0.94))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Keyboard Helper Actions Row (Backspace, Space, Search/Enter)
                HStack(spacing: 12) {
                    // Backspace Button
                    Button(action: {
                        if !inputText.isEmpty {
                            inputText.removeLast()
                        }
                        // Send TV backspace keycode
                        onSendKey(.back)
                    }) {
                        HStack {
                            Image(systemName: "delete.left.fill")
                            Text("Xóa")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.16))
                        .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.94))
                    
                    // Space Bar Button
                    Button(action: {
                        inputText += " "
                        onSendText(" ")
                    }) {
                        Text("Dấu cách")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(white: 0.16))
                            .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.94))
                    
                    // Search / Enter Button
                    Button(action: {
                        onSendKey(.enter)
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Tìm")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.94))
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 10)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
    }
    
    private func submitText() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Send full text string to Samsung TV
        onSendText(trimmed)
        
        // Also send Enter key after sending text to trigger search on TV
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSendKey(.enter)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

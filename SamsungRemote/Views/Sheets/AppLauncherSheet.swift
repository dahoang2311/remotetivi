import SwiftUI

/// App drawer sheet for launching Smart TV applications on Samsung Smart Hub.
struct AppLauncherSheet: View {
    let apps: [SamsungApp]
    let onSelectApp: (SamsungApp) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Apps")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Tap to launch directly on your Samsung TV")
                            .font(.system(size: 13))
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
                .padding(.horizontal, 24)
                
                // Grid of apps
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(apps) { app in
                            Button(action: {
                                onSelectApp(app)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(app.accentColor)
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: app.iconName)
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(app.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color(white: 0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(ScaleButtonStyle(scale: 0.95))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

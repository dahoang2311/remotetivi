import SwiftUI

/// Main Remote Control Screen supporting iPhone X through iPhone 14/15/16 Pro/Pro Max (Notch & Dynamic Island).
struct ContentView: View {
    @StateObject private var viewModel = RemoteViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let isCompact = screenHeight < 700 // iPhone SE / mini adaptation
            let dpadSize: CGFloat = isCompact ? 190 : 216
            let rockerHeight: CGFloat = isCompact ? 116 : 134
            
            ZStack {
                // Background Gradient & OLED Dark Surface
                Color(red: 0.06, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                // Subtle Ambient Light Glow behind D-Pad
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.12),
                        Color.purple.opacity(0.04),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 40,
                    endRadius: 280
                )
                .ignoresSafeArea()
                
                // Main Content
                VStack(spacing: isCompact ? 10 : 16) {
                    // Top Bar: Input Source, Connection Status Pill, Power Button
                    topHeaderBar
                        .padding(.top, 4)
                    
                    // Quick Action Shortcuts: 123 Keypad, App Launcher, Search, Guide
                    utilityBar
                    
                    Spacer(minLength: 4)
                    
                    // D-Pad Navigation with Home & Back flanks
                    dpadSection(dpadSize: dpadSize)
                    
                    Spacer(minLength: 4)
                    
                    // Volume & Channel Rockers with Media Controls in Center
                    volumeChannelSection(rockerHeight: rockerHeight)
                    
                    Spacer(minLength: 4)
                    
                    // Bottom Quick App Dock
                    quickAppDock
                        .padding(.bottom, 6)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 440) // Optimal ergonomics on large Pro Max and iPad
            }
            .sheet(isPresented: $viewModel.showDiscoverySheet) {
                DeviceDiscoveryView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showKeypadSheet) {
                NumericKeypadSheet(onKeyPress: { key in
                    viewModel.sendKey(key)
                })
                .sheetPresentationMedium()
            }
            .sheet(isPresented: $viewModel.showAppLauncherSheet) {
                AppLauncherSheet(apps: SamsungApp.popularApps, onSelectApp: { app in
                    viewModel.launchApp(app)
                })
                .sheetPresentationMediumAndLarge()
            }
            .sheet(isPresented: $viewModel.showKeyboardSheet) {
                SmartKeyboardSheet(
                    onSendText: { text in
                        viewModel.sendText(text)
                    },
                    onSendKey: { key in
                        viewModel.sendKey(key)
                    }
                )
                .sheetPresentationMediumAndLarge()
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Samsung Remote"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Top Header Bar
    
    private var topHeaderBar: some View {
        HStack(spacing: 12) {
            // Source / Input Button
            RemoteButton(
                icon: "display.2",
                width: 48,
                height: 48,
                backgroundColor: Color(white: 0.15)
            ) {
                viewModel.sendKey(.source)
            }
            
            Spacer()
            
            // Central Connection Status Pill (Tappable to scan/switch TVs)
            ConnectionStatusBadge(
                state: viewModel.connectionState,
                deviceName: viewModel.activeDevice?.name
            ) {
                viewModel.showDiscoverySheet = true
            }
            
            Spacer()
            
            // Power Button (Red glowing power toggle)
            RemoteButton(
                icon: "power",
                width: 48,
                height: 48,
                tintColor: .white,
                backgroundColor: Color(red: 0.85, green: 0.18, blue: 0.22),
                glowColor: Color.red
            ) {
                viewModel.togglePower()
            }
        }
    }
    
    // MARK: - Utility Bar
    
    private var utilityBar: some View {
        HStack(spacing: 10) {
            // Number Pad (123)
            RemoteButton(
                title: "1 2 3",
                height: 40,
                backgroundColor: Color(white: 0.15),
                isPill: true
            ) {
                viewModel.showKeypadSheet = true
            }
            
            // Smart Keyboard Input (YouTube & Search Typing)
            RemoteButton(
                icon: "keyboard",
                title: "Gõ chữ",
                height: 40,
                backgroundColor: Color(white: 0.15),
                isPill: true
            ) {
                viewModel.showKeyboardSheet = true
            }
            
            // App Launcher Drawer
            RemoteButton(
                icon: "square.grid.2x2.fill",
                title: "Apps",
                height: 40,
                backgroundColor: Color(white: 0.15),
                isPill: true
            ) {
                viewModel.showAppLauncherSheet = true
            }
            
            // Menu Button
            RemoteButton(
                icon: "line.3.horizontal",
                width: 42,
                height: 40,
                backgroundColor: Color(white: 0.15),
                isPill: true
            ) {
                viewModel.sendKey(.menu)
            }
        }
    }
    
    // MARK: - D-Pad Navigation Section
    
    private func dpadSection(dpadSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Left Flank Buttons (Back & Home)
            VStack(spacing: 24) {
                RemoteButton(
                    icon: "arrow.uturn.backward",
                    width: 50,
                    height: 50,
                    backgroundColor: Color(white: 0.16)
                ) {
                    viewModel.sendKey(.back)
                }
                
                RemoteButton(
                    icon: "house.fill",
                    width: 50,
                    height: 50,
                    tintColor: .cyan,
                    backgroundColor: Color(white: 0.16)
                ) {
                    viewModel.sendKey(.home)
                }
            }
            
            // Center D-Pad
            DPadView(onDirection: { key in
                viewModel.sendKey(key)
            }, size: dpadSize)
            
            // Right Flank Buttons (Exit & Info)
            VStack(spacing: 24) {
                RemoteButton(
                    icon: "xmark",
                    width: 50,
                    height: 50,
                    backgroundColor: Color(white: 0.16)
                ) {
                    viewModel.sendKey(.exit)
                }
                
                RemoteButton(
                    icon: "info.circle",
                    width: 50,
                    height: 50,
                    backgroundColor: Color(white: 0.16)
                ) {
                    viewModel.sendKey(.info)
                }
            }
        }
    }
    
    // MARK: - Volume & Channel Rockers Section
    
    private func volumeChannelSection(rockerHeight: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 20) {
            // Volume Rocker
            RockerControlView(
                topIcon: "plus",
                bottomIcon: "minus",
                label: "VOL",
                onTopAction: { viewModel.sendKey(.volumeUp) },
                onBottomAction: { viewModel.sendKey(.volumeDown) },
                height: rockerHeight
            )
            
            // Center Media & Mute Controls
            VStack(spacing: 14) {
                // Play / Pause Toggle
                RemoteButton(
                    icon: "playpause.fill",
                    width: 54,
                    height: 50,
                    tintColor: .white,
                    backgroundColor: Color(white: 0.18)
                ) {
                    viewModel.sendKey(.play)
                }
                
                // Mute Button
                RemoteButton(
                    icon: "speaker.slash.fill",
                    width: 54,
                    height: 50,
                    tintColor: Color(red: 1.0, green: 0.6, blue: 0.2),
                    backgroundColor: Color(white: 0.18)
                ) {
                    viewModel.sendKey(.mute)
                }
            }
            
            // Channel Rocker
            RockerControlView(
                topIcon: "chevron.compact.up",
                bottomIcon: "chevron.compact.down",
                label: "CH",
                onTopAction: { viewModel.sendKey(.channelUp) },
                onBottomAction: { viewModel.sendKey(.channelDown) },
                height: rockerHeight
            )
        }
    }
    
    // MARK: - Bottom Quick App Dock
    
    private var quickAppDock: some View {
        HStack(spacing: 12) {
            ForEach(Array(SamsungApp.popularApps.prefix(4))) { app in
                Button(action: {
                    viewModel.launchApp(app)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(white: 0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(app.accentColor)
                                .frame(width: 10, height: 10)
                            
                            Text(app.name)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    .frame(height: 42)
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.94))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}

// MARK: - Safe Sheet Detents for iOS 15+ Compatibility

private extension View {
    @ViewBuilder
    func sheetPresentationMedium() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.medium])
        } else {
            self
        }
    }
    
    @ViewBuilder
    func sheetPresentationMediumAndLarge() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.medium, .large])
        } else {
            self
        }
    }
}

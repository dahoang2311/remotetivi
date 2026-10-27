import SwiftUI

/// Main Remote Control Screen supporting iPhone X through iPhone 14/15/16 Pro/Pro Max (Notch & Dynamic Island).
struct ContentView: View {
    @StateObject private var viewModel = RemoteViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let isCompact = screenHeight < 700 // iPhone SE / mini adaptation
            let dpadSize: CGFloat = isCompact ? 188 : 212
            let rockerHeight: CGFloat = isCompact ? 116 : 132
            
            ZStack {
                // Background Gradient & OLED Dark Surface
                Color(red: 0.06, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                // Subtle Ambient Light Glow behind D-Pad
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.12),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 40,
                    endRadius: 280
                )
                .ignoresSafeArea()
                
                // Main Content
                VStack(spacing: isCompact ? 8 : 12) {
                    // Top Bar: Connection Status Badge & Power Button
                    topHeaderBar
                        .padding(.top, 2)
                    
                    // Top Function Row: [Keyboard] [123] [Google Assistant]
                    topUtilityRow
                    
                    Spacer(minLength: 2)
                    
                    // D-Pad Navigation with Home, Source, Back, Exit flanks
                    dpadSection(dpadSize: dpadSize)
                    
                    Spacer(minLength: 2)
                    
                    // Volume & Channel Rockers with Center 2x2 Grid (Mute, Settings, List, Guide)
                    volumeChannelSection(rockerHeight: rockerHeight)
                    
                    Spacer(minLength: 2)
                    
                    // Media Playback Controls Row (<<, >, ||, >>)
                    playbackSection
                    
                    // Bottom Quick App Dock (YouTube, Netflix, VTV Go, FPT Play)
                    quickAppDock
                        .padding(.bottom, 4)
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
                    title: Text("DaRemote"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Top Header Bar (Safe Area)
    
    private var topHeaderBar: some View {
        HStack {
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
                width: 44,
                height: 44,
                tintColor: .white,
                backgroundColor: Color(red: 0.85, green: 0.18, blue: 0.22),
                isCircle: true,
                glowColor: Color.red
            ) {
                viewModel.togglePower()
            }
        }
    }
    
    // MARK: - Top Utility Row: Keyboard, 123, Assistant
    
    private var topUtilityRow: some View {
        HStack(spacing: 26) {
            // 1. Smart Keyboard
            RemoteButton(
                icon: "keyboard",
                width: 58,
                height: 58,
                backgroundColor: Color(white: 0.18),
                isCircle: true
            ) {
                viewModel.showKeyboardSheet = true
            }
            
            // 2. 123 Keypad
            RemoteButton(
                title: "123",
                width: 58,
                height: 58,
                backgroundColor: Color(white: 0.18),
                isCircle: true
            ) {
                viewModel.showKeypadSheet = true
            }
            
            // 3. Assistant / Voice Search (4 Google colored dots)
            Button(action: {
                viewModel.sendKey(.voice)
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.22), Color(white: 0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    
                    HStack(spacing: 3.5) {
                        Circle().fill(Color.blue).frame(width: 5.5, height: 5.5)
                        Circle().fill(Color.red).frame(width: 5.5, height: 5.5)
                        Circle().fill(Color.yellow).frame(width: 5.5, height: 5.5)
                        Circle().fill(Color.green).frame(width: 5.5, height: 5.5)
                    }
                }
            }
            .buttonStyle(TactileButtonStyle(scale: 0.92))
        }
    }
    
    // MARK: - D-Pad Navigation Section with Corner Flanks
    
    private func dpadSection(dpadSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Left Flank: Home (top) and Back (bottom)
            VStack {
                Button(action: { viewModel.sendKey(.home) }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                }
                .buttonStyle(TactileButtonStyle())
                
                Spacer()
                    .frame(height: dpadSize * 0.44)
                
                Button(action: { viewModel.sendKey(.back) }) {
                    Image(systemName: "arrow.backward")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                }
                .buttonStyle(TactileButtonStyle())
            }
            
            // Center Circular Vibrant Blue D-Pad
            DPadView(onDirection: { key in
                viewModel.sendKey(key)
            }, size: dpadSize)
            
            // Right Flank: Source (top) and Exit (bottom)
            VStack {
                Button(action: { viewModel.sendKey(.source) }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                }
                .buttonStyle(TactileButtonStyle())
                
                Spacer()
                    .frame(height: dpadSize * 0.44)
                
                Button(action: { viewModel.sendKey(.exit) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                }
                .buttonStyle(TactileButtonStyle())
            }
        }
    }
    
    // MARK: - Volume & Channel Rockers Section with Center 2x2 Grid
    
    private func volumeChannelSection(rockerHeight: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Volume Rocker (+, vol, -)
            RockerControlView(
                topIcon: "plus",
                bottomIcon: "minus",
                label: "vol",
                onTopAction: { viewModel.sendKey(.volumeUp) },
                onBottomAction: { viewModel.sendKey(.volumeDown) },
                width: 58,
                height: rockerHeight
            )
            
            // Center 2x2 Grid: Mute, Settings, List, Guide
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    // Mute
                    RemoteButton(
                        icon: "speaker.slash.fill",
                        width: 52,
                        height: 52,
                        backgroundColor: Color(white: 0.18),
                        isCircle: true
                    ) {
                        viewModel.sendKey(.mute)
                    }
                    
                    // Settings / Tools
                    RemoteButton(
                        icon: "gearshape.fill",
                        width: 52,
                        height: 52,
                        backgroundColor: Color(white: 0.18),
                        isCircle: true
                    ) {
                        viewModel.sendKey(.tools)
                    }
                }
                
                HStack(spacing: 14) {
                    // List
                    RemoteButton(
                        title: "list",
                        width: 52,
                        height: 52,
                        backgroundColor: Color(white: 0.18),
                        isCircle: true
                    ) {
                        viewModel.sendKey(.channelList)
                    }
                    
                    // Guide
                    RemoteButton(
                        title: "guide",
                        width: 52,
                        height: 52,
                        backgroundColor: Color(white: 0.18),
                        isCircle: true
                    ) {
                        viewModel.sendKey(.guide)
                    }
                }
            }
            
            // Channel Rocker (^, ch, v)
            RockerControlView(
                topIcon: "chevron.up",
                bottomIcon: "chevron.down",
                label: "ch",
                onTopAction: { viewModel.sendKey(.channelUp) },
                onBottomAction: { viewModel.sendKey(.channelDown) },
                width: 58,
                height: rockerHeight
            )
        }
    }
    
    // MARK: - Media Playback Controls Row (<<, >, ||, >>)
    
    private var playbackSection: some View {
        HStack(spacing: 10) {
            // Rewind
            RemoteButton(
                icon: "backward.fill",
                height: 38,
                backgroundColor: Color(white: 0.17),
                isPill: true
            ) {
                viewModel.sendKey(.rewind)
            }
            
            // Play
            RemoteButton(
                icon: "play.fill",
                height: 38,
                backgroundColor: Color(white: 0.17),
                isPill: true
            ) {
                viewModel.sendKey(.play)
            }
            
            // Pause
            RemoteButton(
                icon: "pause.fill",
                height: 38,
                backgroundColor: Color(white: 0.17),
                isPill: true
            ) {
                viewModel.sendKey(.pause)
            }
            
            // Fast Forward
            RemoteButton(
                icon: "forward.fill",
                height: 38,
                backgroundColor: Color(white: 0.17),
                isPill: true
            ) {
                viewModel.sendKey(.fastForward)
            }
        }
    }
    
    // MARK: - Bottom Quick App Dock (YouTube, Netflix, VTV Go, FPT Play)
    
    private var quickAppDock: some View {
        HStack(spacing: 8) {
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
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(app.accentColor)
                                .frame(width: 8, height: 8)
                            
                            Text(app.name)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    .frame(height: 38)
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

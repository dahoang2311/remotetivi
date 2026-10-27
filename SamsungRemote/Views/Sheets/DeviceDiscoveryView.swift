import SwiftUI

/// Modal sheet for discovering Samsung TVs via SSDP/Subnet probe and managing saved devices or manual IP entry.
struct DeviceDiscoveryView: View {
    @ObservedObject var viewModel: RemoteViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var manualIP: String = ""
    @State private var isShowingManualEntry = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Scan Header Card
                        scanHeaderSection
                        
                        // Discovered Devices Section
                        discoveredDevicesSection
                        
                        // Saved Devices Section
                        savedDevicesSection
                        
                        // Manual IP Entry Card
                        manualEntrySection
                        
                        // Network Troubleshooting Tips
                        troubleshootingTipsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Connect TV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            viewModel.discoveryService.startDiscovery()
        }
        .onDisappear {
            viewModel.discoveryService.stopDiscovery()
        }
    }
    
    // MARK: - Scan Header
    
    private var scanHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Local Network Scan")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                
                Text(viewModel.discoveryService.isScanning ? "Scanning Wi-Fi for Samsung TVs..." : "Scan completed")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            Spacer()
            
            if viewModel.discoveryService.isScanning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            } else {
                Button(action: {
                    viewModel.discoveryService.startDiscovery()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Rescan")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.14))
        )
    }
    
    // MARK: - Discovered Devices List
    
    private var discoveredDevicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DISCOVERED TVS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.horizontal, 4)
            
            if viewModel.discoveryService.discoveredDevices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tv.badge.wifi")
                        .font(.system(size: 36))
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Text(viewModel.discoveryService.isScanning ? "Looking for nearby Samsung TVs..." : "No Samsung TVs detected yet")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(white: 0.12))
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.discoveryService.discoveredDevices) { device in
                        deviceRow(device: device, isDiscovered: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Saved Devices List
    
    private var savedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SAVED DEVICES")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.horizontal, 4)
            
            if viewModel.savedDevices.isEmpty {
                Text("No saved TVs. Connect to a TV to save it here.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(.horizontal, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.savedDevices) { device in
                        deviceRow(device: device, isDiscovered: false)
                    }
                }
            }
        }
    }
    
    private func deviceRow(device: SamsungDevice, isDiscovered: Bool) -> some View {
        let isCurrent = viewModel.activeDevice?.id == device.id
        
        return Button(action: {
            viewModel.selectDevice(device)
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(spacing: 14) {
                // TV Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isCurrent ? Color.blue : Color(white: 0.22))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "tv.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                // Device Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(device.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(device.ipAddress)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        if !device.modelName.isEmpty {
                            Text("•  \(device.modelName)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                    }
                }
                
                Spacer()
                
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.white.opacity(0.3))
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(white: 0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isCurrent ? Color.blue.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
    
    // MARK: - Manual Entry
    
    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MANUAL IP CONNECTION")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.horizontal, 4)
            
            HStack(spacing: 10) {
                Image(systemName: "network")
                    .foregroundColor(Color.white.opacity(0.5))
                
                TextField("e.g. 192.168.1.150", text: $manualIP)
                    .keyboardType(.numbersAndPunctuation)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(.white)
                
                Button(action: {
                    guard !manualIP.isEmpty else { return }
                    viewModel.addDeviceManually(ip: manualIP)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Connect")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(manualIP.isEmpty ? Color.gray.opacity(0.4) : Color.blue)
                        .cornerRadius(8)
                }
                .disabled(manualIP.isEmpty)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(white: 0.14))
            )
        }
    }
    
    // MARK: - Troubleshooting Tips
    
    private var troubleshootingTipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Setup Tips", systemImage: "lightbulb.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.yellow)
            
            Text("1. Make sure your iPhone and Samsung TV are connected to the same Wi-Fi network.")
            Text("2. When connecting for the first time, check your TV screen and select 'Allow' using the physical remote.")
            Text("3. On your TV: Settings → General → External Device Manager → Device Connect Manager → Device List (ensure access is Allowed).")
        }
        .font(.system(size: 12))
        .foregroundColor(Color.white.opacity(0.65))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(white: 0.11))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

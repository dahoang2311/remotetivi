import Foundation
import SwiftUI
import Combine

/// Main ViewModel orchestrating TV communication, discovery, haptic feedback, and remote state.
final class RemoteViewModel: ObservableObject, SamsungTVServiceDelegate {
    // MARK: - Published Properties
    
    @Published var activeDevice: SamsungDevice?
    @Published var savedDevices: [SamsungDevice] = []
    @Published var connectionState: TVConnectionState = .disconnected
    
    // UI Sheets & Overlays
    @Published var showDiscoverySheet: Bool = false
    @Published var showKeypadSheet: Bool = false
    @Published var showAppLauncherSheet: Bool = false
    @Published var showKeyboardSheet: Bool = false
    
    // Alerts
    @Published var alertMessage: String?
    @Published var showAlert: Bool = false
    
    // Services
    let tvService = SamsungTVService()
    let discoveryService = SSDPDiscoveryService()
    private let wolService = WakeOnLANService.shared
    private let haptic = HapticManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaultsKey = "SavedSamsungDevices"
    private let lastActiveDeviceKey = "LastActiveSamsungDevice"
    
    // MARK: - Initialization
    
    init() {
        self.tvService.delegate = self
        loadSavedDevices()
        
        // Auto-connect to previously selected device if available
        if let lastDevice = activeDevice {
            connect(to: lastDevice)
        }
        
        // Observe TV Service state
        tvService.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Device Management & Persistence
    
    private func loadSavedDevices() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let devices = try? JSONDecoder().decode([SamsungDevice].self, from: data) {
            // Enrich with tokens from Keychain if present
            self.savedDevices = devices.map { device in
                var updated = device
                if updated.token == nil || updated.token?.isEmpty == true {
                    updated.token = KeychainHelper.shared.getToken(for: device.id)
                }
                return updated
            }
        }
        
        if let lastId = UserDefaults.standard.string(forKey: lastActiveDeviceKey) {
            self.activeDevice = savedDevices.first(where: { $0.id == lastId })
        } else {
            self.activeDevice = savedDevices.first
        }
    }
    
    private func saveDevices() {
        if let data = try? JSONEncoder().encode(savedDevices) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        if let active = activeDevice {
            UserDefaults.standard.set(active.id, forKey: lastActiveDeviceKey)
        }
    }
    
    func selectDevice(_ device: SamsungDevice) {
        self.activeDevice = device
        saveDevices()
        connect(to: device)
        showDiscoverySheet = false
    }
    
    func addOrUpdateDevice(_ device: SamsungDevice) {
        if let index = savedDevices.firstIndex(where: { $0.ipAddress == device.ipAddress }) {
            // Update existing
            savedDevices[index] = device
        } else {
            savedDevices.append(device)
        }
        selectDevice(device)
    }
    
    func removeDevice(at offsets: IndexSet) {
        let removedIds = offsets.map { savedDevices[$0].id }
        savedDevices.remove(atOffsets: offsets)
        if let active = activeDevice, removedIds.contains(active.id) {
            disconnect()
            activeDevice = savedDevices.first
        }
        saveDevices()
    }
    
    func addDeviceManually(ip: String, name: String? = nil) {
        let trimmedIp = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIp.isEmpty else { return }
        
        // Query device info
        SamsungTVService.fetchDeviceInfo(ip: trimmedIp) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fetched):
                self.addOrUpdateDevice(fetched)
            case .failure:
                let manualDevice = SamsungDevice(
                    name: name ?? "Samsung TV (\(trimmedIp))",
                    ipAddress: trimmedIp,
                    modelName: "Smart TV"
                )
                self.addOrUpdateDevice(manualDevice)
            }
        }
    }
    
    // MARK: - Connection
    
    func connect(to device: SamsungDevice) {
        tvService.connect(to: device)
    }
    
    func disconnect() {
        tvService.disconnect()
    }
    
    func retryConnection() {
        if let device = activeDevice {
            connect(to: device)
        } else {
            showDiscoverySheet = true
        }
    }
    
    // MARK: - Remote Commands
    
    func sendKey(_ key: SamsungKey) {
        guard activeDevice != nil else {
            presentAlert("No TV Selected", message: "Please search and connect to your Samsung TV first.")
            return
        }
        
        // Haptic feedback based on key type
        switch key {
        case .enter, .home, .power:
            haptic.triggerConfirm()
        case .up, .down, .left, .right:
            haptic.triggerNavigation()
        default:
            haptic.triggerTap()
        }
        
        tvService.sendKey(key) { [weak self] success in
            if !success && !(self?.connectionState.isConnected ?? false) {
                // TV is disconnected
                print("[RemoteViewModel] Failed to send key \(key.rawValue) - disconnected")
            }
        }
    }
    
    /// Sends a full text string to the TV (e.g. YouTube search or Netflix text input).
    func sendText(_ text: String) {
        guard activeDevice != nil else {
            presentAlert("No TV Selected", message: "Please connect to your TV first.")
            return
        }
        haptic.triggerTap()
        tvService.sendText(text) { success in
            if !success {
                print("[RemoteViewModel] Failed to send text: \(text)")
            }
        }
    }
    
    /// Smart Power handler: Sends KEY_POWER if connected, or Wake-On-LAN magic packet if disconnected.
    func togglePower() {
        haptic.triggerConfirm()
        
        guard let device = activeDevice else {
            presentAlert("No Device", message: "Select or add a Samsung TV first.")
            return
        }
        
        if connectionState.isConnected {
            // TV is on and connected: send Power toggle
            tvService.sendKey(.power)
        } else {
            // TV is off/standby: Attempt Wake-on-LAN if MAC is available
            if !device.macAddress.isEmpty {
                wolService.wake(macAddress: device.macAddress) { [weak self] success in
                    guard let self = self else { return }
                    if success {
                        // Wait a few seconds for TV to boot network stack and attempt connection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            self.connect(to: device)
                        }
                    }
                }
            } else {
                // Try sending power key or reconnecting
                connect(to: device)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.tvService.sendKey(.power)
                }
            }
        }
    }
    
    func launchApp(_ app: SamsungApp) {
        haptic.triggerSelection()
        tvService.launchApp(app) { [weak self] success in
            if !success {
                self?.presentAlert("Launch Failed", message: "Could not open \(app.name). Ensure TV is powered on.")
            }
        }
        showAppLauncherSheet = false
    }
    
    // MARK: - SamsungTVServiceDelegate
    
    func tvServiceDidChangeState(_ state: TVConnectionState) {
        self.connectionState = state
        if case .error(let msg) = state {
            presentAlert("Connection Alert", message: msg)
        }
    }
    
    func tvServiceDidReceiveToken(_ token: String) {
        // Persist token in activeDevice and savedDevices
        guard var device = activeDevice else { return }
        device.token = token
        self.activeDevice = device
        
        if let index = savedDevices.firstIndex(where: { $0.id == device.id }) {
            savedDevices[index].token = token
        }
        saveDevices()
    }
    
    // MARK: - Helper Alert
    
    private func presentAlert(_ title: String, message: String) {
        self.alertMessage = "\(title): \(message)"
        self.showAlert = true
    }
}

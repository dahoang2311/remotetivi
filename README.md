# Samsung Smart Remote for iOS (SwiftUI + MVVM)

A production-ready, beautifully designed iOS application built in SwiftUI that transforms your iPhone into a smart remote control for Samsung Smart TVs (Tizen OS 2016 to present).

Designed with dark mode aesthetics, tactile haptic feedback, safe area compliance for all Notch & Dynamic Island iPhone models, and network resilience.

---

## 📱 Features

- **Device Discovery**:
  - Automatic local network discovery using **SSDP (UPnP)** M-SEARCH UDP multicast (`239.255.255.250:1900`).
  - Parallel smart subnet probing on `http://<ip>:8001/api/v2/` to ensure discovery still succeeds even on consumer Wi-Fi routers that block multicast UDP.
  - Manual IP address connection support.
  - Paired devices saved automatically in `UserDefaults`.
- **Samsung Smart TV Communication Protocol**:
  - Secure **WebSocket API** (`wss://<ip>:8002/api/v2/channels/samsung.remote.control?name=...&token=...`) with automatic SSL certificate trust handler for self-signed certificates.
  - Fallback to non-secure WebSocket port `8001` (`ws://`) for older Tizen models.
  - Pairing handshake & token persistence so you only have to press **"Allow"** on your TV once.
  - REST API endpoint (`http://<ip>:8001/api/v2/`) integration to query device name, model, Wi-Fi MAC, and power status.
- **Wake-on-LAN (WOL)**:
  - Broadcasts magic packets (UDP port 9) to power on Samsung TVs when they are in standby mode.
- **Remote Control Interface**:
  - **Power On/Off** toggle with ambient red illumination.
  - **Center Circular D-Pad**: Up, Down, Left, Right, and central **OK / Enter** button.
  - **Volume & Channel Vertical Rockers**: Tactile pill rockers for VOL +, VOL -, CH ∧, and CH ∨.
  - **Navigation Shortcuts**: Home, Back, Exit, Menu, Source/Input, and Info.
  - **Media Playback**: Play/Pause and Mute toggles.
  - **Numeric Keypad Sheet**: 0-9 digits, dot (•), Pre-CH, TTX, and color buttons (Red, Green, Yellow, Blue).
  - **App Launcher Grid & Dock**: Instant deep-link launch for Netflix, YouTube, Prime Video, Disney+, Apple TV, Spotify, and Web Browser.
- **Real-Time Status Indicator**:
  - Live pulsating status badge (Green: Connected, Orange: Connecting, Yellow: TV Authorization Prompt, Red: Disconnected).

---

## 📐 Device Compatibility

Fully optimized and tested for safe area insets on:
- **Dynamic Island Devices**: iPhone 14 Pro, iPhone 14 Pro Max, iPhone 15 / 15 Plus / 15 Pro / 15 Pro Max, iPhone 16 series.
- **Notch Devices**: iPhone X, iPhone XS, iPhone XS Max, iPhone XR, iPhone 11 series, iPhone 12 series, iPhone 13 series, iPhone 14 / 14 Plus.
- **Compact Devices**: iPhone SE (2nd/3rd gen) and mini models via responsive layout scaling.

---

## 🏗️ Architecture & Project Structure (MVVM)

```
remotetivi/
├── SamsungRemote.xcodeproj/       # Turnkey Xcode project file
│   └── project.pbxproj
├── Package.swift                  # Swift Package Manager manifest
├── SamsungRemote/
│   ├── App/
│   │   └── SamsungRemoteApp.swift # SwiftUI @main app lifecycle
│   ├── Models/
│   │   ├── SamsungDevice.swift    # Device model, REST response schema, persistence
│   │   ├── SamsungKey.swift       # Samsung TV keycodes & SF Symbols
│   │   ├── SamsungApp.swift       # Tizen App IDs & brand styling
│   │   └── TVConnectionState.swift# Real-time connection states
│   ├── Services/
│   │   ├── SamsungTVService.swift # WebSocket client, SSL trust bypass, token handshake, ms.remote.control
│   │   ├── SSDPDiscoveryService.swift # UDP SSDP discovery & subnet probe
│   │   ├── WakeOnLANService.swift # UDP Magic Packet broadcaster (ports 9 & 7)
│   │   ├── KeychainHelper.swift   # Secure token storage using iOS Keychain
│   │   └── HapticManager.swift    # Tactile iOS feedback engine
│   ├── ViewModels/
│   │   └── RemoteViewModel.swift  # MVVM ViewModel coordinating state & TV service
│   ├── Views/
│   │   ├── ContentView.swift      # Master Remote interface (Adaptive layout)
│   │   ├── Components/
│   │   │   ├── DPadView.swift     # Circular haptic D-Pad
│   │   │   ├── RockerControlView.swift # Vertical volume & channel rockers
│   │   │   ├── ConnectionStatusBadge.swift # Pulsating status pill
│   │   │   └── RemoteButton.swift # Reusable tactile glassmorphism button
│   │   └── Sheets/
│   │       ├── DeviceDiscoveryView.swift # Scan & saved devices modal
│   │       ├── NumericKeypadSheet.swift  # 0-9 numeric pad & color keys
│   │       └── AppLauncherSheet.swift    # Smart Hub app launcher drawer
│   └── Resources/
│       ├── Info.plist             # Local network & Bonjour permissions
│       └── Assets.xcassets        # Color & icon assets
└── README.md
```

---

## ⚙️ TV Setup & Pairing Guide

1. **Same Wi-Fi Network**: Ensure your iPhone and Samsung TV are connected to the same Wi-Fi network (2.4 GHz or 5 GHz).
2. **TV Network Permission Setting**:
   - On your Samsung TV, navigate to:
     `Settings` → `General` → `External Device Manager` → `Device Connect Manager`
   - Set **Access Notification** to **First Time Only** or **Always On**.
   - Check **Device List** to make sure access is not blocked.
3. **First-Time Connection Handshake**:
   - Open the app and tap **Connect TV** or select your discovered Samsung TV.
   - Look at your TV screen: a popup will ask *"Allow [iOS Smart Remote] to connect to TV?"*.
   - Use your TV's physical remote to click **Allow**.
   - The app securely receives and caches an authentication token. Subsequent connections will connect automatically without prompting again!

---

## 🔒 iOS Permissions & Info.plist

The app includes all required keys in `SamsungRemote/Resources/Info.plist`:

1. **`NSLocalNetworkUsageDescription`**:
   Required by Apple starting in iOS 14 to allow local socket and HTTP/WebSocket communication with devices on the local Wi-Fi.
2. **`NSBonjourServices`**:
   Declares Bonjour mDNS services used by Samsung TVs (`_samsungmsf._tcp`, `_samsung-remote._tcp`, `_dial-multiscreen-org._tcp`, `_airplay._tcp`).
3. **`NSAppTransportSecurity` (`NSAllowsLocalNetworking: true`)**:
   Allows HTTP communication with local TV IP addresses on port 8001 without being blocked by App Transport Security.

---

## 📡 Samsung TizenOS Protocol Specifications

### 1. WebSocket Handshake & Token Handling (Port 8002 WSS)
- **Initial Connection URL**:
  ```
  wss://<ip>:8002/api/v2/channels/samsung.remote.control?name=<base64AppName>
  ```
- **TV Handshake Response**:
  When user selects "Allow" on TV, Samsung TV emits:
  ```json
  {
    "event": "ms.channel.connect",
    "data": {
      "token": "12345678",
      "clients": [...]
    }
  }
  ```
- The token is extracted and securely stored in iOS **Keychain** via `KeychainHelper`.
- **Subsequent Connection URL**:
  ```
  wss://<ip>:8002/api/v2/channels/samsung.remote.control?name=<base64AppName>&token=12345678
  ```

### 2. Remote Key JSON Payload Structure
All remote button actions are wrapped inside the standard Samsung `ms.remote.control` payload:
```json
{
  "method": "ms.remote.control",
  "params": {
    "Cmd": "Click",
    "DataOfCode": "KEY_VOLUP",
    "Option": "false",
    "TypeOfRemote": "SendRemoteKey"
  }
}
```

### 3. Wake-on-LAN Magic Packet Helper
Sends a standard 102-byte magic packet (6x `0xFF` followed by 16x MAC address) over UDP broadcast to both port 9 and port 7:
```swift
WakeOnLANService.sendWakeOnLAN(macAddress: "A0:B1:C2:D3:E4:F5") { success in
    print("Magic packet broadcast result: \(success)")
}
```

---

## 🚀 How to Run in Xcode

1. Open `SamsungRemote.xcodeproj` on a Mac running Xcode 14, 15, or 16.
2. Select your target device or simulator (e.g. *iPhone 15 Pro* or *iPhone 14*).
3. Press **Cmd + R** to build and run.

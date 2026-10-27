import SwiftUI

@main
struct SamsungRemoteApp: App {
    init() {
        // Prepare haptic feedback engines
        HapticManager.shared.prepare()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

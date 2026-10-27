import Foundation
import SwiftUI

/// Represents a Smart Hub application on Samsung Tizen TVs.
struct SamsungApp: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let accentColor: Color
    let deepLinkAction: String?
    
    init(id: String, name: String, iconName: String, accentColor: Color, deepLinkAction: String? = nil) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.accentColor = accentColor
        self.deepLinkAction = deepLinkAction
    }
    
    /// Curated list of popular Samsung Smart TV apps with official Tizen App IDs
    static let popularApps: [SamsungApp] = [
        SamsungApp(
            id: "3201907018807", // Netflix Tizen App ID (also 11101200001)
            name: "Netflix",
            iconName: "play.rectangle.fill",
            accentColor: Color(red: 0.89, green: 0.04, blue: 0.08)
        ),
        SamsungApp(
            id: "111299001912", // YouTube Tizen App ID (also 3201512006785)
            name: "YouTube",
            iconName: "play.tv.fill",
            accentColor: Color(red: 1.0, green: 0.0, blue: 0.0)
        ),
        SamsungApp(
            id: "3201901017640", // Prime Video Tizen App ID
            name: "Prime Video",
            iconName: "cart.fill",
            accentColor: Color(red: 0.0, green: 0.65, blue: 0.9)
        ),
        SamsungApp(
            id: "3201901019363", // Disney+ Tizen App ID
            name: "Disney+",
            iconName: "sparkles.tv.fill",
            accentColor: Color(red: 0.07, green: 0.22, blue: 0.55)
        ),
        SamsungApp(
            id: "3201807016597", // Apple TV Tizen App ID
            name: "Apple TV",
            iconName: "appletvfill",
            accentColor: Color(red: 0.25, green: 0.25, blue: 0.28)
        ),
        SamsungApp(
            id: "3201606009684", // Spotify Tizen App ID
            name: "Spotify",
            iconName: "music.note",
            accentColor: Color(red: 0.12, green: 0.84, blue: 0.38)
        ),
        SamsungApp(
            id: "org.tizen.browser", // Tizen Built-in Web Browser
            name: "Internet",
            iconName: "safari.fill",
            accentColor: Color(red: 0.18, green: 0.52, blue: 0.95)
        ),
        SamsungApp(
            id: "3201601007230", // Twitch
            name: "Twitch",
            iconName: "bubble.left.and.bubble.right.fill",
            accentColor: Color(red: 0.57, green: 0.27, blue: 1.0)
        )
    ]
}

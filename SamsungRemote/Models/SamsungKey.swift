import Foundation
import SwiftUI

/// Enum containing Samsung Smart TV keycodes and UI presentation metadata.
enum SamsungKey: String, CaseIterable, Identifiable {
    // Power
    case power = "KEY_POWER"
    case powerOff = "KEY_POWEROFF"
    
    // Navigation & D-Pad
    case up = "KEY_UP"
    case down = "KEY_DOWN"
    case left = "KEY_LEFT"
    case right = "KEY_RIGHT"
    case enter = "KEY_ENTER"
    case back = "KEY_RETURN"
    case home = "KEY_HOME"
    case menu = "KEY_MENU"
    case source = "KEY_SOURCE"
    case exit = "KEY_EXIT"
    case info = "KEY_INFO"
    case guide = "KEY_GUIDE"
    
    // Volume & Sound
    case volumeUp = "KEY_VOLUP"
    case volumeDown = "KEY_VOLDOWN"
    case mute = "KEY_MUTE"
    
    // Channel
    case channelUp = "KEY_CHUP"
    case channelDown = "KEY_CHDOWN"
    case previousChannel = "KEY_PRECH"
    
    // Playback
    case play = "KEY_PLAY"
    case pause = "KEY_PAUSE"
    case stop = "KEY_STOP"
    case rewind = "KEY_REWIND"
    case fastForward = "KEY_FF"
    
    // Numeric Keypad
    case num0 = "KEY_0"
    case num1 = "KEY_1"
    case num2 = "KEY_2"
    case num3 = "KEY_3"
    case num4 = "KEY_4"
    case num5 = "KEY_5"
    case num6 = "KEY_6"
    case num7 = "KEY_7"
    case num8 = "KEY_8"
    case num9 = "KEY_9"
    case dot = "KEY_DOT"
    case ttxMix = "KEY_TTX_MIX"
    
    // Color keys
    case red = "KEY_RED"
    case green = "KEY_GREEN"
    case yellow = "KEY_YELLOW"
    case blue = "KEY_CYAN"
    
    // Other
    case search = "KEY_SEARCH"
    
    var id: String { rawValue }
    
    /// User-friendly label or fallback symbol
    var displayName: String {
        switch self {
        case .power, .powerOff: return "Power"
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        case .enter: return "OK"
        case .back: return "Back"
        case .home: return "Home"
        case .menu: return "Menu"
        case .source: return "Source"
        case .exit: return "Exit"
        case .info: return "Info"
        case .guide: return "Guide"
        case .volumeUp: return "VOL +"
        case .volumeDown: return "VOL -"
        case .mute: return "Mute"
        case .channelUp: return "CH ∧"
        case .channelDown: return "CH ∨"
        case .previousChannel: return "Pre-CH"
        case .play: return "Play"
        case .pause: return "Pause"
        case .stop: return "Stop"
        case .rewind: return "Rewind"
        case .fastForward: return "Fast Forward"
        case .num0: return "0"
        case .num1: return "1"
        case .num2: return "2"
        case .num3: return "3"
        case .num4: return "4"
        case .num5: return "5"
        case .num6: return "6"
        case .num7: return "7"
        case .num8: return "8"
        case .num9: return "9"
        case .dot: return "•"
        case .ttxMix: return "TTX"
        case .red: return "Red"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .search: return "Search"
        }
    }
    
    /// SF Symbol icon name if available
    var sfSymbol: String? {
        switch self {
        case .power, .powerOff: return "power"
        case .up: return "chevron.up"
        case .down: return "chevron.down"
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        case .enter: return nil // Special text OK
        case .back: return "arrow.uturn.backward"
        case .home: return "house.fill"
        case .menu: return "line.3.horizontal"
        case .source: return "display.2"
        case .exit: return "xmark"
        case .info: return "info.circle"
        case .guide: return "list.bullet.rectangle"
        case .volumeUp: return "speaker.wave.3.fill"
        case .volumeDown: return "speaker.wave.1.fill"
        case .mute: return "speaker.slash.fill"
        case .channelUp: return "chevron.compact.up"
        case .channelDown: return "chevron.compact.down"
        case .previousChannel: return "arrow.counterclockwise"
        case .play: return "play.fill"
        case .pause: return "pause.fill"
        case .stop: return "stop.fill"
        case .rewind: return "backward.fill"
        case .fastForward: return "forward.fill"
        case .search: return "magnifyingglass"
        default: return nil
        }
    }
}

import UIKit

/// Manages tactile haptic feedback for remote control buttons to replicate physical remote feel.
final class HapticManager {
    static let shared = HapticManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private init() {
        prepare()
    }
    
    func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    /// Triggered on normal button taps (e.g. Volume, Channel, D-Pad)
    func triggerTap() {
        mediumImpact.impactOccurred()
    }
    
    /// Triggered on navigation key movement
    func triggerNavigation() {
        lightImpact.impactOccurred(intensity: 0.8)
    }
    
    /// Triggered on OK/Enter or important actions (Power, Home)
    func triggerConfirm() {
        heavyImpact.impactOccurred()
    }
    
    /// Triggered on toggle or mode changes
    func triggerSelection() {
        selectionFeedback.selectionChanged()
    }
    
    /// Triggered when connected successfully
    func triggerSuccess() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Triggered on connection error or rejection
    func triggerError() {
        notificationFeedback.notificationOccurred(.error)
    }
    
    /// Triggered when TV asks user for permission
    func triggerWarning() {
        notificationFeedback.notificationOccurred(.warning)
    }
}

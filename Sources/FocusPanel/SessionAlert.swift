import Foundation
import AppKit
import FocusPanelCore
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Fires an end-of-session alert. Uses a native user notification when the
/// process is running as a real .app bundle, and always plays a chime.
///
/// Note: `UNUserNotificationCenter` requires a bundle identifier. When the app
/// is launched via `swift run` (no bundle) we deliberately skip the
/// notification path — touching the notification center there can crash the
/// process — and fall back to an audible chime only.
enum SessionAlert {
    private static var notificationsUsable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    static func requestAuthorizationIfPossible() {
        #if canImport(UserNotifications)
        guard notificationsUsable else { return }
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
        #endif
    }

    static func fire(finished: SessionType, next: SessionType, playSound: Bool) {
        if playSound {
            (NSSound(named: "Glass") ?? NSSound(named: "Ping"))?.play()
        }

        #if canImport(UserNotifications)
        guard notificationsUsable else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(finished.title) complete"
        content.body = "Time for \(next.title.lowercased()). Keep the momentum going."
        if playSound { content.sound = .default }
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        #endif
    }
}

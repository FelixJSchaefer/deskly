import UIKit
import UserNotifications

extension Notification.Name {
    static let desklyStopAlarm = Notification.Name("deskly.stopAlarm")
}

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private let requestPrefix = "deskly.phase."
    private let categoryIdentifier = "DESKLY_PHASE_ALARM"
    private let stopActionIdentifier = "DESKLY_STOP_ALARM"

    func configure() {
        center.delegate = self
        let stop = UNNotificationAction(
            identifier: stopActionIdentifier,
            title: "Alarm stoppen",
            options: []
        )
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: categoryIdentifier,
                actions: [stop],
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
        ])
    }

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func scheduleRemaining(
        phases: [WorkPhase],
        currentIndex: Int,
        remainingSeconds: TimeInterval,
        soundEnabled: Bool
    ) async {
        cancelPending()
        guard phases.indices.contains(currentIndex) else { return }

        var delay = max(1, remainingSeconds)
        for index in currentIndex..<phases.count {
            let content = UNMutableNotificationContent()
            if phases.indices.contains(index + 1) {
                let next = phases[index + 1]
                content.title = "Zeit für \(next.name)"
                content.body = "Die nächste Deskly-Phase beginnt jetzt."
            } else {
                content.title = "Tagesplan abgeschlossen"
                content.body = "Alle Deskly-Phasen sind geschafft."
            }
            content.categoryIdentifier = categoryIdentifier
            content.sound = soundEnabled ? UNNotificationSound(named: .init("Knock.wav")) : nil
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(requestPrefix)\(index)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
            if phases.indices.contains(index + 1) {
                delay += TimeInterval(phases[index + 1].minutes * 60)
            }
        }
    }

    func cancelPending() {
        center.removeAllPendingNotificationRequests()
    }

    func clearDelivered() {
        center.removeAllDeliveredNotifications()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == stopActionIdentifier {
            NotificationCenter.default.post(name: .desklyStopAlarm, object: nil)
            clearDelivered()
        }
        completionHandler()
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationService.shared.configure()
        return true
    }
}

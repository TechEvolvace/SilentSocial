//  NotificationsSettingsViewController.swift
//  SilentSocial

import UIKit
import UserNotifications

final class NotificationsSettingsViewController: UIViewController {

    @IBOutlet weak var notificationsSwitch: UISwitch!

    private let defaults = UserDefaults.standard
    private let notificationsEnabledKey = "notificationsEnabled"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"

        // Load saved state (default false)
        let isOn = defaults.bool(forKey: notificationsEnabledKey)
        notificationsSwitch.isOn = isOn
    }

    @IBAction func notificationsSwitchToggled(_ sender: UISwitch) {
        let isOn = sender.isOn
        defaults.set(isOn, forKey: notificationsEnabledKey)

        if isOn {
            enableNotifications()
        } else {
            cancelDailyNotification()
        }
    }

    // MARK: - Core logic

    private func enableNotifications() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            switch settings.authorizationStatus {
            case .notDetermined:
                // First time: ask for permission
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        self.scheduleDailyNotification()
                    } else {
                        // We DO NOT change the switch back here; user preference is still "I want it on".
                        // iOS simply won't show notifications if they denied it.
                        print("Notification permission not granted: \(error?.localizedDescription ?? "no error")")
                    }
                }

            case .authorized, .provisional, .ephemeral:
                self.scheduleDailyNotification()

            case .denied:
                // They denied at OS level. Again, no flip back. Just tell them.
                DispatchQueue.main.async {
                    self.showInfo(
                        "Notifications Disabled in Settings",
                        "SilentSocial cannot show alerts because notifications are disabled in iOS Settings. You can enable them in Settings → SilentSocial → Notifications."
                    )
                }

            @unknown default:
                break
            }
        }
    }

    private func scheduleDailyNotification() {
        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(withIdentifiers: ["dailyMoodReminder"])

        let content = UNMutableNotificationContent()
        content.title = "SilentSocial Check-In"
        content.body  = "Share your mood or react to your friends' visuals today."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "dailyMoodReminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    private func cancelDailyNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyMoodReminder"])
    }

    // MARK: - Helper

    private func showInfo(_ title: String, _ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

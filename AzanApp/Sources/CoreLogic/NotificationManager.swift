import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false

    init() {
        checkAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async { self.isAuthorized = granted }
            if let error = error { print("Notification permission error: \(error.localizedDescription)") }
        }
    }

    private func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule

    /// Cancels all pending prayer notifications and schedules fresh ones for today's remaining prayers.
    /// Called every time prayer times are fetched (from API or offline fallback).
    func scheduleDailyNotifications(prayerTimes: DailyPrayerTimes, settings: SettingsManager) {
        guard isAuthorized else {
            print("NotificationManager: not authorized, skipping schedule")
            return
        }

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let now = Date()
        let prayers: [(Prayer, Date)] = [
            (.fajr,    prayerTimes.fajr),
            (.dhuhr,   prayerTimes.dhuhr),
            (.asr,     prayerTimes.asr),
            (.maghrib, prayerTimes.maghrib),
            (.isha,    prayerTimes.isha)
        ]

        for (prayer, time) in prayers {
            guard time > now else { continue }  // skip past prayers
            let soundSetting = settings.soundPreference(for: prayer)
            scheduleNotification(for: prayer, at: time, soundSetting: soundSetting)
        }
    }

    // MARK: - Single Notification

    private func scheduleNotification(for prayer: Prayer, at date: Date, soundSetting: SoundSetting) {
        let content = UNMutableNotificationContent()
        content.title = "🕌 \(prayerName(prayer))"
        content.body = "It is time for \(prayerName(prayer)) prayer."
        content.badge = 1

        switch soundSetting {
        case .defaultBeep:
            content.sound = .default
        case .makkahAzan:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("makkah.mp3"))
        case .custom(let filename):
            content.sound = UNNotificationSound(named: UNNotificationSoundName(filename))
        case .silent:
            content.sound = nil
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "azan-\(prayerName(prayer))-\(Int(date.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule \(self.prayerName(prayer)): \(error.localizedDescription)")
            } else {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                print("Scheduled \(self.prayerName(prayer)) at \(formatter.string(from: date))")
            }
        }
    }

    // MARK: - Helpers

    func prayerName(_ prayer: Prayer) -> String {
        switch prayer {
        case .fajr:    return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isha"
        }
    }
}

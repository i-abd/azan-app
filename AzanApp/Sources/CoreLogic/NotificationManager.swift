import Foundation
import UserNotifications


class NotificationManager: ObservableObject {
    @Published var isAuthorized = false

    init() {
        checkAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    private func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleDailyNotifications(prayerTimes: PrayerTimes, settings: SettingsManager) {
        guard isAuthorized else { return }
        
        // Remove old before scheduling new ones
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let prayers: [(Prayer, Date)] = [
            (.fajr, prayerTimes.fajr),
            (.dhuhr, prayerTimes.dhuhr),
            (.asr, prayerTimes.asr),
            (.maghrib, prayerTimes.maghrib),
            (.isha, prayerTimes.isha)
        ]

        for (prayer, time) in prayers {
            guard time > Date() else { continue }
            scheduleNotification(for: prayer, at: time, soundSetting: settings.soundPreference(for: prayer))
        }
    }

    private func scheduleNotification(for prayer: Prayer, at date: Date, soundSetting: SoundSetting) {
        let content = UNMutableNotificationContent()
        content.title = "Time for \(prayerName(prayer))"
        content.body = "It is time for \(prayerName(prayer)) prayer."
        
        switch soundSetting {
        case .defaultBeep:
            content.sound = .default
        case .makkahAzan:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("makkah.caf"))
        case .custom(let filename):
            content.sound = UNNotificationSound(named: UNNotificationSoundName(filename))
        case .silent:
            break
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "prayer-\(prayerName(prayer))-\(date.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule \(self.prayerName(prayer)): \(error.localizedDescription)")
            }
        }
    }

    func prayerName(_ prayer: Prayer) -> String {
        switch prayer {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
}

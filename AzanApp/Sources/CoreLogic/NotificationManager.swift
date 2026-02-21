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

        let prayers: [(Prayer, Date?)] = [
            (.fajr, prayerTimes.fajr),
            (.dhuhr, prayerTimes.dhuhr),
            (.asr, prayerTimes.asr),
            (.maghrib, prayerTimes.maghrib),
            (.isha, prayerTimes.isha)
        ]

        for (prayer, time) in prayers {
            guard let prayerTime = time, prayerTime > Date() else { continue }
            
            scheduleNotification(for: prayer, at: prayerTime, soundSetting: settings.soundPreference(for: prayer))
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
            // Apple limits custom sounds to 30s. Must be in Library/Sounds or Main Bundle.
            content.sound = UNNotificationSound(named: UNNotificationSoundName(filename))
        case .silent:
            // Do not attach a sound
            break
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "prayer-\(prayer.rawValue)-\(date.timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule \(prayerName(prayer)): \(error.localizedDescription)")
            }
        }
    }

    private func prayerName(_ prayer: Prayer) -> String {
        switch prayer {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise" // Usually no azan for sunrise
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        case .none: return "Unknown"
        }
    }
}

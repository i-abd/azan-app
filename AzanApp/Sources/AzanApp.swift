import SwiftUI
import UserNotifications

// Intercepts foreground notifications to play the full Azan via AVAudioPlayer.
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // App is open — play full Azan audio and show banner (suppress default sound)
        AzanAudioPlayer.shared.playAzan(soundName: "makkah")
        completionHandler([.banner, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

@main
struct AzanAppApp: App {
    @StateObject private var locationManager    = LocationManager()
    @StateObject private var prayerTimesManager = PrayerTimesManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var settingsManager    = SettingsManager()

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(prayerTimesManager)
                .environmentObject(notificationManager)
                .environmentObject(settingsManager)
                .onAppear {
                    notificationManager.requestAuthorization()
                    locationManager.requestLocation()
                }
                // *** THE KEY WIRING ***
                // Every time prayer times are fetched (API or offline), schedule notifications.
                .onChange(of: prayerTimesManager.lastUpdateTime) { _ in
                    guard let times = prayerTimesManager.currentPrayerTimes else { return }
                    notificationManager.scheduleDailyNotifications(
                        prayerTimes: times,
                        settings: settingsManager)
                }
        }
    }
}

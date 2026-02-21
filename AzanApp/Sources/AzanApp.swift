import SwiftUI
import UserNotifications

@main
struct AzanAppApp: App, UNUserNotificationCenterDelegate {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var prayerTimesManager = PrayerTimesManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var settingsManager = SettingsManager()
    let audioPlayer = AzanAudioPlayer.shared

    init() {
        // Become the notification delegate so we can intercept foreground notifications
        UNUserNotificationCenter.current().delegate = self
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
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification fires while the app IS in the foreground.
    /// Instead of showing a banner + short beep, we play the full Azan via AVAudioPlayer.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Play the full Azan audio in the foreground
        audioPlayer.playAzan(soundName: "makkah")
        
        // Show the banner but suppress the default notification sound (we handle audio ourselves)
        completionHandler([.banner, .list])
    }

    /// Called when the user taps a notification (from background).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

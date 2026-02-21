import SwiftUI
import UserNotifications

// Delegates must be classes in Swift — this intercepts foreground notifications
// and plays the full Azan via AVAudioPlayer instead of the short system beep.
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    /// Called when a notification fires while the app IS in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Play the full Azan in the foreground
        AzanAudioPlayer.shared.playAzan(soundName: "makkah")
        
        // Show the banner but suppress the default sound (we handle audio ourselves)
        completionHandler([.banner, .list])
    }
    
    /// Called when the user taps a delivered notification.
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
    @StateObject private var locationManager = LocationManager()
    @StateObject private var prayerTimesManager = PrayerTimesManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var settingsManager = SettingsManager()

    init() {
        // Set the class-based delegate to intercept foreground notifications
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
        }
    }
}

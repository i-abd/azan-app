import SwiftUI

@main
struct AzanAppApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var prayerTimesManager = PrayerTimesManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var settingsManager = SettingsManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(prayerTimesManager)
                .environmentObject(notificationManager)
                .environmentObject(settingsManager)
                .onAppear {
                    // Start permissions
                    notificationManager.requestAuthorization()
                    locationManager.requestLocation()
                }
        }
    }
}

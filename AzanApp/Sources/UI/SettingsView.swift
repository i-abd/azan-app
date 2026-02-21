import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var prayerTimesManager: PrayerTimesManager
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prayer Calculation Method")) {
                    Picker("Calculation Method", selection: $settingsManager.calculationMethodIndex) {
                        Text("Auto-Detect (Based on Location)").tag(-1)
                        ForEach(Array(calculationMethodList.enumerated()), id: \.offset) { idx, info in
                            Text(info.displayName).tag(idx)
                        }
                    }
                    .onChange(of: settingsManager.calculationMethodIndex) { _ in
                        recalculateTimes()
                    }
                    Text("Times fetched from Aladhan API for accuracy. Falls back to offline if no internet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Notifications & Sounds"),
                        footer: Text("Background notification sounds are limited to 30 seconds by iOS.")) {
                    prayerSoundRow(for: .fajr,    name: "Fajr")
                    prayerSoundRow(for: .dhuhr,   name: "Dhuhr")
                    prayerSoundRow(for: .asr,     name: "Asr")
                    prayerSoundRow(for: .maghrib,  name: "Maghrib")
                    prayerSoundRow(for: .isha,    name: "Isha")
                }

                Section(header: Text("Support the App")) {
                    Button(action: { /* TODO: Sadaqah */ }) {
                        HStack {
                            Image(systemName: "heart.fill").foregroundColor(.red)
                            Text("Donate (Sadaqah)").foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func prayerSoundRow(for prayer: Prayer, name: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Picker("Sound", selection: Binding(
                get: { settingsManager.soundPreference(for: prayer) },
                set: { settingsManager.setSoundPreference(for: prayer, to: $0) }
            )) {
                Text("Default Beep").tag(SoundSetting.defaultBeep)
                Text("Makkah Azan").tag(SoundSetting.makkahAzan)
                Text("Silent").tag(SoundSetting.silent)
            }
            .pickerStyle(MenuPickerStyle())
        }
    }

    private func recalculateTimes() {
        guard let loc = locationManager.location else { return }
        prayerTimesManager.calculateTimes(
            coordinate: loc,
            countryCode: locationManager.countryCode,
            customMethodIndex: settingsManager.calculationMethodIndex)
    }
}

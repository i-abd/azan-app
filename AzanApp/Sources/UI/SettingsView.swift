import SwiftUI


// A simple index-based mapping for CalculationMethod since it's not RawRepresentable
let calculationMethods: [(String, CalculationMethod)] = [
    ("Muslim World League", .muslimWorldLeague),
    ("Egyptian", .egyptian),
    ("Karachi", .karachi),
    ("Umm Al-Qura", .ummAlQura),
    ("Dubai", .dubai),
    ("Qatar", .qatar),
    ("Kuwait", .kuwait),
    ("Moonsighting Committee", .moonsightingCommittee),
    ("North America (ISNA)", .northAmerica),
    ("Singapore", .singapore),
    ("Turkey", .turkey),
]

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
                        ForEach(Array(calculationMethods.enumerated()), id: \.offset) { idx, method in
                            Text(method.0).tag(idx)
                        }
                    }
                    .onChange(of: settingsManager.calculationMethodIndex) { _ in
                        recalculateTimes()
                    }
                    
                    Text("Auto-detect uses your current country to pick the most common standard.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Notifications & Sounds"), footer: Text("Custom sounds longer than 30 seconds will be trimmed by iOS when the app is in the background.")) {
                    prayerSoundRow(for: .fajr, name: "Fajr")
                    prayerSoundRow(for: .dhuhr, name: "Dhuhr")
                    prayerSoundRow(for: .asr, name: "Asr")
                    prayerSoundRow(for: .maghrib, name: "Maghrib")
                    prayerSoundRow(for: .isha, name: "Isha")
                }
                
                Section(header: Text("Support the App")) {
                    Button(action: {
                        // TODO: Implement Sadaqah / Donation logic
                    }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Donate (Sadaqah)")
                                .foregroundColor(.primary)
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
                get: { self.settingsManager.soundPreference(for: prayer) },
                set: { self.settingsManager.setSoundPreference(for: prayer, to: $0) }
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
        
        var method: CalculationMethod? = nil
        let idx = settingsManager.calculationMethodIndex
        if idx >= 0 && idx < calculationMethods.count {
            method = calculationMethods[idx].1
        }
        
        prayerTimesManager.calculateTimes(coordinate: loc, countryCode: locationManager.countryCode, customMethod: method)
    }
}

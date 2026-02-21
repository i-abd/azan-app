import SwiftUI

struct HomeView: View {
    @EnvironmentObject var prayerTimesManager: PrayerTimesManager
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                // Header: Hijri Date
                VStack(spacing: 4) {
                    Text(prayerTimesManager.getCurrentHijriDate())
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if let error = locationManager.error {
                        Text("Location Error: \(error)")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else if locationManager.location == nil {
                        Text("Locating…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)

                // Countdown Widget
                if let nextPrayer = prayerTimesManager.nextPrayer,
                   let countdown = prayerTimesManager.countdown {
                    VStack(spacing: 8) {
                        Text("Next: \(prayerName(nextPrayer))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(formatCountdown(countdown))
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)
                } else {
                    Text("Fetching times…")
                        .padding()
                        .foregroundColor(.secondary)
                }

                // Prayer Times List
                List {
                    if let times = prayerTimesManager.currentPrayerTimes {
                        PrayerRow(name: "Fajr",    time: fmt(times.fajr),    isNext: prayerTimesManager.nextPrayer == .fajr)
                        PrayerRow(name: "Sunrise", time: fmt(times.sunrise), isNext: prayerTimesManager.nextPrayer == .sunrise)
                        PrayerRow(name: "Dhuhr",   time: fmt(times.dhuhr),   isNext: prayerTimesManager.nextPrayer == .dhuhr)
                        PrayerRow(name: "Asr",     time: fmt(times.asr),     isNext: prayerTimesManager.nextPrayer == .asr)
                        PrayerRow(name: "Maghrib", time: fmt(times.maghrib), isNext: prayerTimesManager.nextPrayer == .maghrib)
                        PrayerRow(name: "Isha",    time: fmt(times.isha),    isNext: prayerTimesManager.nextPrayer == .isha)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Azan")
            .onAppear { locationManager.requestLocation() }
            .onChange(of: locationManager.locationString) { _ in
                guard let loc = locationManager.location else { return }
                prayerTimesManager.calculateTimes(
                    coordinate: loc,
                    countryCode: locationManager.countryCode)
            }
        }
    }

    // MARK: - Helpers

    private func fmt(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.unitsStyle = .positional
        f.zeroFormattingBehavior = .pad
        return f.string(from: interval) ?? "00:00:00"
    }

    private func prayerName(_ prayer: Prayer) -> String {
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

struct PrayerRow: View {
    let name: String
    let time: String
    let isNext: Bool

    var body: some View {
        HStack {
            Text(name).font(.headline)
            Spacer()
            Text(time)
                .font(.title3)
                .fontWeight(isNext ? .bold : .regular)
                .foregroundColor(isNext ? .blue : .primary)
        }
        .padding(.vertical, 4)
    }
}

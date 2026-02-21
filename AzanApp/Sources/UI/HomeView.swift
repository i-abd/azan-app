import SwiftUI


struct HomeView: View {
    @EnvironmentObject var prayerTimesManager: PrayerTimesManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header: Hijri Date & Location
                VStack {
                    Text(prayerTimesManager.getCurrentHijriDate())
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if let error = locationManager.error {
                        Text("Location Error: \(error)").foregroundColor(.red).font(.caption)
                    } else if locationManager.location == nil {
                        Text("Locating...").font(.caption)
                    }
                }
                .padding(.top)
                
                // Countdown Widget
                if let nextPrayer = prayerTimesManager.nextPrayer, let countdown = prayerTimesManager.countdown {
                    VStack {
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
                    Text("Fetching times...")
                        .padding()
                }

                // Prayer Times List
                List {
                    if let times = prayerTimesManager.currentPrayerTimes {
                        PrayerRow(name: "Fajr", time: formatTime(times.fajr), isNext: prayerTimesManager.nextPrayer == .fajr)
                        PrayerRow(name: "Sunrise", time: formatTime(times.sunrise), isNext: prayerTimesManager.nextPrayer == .sunrise)
                        PrayerRow(name: "Dhuhr", time: formatTime(times.dhuhr), isNext: prayerTimesManager.nextPrayer == .dhuhr)
                        PrayerRow(name: "Asr", time: formatTime(times.asr), isNext: prayerTimesManager.nextPrayer == .asr)
                        PrayerRow(name: "Maghrib", time: formatTime(times.maghrib), isNext: prayerTimesManager.nextPrayer == .maghrib)
                        PrayerRow(name: "Isha", time: formatTime(times.isha), isNext: prayerTimesManager.nextPrayer == .isha)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Azan")
            .onAppear {
                locationManager.requestLocation()
            }
            .onChange(of: locationManager.locationString) { _ in
                if let loc = locationManager.location {
                    prayerTimesManager.calculateTimes(coordinate: loc, countryCode: locationManager.countryCode)
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? "00:00:00"
    }

    private func prayerName(_ prayer: Prayer) -> String {
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

struct PrayerRow: View {
    let name: String
    let time: String
    let isNext: Bool
    
    var body: some View {
        HStack {
            Text(name)
                .font(.headline)
            Spacer()
            Text(time)
                .font(.title3)
                .fontWeight(isNext ? .bold : .regular)
                .foregroundColor(isNext ? .blue : .primary)
        }
        .padding(.vertical, 4)
    }
}

import Foundation
import CoreLocation

class PrayerTimesManager: ObservableObject {
    @Published var currentPrayerTimes: PrayerTimes?
    @Published var nextPrayer: Prayer?
    @Published var countdown: TimeInterval?

    private var timer: Timer?

    init() {
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    func calculateTimes(coordinate: CLLocationCoordinate2D, countryCode: String?, customMethod: CalculationMethod? = nil) {
        let coordinates = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Auto-detect calculation method based on country or use custom
        var params: CalculationParameters
        if let custom = customMethod {
            params = custom.params
        } else {
            params = defaultCalculationMethod(for: countryCode).params
        }

        // Madhab is generally Shafi (except Hanafi in some regions)
        params.madhab = .shafi
        
        let date = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        
        if let prayerTimes = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params) {
            DispatchQueue.main.async {
                self.currentPrayerTimes = prayerTimes
                self.updateNextPrayer()
            }
        }
    }

    private func defaultCalculationMethod(for countryCode: String?) -> CalculationMethod {
        guard let code = countryCode?.uppercased() else { return .muslimWorldLeague }
        
        switch code {
        case "US", "CA": return .northAmerica
        case "EG": return .egyptian
        case "PK", "IN", "BD": return .karachi
        case "SA": return .ummAlQura
        case "AE", "BH", "OM", "YE": return .dubai
        case "QA": return .qatar
        case "KW": return .kuwait
        case "SG", "MY": return .singapore
        case "TR": return .turkey
        case "GB": return .moonsightingCommittee
        default: return .muslimWorldLeague
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNextPrayer()
        }
    }

    private func updateNextPrayer() {
        guard let times = currentPrayerTimes else { return }
        
        let now = Date()
        
        // Find the next prayer time manually
        let allPrayers: [(Prayer, Date)] = [
            (.fajr, times.fajr),
            (.sunrise, times.sunrise),
            (.dhuhr, times.dhuhr),
            (.asr, times.asr),
            (.maghrib, times.maghrib),
            (.isha, times.isha)
        ]
        
        if let next = allPrayers.first(where: { $0.1 > now }) {
            self.nextPrayer = next.0
            self.countdown = next.1.timeIntervalSince(now)
        } else {
            self.nextPrayer = nil
            self.countdown = nil
        }
    }

    func getCurrentHijriDate() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

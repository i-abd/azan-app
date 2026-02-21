import Foundation
import CoreLocation
import Adhan

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
        case "US", "CA": return .isna
        case "EG": return .egyptian
        case "PK", "IN", "BD": return .karachi
        case "SA": return .ummAlQura
        case "AE", "QA", "BH", "KW", "OM", "YE": return .dubai
        case "QA": return .qatar
        case "KW": return .kuwait
        case "SG": return .singapore
        case "MY": return .singapore // Often used in Malaysia too
        case "TR": return .turkey
        case "GB", "UK": return .moonsightingCommittee
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
        self.nextPrayer = times.nextPrayer()
        
        if let next = nextPrayer, next != .none {
            if let time = times.time(for: next) {
                self.countdown = time.timeIntervalSince(now)
            }
        } else {
            // Next prayer is tomorrow's Fajr
            self.countdown = nil
        }
    }

    func getCurrentHijriDate() -> String {
        let formatter = DateFormatter()
        // Use the Islamic Calendar (Umm al-Qura is common)
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

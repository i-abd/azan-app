import Foundation
import CoreLocation

// Mapping table shared by PrayerTimesManager and SettingsView.
// Index → (Display Name, Aladhan method ID, Adhan offline method)
struct CalculationMethodInfo {
    let displayName: String
    let aladhanId: Int
    let adhanMethod: CalculationMethod
}

let calculationMethodList: [CalculationMethodInfo] = [
    CalculationMethodInfo(displayName: "Muslim World League", aladhanId: 3,  adhanMethod: .muslimWorldLeague),
    CalculationMethodInfo(displayName: "Egyptian",            aladhanId: 5,  adhanMethod: .egyptian),
    CalculationMethodInfo(displayName: "Karachi",             aladhanId: 1,  adhanMethod: .karachi),
    CalculationMethodInfo(displayName: "Umm Al-Qura (Makkah)",aladhanId: 4,  adhanMethod: .ummAlQura),
    CalculationMethodInfo(displayName: "Dubai / Gulf",        aladhanId: 8,  adhanMethod: .dubai),
    CalculationMethodInfo(displayName: "Qatar",               aladhanId: 10, adhanMethod: .qatar),
    CalculationMethodInfo(displayName: "Kuwait",              aladhanId: 9,  adhanMethod: .kuwait),
    CalculationMethodInfo(displayName: "Moonsighting Committee", aladhanId: 15, adhanMethod: .moonsightingCommittee),
    CalculationMethodInfo(displayName: "North America (ISNA)", aladhanId: 2, adhanMethod: .northAmerica),
    CalculationMethodInfo(displayName: "Singapore",           aladhanId: 11, adhanMethod: .singapore),
    CalculationMethodInfo(displayName: "Turkey",              aladhanId: 13, adhanMethod: .turkey),
]

class PrayerTimesManager: ObservableObject {
    @Published var currentPrayerTimes: DailyPrayerTimes?
    @Published var nextPrayer: Prayer?
    @Published var countdown: TimeInterval?
    /// Changes every time prayer times are successfully fetched — observers use this to schedule notifications.
    @Published var lastUpdateTime: Date?

    private var timer: Timer?
    private var lastCoordinate: CLLocationCoordinate2D?
    private var lastCountryCode: String?
    private var lastMethodIndex: Int = -1

    init() {
        startCountdownTimer()
        scheduleMidnightRefresh()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Public

    func calculateTimes(coordinate: CLLocationCoordinate2D, countryCode: String?, customMethodIndex: Int = -1) {
        lastCoordinate = coordinate
        lastCountryCode = countryCode
        lastMethodIndex = customMethodIndex

        let methodInfo = resolveMethod(countryCode: countryCode, customIndex: customMethodIndex)
        fetchFromAladhan(latitude: coordinate.latitude,
                         longitude: coordinate.longitude,
                         aladhanId: methodInfo.aladhanId) { [weak self] times in
            if let times = times {
                DispatchQueue.main.async {
                    self?.currentPrayerTimes = times
                    self?.lastUpdateTime = Date()
                    self?.updateNextPrayer()
                }
            } else {
                // No internet or API error — use local Adhan library as fallback
                self?.calculateOffline(coordinate: coordinate,
                                       adhanMethod: methodInfo.adhanMethod)
            }
        }
    }

    // MARK: - Aladhan API

    private func fetchFromAladhan(latitude: Double, longitude: Double, aladhanId: Int,
                                  completion: @escaping (DailyPrayerTimes?) -> Void) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let urlString = "https://api.aladhan.com/v1/timings/\(timestamp)?latitude=\(latitude)&longitude=\(longitude)&method=\(aladhanId)"

        guard let url = URL(string: urlString) else { completion(nil); return }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Aladhan API unavailable: \(error?.localizedDescription ?? "no data")")
                completion(nil)
                return
            }

            do {
                guard
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let dataObj = json["data"] as? [String: Any],
                    let timings = dataObj["timings"] as? [String: String]
                else {
                    completion(nil)
                    return
                }

                guard
                    let fajr    = self.parseAPITime(timings["Fajr"]    ?? ""),
                    let sunrise = self.parseAPITime(timings["Sunrise"] ?? ""),
                    let dhuhr   = self.parseAPITime(timings["Dhuhr"]   ?? ""),
                    let asr     = self.parseAPITime(timings["Asr"]     ?? ""),
                    let maghrib = self.parseAPITime(timings["Maghrib"] ?? ""),
                    let isha    = self.parseAPITime(timings["Isha"]    ?? "")
                else {
                    completion(nil)
                    return
                }

                completion(DailyPrayerTimes(fajr: fajr, sunrise: sunrise,
                                            dhuhr: dhuhr, asr: asr,
                                            maghrib: maghrib, isha: isha))

            } catch {
                print("Aladhan JSON parse error: \(error)")
                completion(nil)
            }
        }.resume()
    }

    /// Parses "HH:mm" from Aladhan into a Date for today in the device's local timezone.
    private func parseAPITime(_ timeStr: String) -> Date? {
        let parts = timeStr.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        var components = Calendar.current.dateComponents(in: .current, from: Date())
        components.hour = parts[0]
        components.minute = parts[1]
        components.second = 0
        return Calendar.current.date(from: components)
    }

    // MARK: - Offline Fallback (Adhan library)

    private func calculateOffline(coordinate: CLLocationCoordinate2D, adhanMethod: CalculationMethod) {
        let coords = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var params = adhanMethod.params
        params.madhab = .shafi
        let date = Calendar.current.dateComponents([.year, .month, .day], from: Date())

        guard let pt = PrayerTimes(coordinates: coords, date: date, calculationParameters: params) else { return }

        let times = DailyPrayerTimes(fajr: pt.fajr, sunrise: pt.sunrise,
                                     dhuhr: pt.dhuhr, asr: pt.asr,
                                     maghrib: pt.maghrib, isha: pt.isha)
        DispatchQueue.main.async {
            self.currentPrayerTimes = times
            self.lastUpdateTime = Date()
            self.updateNextPrayer()
        }
    }

    // MARK: - Method Resolution

    private func resolveMethod(countryCode: String?, customIndex: Int) -> CalculationMethodInfo {
        // User explicitly picked a method
        if customIndex >= 0, customIndex < calculationMethodList.count {
            return calculationMethodList[customIndex]
        }
        // Auto-detect from country
        guard let code = countryCode?.uppercased() else { return calculationMethodList[0] }
        switch code {
        case "SA":           return calculationMethodList[3]  // Umm Al-Qura
        case "AE","BH","OM","YE": return calculationMethodList[4]  // Dubai/Gulf
        case "QA":           return calculationMethodList[5]  // Qatar
        case "KW":           return calculationMethodList[6]  // Kuwait
        case "EG":           return calculationMethodList[1]  // Egyptian
        case "PK","IN","BD": return calculationMethodList[2]  // Karachi
        case "US","CA":      return calculationMethodList[8]  // ISNA
        case "SG","MY":      return calculationMethodList[9]  // Singapore
        case "TR":           return calculationMethodList[10] // Turkey
        case "GB":           return calculationMethodList[7]  // Moonsighting
        default:             return calculationMethodList[0]  // Muslim World League
        }
    }

    // MARK: - Countdown Timer

    private func startCountdownTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNextPrayer()
        }
    }

    private func updateNextPrayer() {
        guard let times = currentPrayerTimes else { return }
        let now = Date()
        let ordered: [(Prayer, Date)] = [
            (.fajr, times.fajr),
            (.sunrise, times.sunrise),
            (.dhuhr, times.dhuhr),
            (.asr, times.asr),
            (.maghrib, times.maghrib),
            (.isha, times.isha)
        ]
        if let next = ordered.first(where: { $0.1 > now }) {
            self.nextPrayer = next.0
            self.countdown = next.1.timeIntervalSince(now)
        } else {
            self.nextPrayer = nil
            self.countdown = nil
        }
    }

    // MARK: - Midnight Refresh

    /// Schedules a one-shot timer to refresh prayer times just after midnight each day.
    private func scheduleMidnightRefresh() {
        let cal = Calendar.current
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()),
              let midnight = cal.date(bySettingHour: 0, minute: 1, second: 0, of: tomorrow)
        else { return }

        let delay = midnight.timeIntervalSinceNow
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, let coord = self.lastCoordinate else { return }
            self.calculateTimes(coordinate: coord,
                                countryCode: self.lastCountryCode,
                                customMethodIndex: self.lastMethodIndex)
            self.scheduleMidnightRefresh() // arm again for the next day
        }
    }

    func getCurrentHijriDate() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

import Foundation

/// Our own prayer times model, independent of any library.
/// Used as the single source of truth from both the API and offline fallback.
struct DailyPrayerTimes {
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
}

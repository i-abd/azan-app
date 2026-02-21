import Foundation
import SwiftUI

enum SoundSetting: Codable, Hashable {
    case defaultBeep
    case makkahAzan
    case custom(String)
    case silent
}

class SettingsManager: ObservableObject {
    @AppStorage("fajrSound") private var fajrSoundData: Data = try! JSONEncoder().encode(SoundSetting.makkahAzan)
    @AppStorage("dhuhrSound") private var dhuhrSoundData: Data = try! JSONEncoder().encode(SoundSetting.defaultBeep)
    @AppStorage("asrSound") private var asrSoundData: Data = try! JSONEncoder().encode(SoundSetting.makkahAzan)
    @AppStorage("maghribSound") private var maghribSoundData: Data = try! JSONEncoder().encode(SoundSetting.makkahAzan)
    @AppStorage("ishaSound") private var ishaSoundData: Data = try! JSONEncoder().encode(SoundSetting.makkahAzan)
    
    // We can also store the custom calculation method here
    @AppStorage("calculationMethodIndex") var calculationMethodIndex: Int = -1

    func soundPreference(for prayer: Prayer) -> SoundSetting {
        let decoder = JSONDecoder()
        switch prayer {
        case .fajr: return (try? decoder.decode(SoundSetting.self, from: fajrSoundData)) ?? .makkahAzan
        case .dhuhr: return (try? decoder.decode(SoundSetting.self, from: dhuhrSoundData)) ?? .defaultBeep
        case .asr: return (try? decoder.decode(SoundSetting.self, from: asrSoundData)) ?? .makkahAzan
        case .maghrib: return (try? decoder.decode(SoundSetting.self, from: maghribSoundData)) ?? .makkahAzan
        case .isha: return (try? decoder.decode(SoundSetting.self, from: ishaSoundData)) ?? .makkahAzan
        default: return .defaultBeep
        }
    }

    func setSoundPreference(for prayer: Prayer, to setting: SoundSetting) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(setting) else { return }
        
        switch prayer {
        case .fajr: fajrSoundData = data
        case .dhuhr: dhuhrSoundData = data
        case .asr: asrSoundData = data
        case .maghrib: maghribSoundData = data
        case .isha: ishaSoundData = data
        default: break
        }
        
        // Notify observers explicitly since we're modifying UserDefaults inside a class
        objectWillChange.send()
    }
}

import Foundation
import AVFoundation
import UserNotifications

/// Manages Azan audio playback.
/// - When the app is in the FOREGROUND at prayer time, plays the full Azan via AVAudioPlayer.
/// - When the app is in the BACKGROUND, the scheduled UNNotification fires and plays
///   the bundled makkah.mp3 sound (up to 30 seconds, iOS limit).
class AzanAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AzanAudioPlayer()
    
    private var player: AVAudioPlayer?
    @Published var isPlaying = false
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AzanAudioPlayer: Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Playback
    
    /// Play the Azan sound for a given prayer.
    /// This is called when the app is in the FOREGROUND to play the full audio.
    func playAzan(soundName: String = "makkah") {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("AzanAudioPlayer: Could not find \(soundName).mp3 in bundle")
            // Fall back to default sound via a local notification
            playFallbackAlert()
            return
        }
        
        stop()
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            print("AzanAudioPlayer: Playing \(soundName).mp3")
        } catch {
            print("AzanAudioPlayer: Playback failed: \(error)")
        }
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
    
    // MARK: - Foreground Notification Intercept
    
    /// Called by AppDelegate/SceneDelegate when a notification fires while the app is in foreground.
    /// This replaces the short notification beep with full AVAudioPlayer playback.
    func handleForegroundPrayerNotification(soundName: String) {
        playAzan(soundName: soundName)
    }
    
    // MARK: - Fallback
    
    private func playFallbackAlert() {
        // Fire a simple system sound so the user at least hears something
        let content = UNMutableNotificationContent()
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: "fallback-\(Date())", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}

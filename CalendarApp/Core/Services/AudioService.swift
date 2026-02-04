import AVFoundation
import Foundation

class AudioService {
    static let shared = AudioService()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    func playAlarmSound(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf") ?? Bundle.main.url(forResource: "default", withExtension: "caf") else {
            playSystemSound()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            playSystemSound()
        }
    }
    
    func playTimerEndSound() {
        playSystemSound()
    }
    
    func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }
    
    private func playSystemSound() {
        AudioServicesPlaySystemSound(1007)
    }
}

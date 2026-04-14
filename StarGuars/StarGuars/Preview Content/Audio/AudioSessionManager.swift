import AVFoundation
import Foundation

class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    // Notificación cuando hay una interrupción
    var onInterruptionBegan: (() -> Void)?
    var onInterruptionEnded: (() -> Void)?
    
    private init() {
        setupAudioSession()
    }
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
            
            print("Audio session setup successfully")
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("Audio interruption began")
            onInterruptionBegan?()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                print("Audio interruption ended - should resume")
                onInterruptionEnded?()
            }
        @unknown default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
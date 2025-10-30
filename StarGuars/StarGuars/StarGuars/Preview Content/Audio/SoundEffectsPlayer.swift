import AVFoundation
import Foundation

class SoundEffectsPlayer {
    static let shared = SoundEffectsPlayer()
    
    // Configuración
    private let EFFECTS_VOLUME: Float = 2.0
    
    // Estado
    private var player: AVAudioPlayer?
    private(set) var isEnabled = false
    
    private init() {}
    
    // MARK: - Efectos directos al player
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        print("SoundEffectsPlayer - Enabled: \(isEnabled)")
    }
    
    func toggleEnabled() {
        isEnabled.toggle()
    }
    
    func playImpactSound() {
        playSound(named: "impact", volume: EFFECTS_VOLUME)
    }
    
    func playLevelUpSound() {
        playSound(named: "level", volume: EFFECTS_VOLUME)
    }
    
    func playLaserSound() {
        playSound(named: "laser", volume: EFFECTS_VOLUME * 0.7)
    }
    
    func playExplosionSound() {
        // Si no existe un archivo específico para explosión, usamos el de impacto con mayor volumen
        playSound(named: "impact", volume: EFFECTS_VOLUME * 1.2)
    }
    
    // MARK: - Private methods
    
    private func playSound(named name: String, volume: Float) {
        guard isEnabled else { return }
        
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.volume = min(volume, 2.0)
                player?.play()
            } catch {
                print("Could not play sound effect \(name): \(error)")
            }
        } else {
            print("Could not find sound effect: \(name)")
        }
    }
} 

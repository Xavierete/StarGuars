import Foundation
import SwiftUI

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    // Constantes para las notificaciones
    static let musicChangedNotification = NSNotification.Name("AudioManagerMusicChanged")
    static let effectsChangedNotification = NSNotification.Name("AudioManagerEffectsChanged")
    
    // Propiedades publicadas para el UI
    @Published var isMusicEnabled = false {
        didSet {
            // Notificar a los observadores del cambio
            NotificationCenter.default.post(
                name: AudioManager.musicChangedNotification,
                object: self,
                userInfo: ["enabled": isMusicEnabled]
            )
        }
    }
    
    @Published var isSoundEffectsEnabled = false {
        didSet {
            // Notificar a los observadores del cambio
            NotificationCenter.default.post(
                name: AudioManager.effectsChangedNotification,
                object: self,
                userInfo: ["enabled": isSoundEffectsEnabled]
            )
        }
    }
    
    // Componentes
    private let musicPlayer = MusicPlayer.shared
    private let soundEffects = SoundEffectsPlayer.shared
    
    private init() {
        // Configurar el delegado de música
        musicPlayer.delegate = self
        
        // Inicializar la sesión de audio
        _ = AudioSessionManager.shared
    }
    
    // MARK: - Música
    
    func toggleMusic() {
        isMusicEnabled.toggle()
        print("AudioManager - Toggle music: \(isMusicEnabled)")
        if isMusicEnabled {
            startBackgroundMusic()
        } else {
            stopBackgroundMusic()
        }
    }
    
    func startBackgroundMusic() {
        guard isMusicEnabled else { return }
        musicPlayer.setEnabled(true)
        musicPlayer.play()
        print("AudioManager - Starting background music")
    }
    
    func pauseBackgroundMusic() {
        musicPlayer.pause()
        print("AudioManager - Pausing background music")
    }
    
    func stopBackgroundMusic() {
        musicPlayer.setEnabled(false)
        musicPlayer.stop()
        print("AudioManager - Stopping background music")
    }
    
    // MARK: - Efectos de sonido
    
    func toggleSoundEffects() {
        isSoundEffectsEnabled.toggle()
        soundEffects.setEnabled(isSoundEffectsEnabled)
    }
    
    func playImpactSound() {
        guard isSoundEffectsEnabled else { return }
        soundEffects.playImpactSound()
    }
    
    func playLevelUpSound() {
        guard isSoundEffectsEnabled else { return }
        soundEffects.playLevelUpSound()
    }
    
    func playLaserSound() {
        guard isSoundEffectsEnabled else { return }
        soundEffects.playLaserSound()
    }
    
    func playExplosionSound() {
        guard isSoundEffectsEnabled else { return }
        soundEffects.playExplosionSound()
    }
}

// MARK: - MusicPlayerDelegate
extension AudioManager: MusicPlayerDelegate {
    func musicTrackDidFinishPlaying() {
        // Podemos agregar lógica adicional aquí si es necesario
        // cuando una pista de música termina
    }
} 
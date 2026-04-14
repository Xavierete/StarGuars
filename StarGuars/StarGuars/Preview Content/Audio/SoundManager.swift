import AVFoundation
import SwiftUI

// MARK: - SoundManager Class
class SoundManager: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = SoundManager()
    
    // MARK: - Dependencies
    private let audioManager = AudioManager.shared
    
    // MARK: - Published Properties
    @Published var isMusicEnabled = false {
        didSet {
            // Sincronizar con AudioManager sin crear un ciclo infinito
            if audioManager.isMusicEnabled != isMusicEnabled {
                audioManager.isMusicEnabled = isMusicEnabled
            }
        }
    }
    
    @Published var isSoundEffectsEnabled = false {
        didSet {
            // Sincronizar con AudioManager sin crear un ciclo infinito
            if audioManager.isSoundEffectsEnabled != isSoundEffectsEnabled {
                audioManager.isSoundEffectsEnabled = isSoundEffectsEnabled
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        // Inicializar los valores con el estado actual del AudioManager
        self.isMusicEnabled = audioManager.isMusicEnabled
        self.isSoundEffectsEnabled = audioManager.isSoundEffectsEnabled
        
        super.init()
        
        // Observar cambios en el AudioManager para mantener sincronizado
        setupObservers()
    }
    
    // MARK: - Observer Setup
    private func setupObservers() {
        // Suscribirse a cambios en el AudioManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioManagerDidChangeMusic(_:)),
            name: AudioManager.musicChangedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioManagerDidChangeEffects(_:)),
            name: AudioManager.effectsChangedNotification,
            object: nil
        )
    }
    
    @objc private func audioManagerDidChangeMusic(_ notification: Notification) {
        // Actualizar nuestra propiedad si la del AudioManager cambió externamente
        if let isEnabled = notification.userInfo?["enabled"] as? Bool,
           isEnabled != isMusicEnabled {
            DispatchQueue.main.async {
                self.isMusicEnabled = isEnabled
            }
        }
    }
    
    @objc private func audioManagerDidChangeEffects(_ notification: Notification) {
        // Actualizar nuestra propiedad si la del AudioManager cambió externamente
        if let isEnabled = notification.userInfo?["enabled"] as? Bool,
           isEnabled != isSoundEffectsEnabled {
            DispatchQueue.main.async {
                self.isSoundEffectsEnabled = isEnabled
            }
        }
    }
    
    func startBackgroundMusic() {
        audioManager.startBackgroundMusic()
    }
    
    func stopBackgroundMusic() {
        audioManager.stopBackgroundMusic()
    }
    
    func toggleMusic() {
        // No necesitamos actualizar nuestro estado directamente,
        // ya que el cambio en AudioManager nos llegará por la notificación
        audioManager.toggleMusic()
    }
    
    func toggleSoundEffects() {
        // No necesitamos actualizar nuestro estado directamente,
        // ya que el cambio en AudioManager nos llegará por la notificación
        audioManager.toggleSoundEffects()
    }
    
    func playImpactSound() {
        audioManager.playImpactSound()
    }
    
    func playLevelUpSound() {
        audioManager.playLevelUpSound()
    }
    
    func playLaserSound() {
        audioManager.playLaserSound()
    }
    
    func playExplosionSound() {
        audioManager.playExplosionSound()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
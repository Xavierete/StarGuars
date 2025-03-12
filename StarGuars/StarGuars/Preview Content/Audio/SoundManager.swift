import AVFoundation
import SwiftUI

/// Clase de compatibilidad para mantener el código existente funcionando
/// mientras se migra al nuevo sistema de audio
class SoundManager: NSObject, ObservableObject {
    static let shared = SoundManager()
    
    // Usamos el AudioManager para todas las operaciones
    private let audioManager = AudioManager.shared
    
    // Propiedades almacenadas que reflejan el estado del AudioManager
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
    
    override init() {
        // Inicializar los valores con el estado actual del AudioManager
        self.isMusicEnabled = audioManager.isMusicEnabled
        self.isSoundEffectsEnabled = audioManager.isSoundEffectsEnabled
        
        super.init()
        
        // Observar cambios en el AudioManager para mantener sincronizado
        setupObservers()
    }
    
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
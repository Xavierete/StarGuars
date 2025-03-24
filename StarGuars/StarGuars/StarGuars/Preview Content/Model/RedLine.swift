import Foundation
import SwiftUI

// MARK: - RedLine Class
class RedLine: Sprite, Identifiable {
    // MARK: - Properties
    let id = UUID()
    
    // MARK: - Visual Properties
    private enum Constants {
        // Tiempos principales
        static let warningDuration: Double = 1.6    // Duración total de la advertencia
        static let firingDuration: Double = 1.8     // Duración del láser activo
        static let fadeOutDuration: Double = 1.2    // Duración del desvanecimiento
        
        // Dimensiones
        static let beamWidth: CGFloat = 24.0
        static let sideLineWidth: CGFloat = 4.0
        static let sideLineOffset: CGFloat = 6.0    // Distancia base desde la línea central
        static let sideLineExpandedOffset: CGFloat = 12.0 // Distancia cuando está expandido
        static let collisionMargin: CGFloat = 5.0
        static let safeMargin: CGFloat = 80.0
        
        // Probabilidades
        static let baseProb: Double = 0.005
        static let levelBonus: Double = 0.002
        static let maxProb: Double = 0.02
        
        // Cooldown
        static let baseCooldown: Double = 5.0
        static let cooldownReduction: Double = 0.2
        static let minCooldown: Double = 3.0
        
        // Fases de animación
        static let phaseOneDuration: Double = 0.8    // Fase de advertencia verde
        static let phaseTwoDuration: Double = 0.6    // Transición a fase mortal
        static let phaseThreeDuration: Double = 0.7  // Fase de desvanecimiento
        static let transitionDuration: Double = 0.3  // Duración de las transiciones
        
        // Opacidades
        static let initialOpacity: Double = 0.4     // Verde inicial más visible
        static let warningOpacity: Double = 0.8     // Aumentado para mejor visibilidad
        static let dangerOpacity: Double = 1.0      // Máxima intensidad en fase mortal
        static let fadeOpacity: Double = 0.5        // Fase de desvanecimiento
        
        // Colores
        static let initialGreen = Color.green.opacity(0.6)
        static let warningOrange = Color.orange     // Naranja puro para mejor visibilidad
        static let beamRed = Color.red              // Rojo puro para la línea central
    }
    
    // Estados visuales
    var opacity: Double = 0.5
    var shadowOpacity: Double = 0.4
    var leftLineOpacity: Double = 0.5
    var rightLineOpacity: Double = 0.5
    var glowIntensity: Double = 0.3
    var pulseScale: Double = 1.0
    var beamWidth: CGFloat = Constants.beamWidth
    var orangeLineShadowOpacity: Double = 0.4
    var glowRadius: CGFloat = 4.0
    var laserColor: Color = .green
    var sideLineColor: Color = .green.opacity(0.7)
    var isVisible: Bool = false
    var currentColor: Color = .green
    var sideColor: Color = .green
    var sideLineOffset: CGFloat = 6.0
    
    // MARK: - State Properties
    var isActive: Bool = true
    var isDeadly: Bool = false
    var isBeaming: Bool = false
    var isPaused: Bool = false
    
    // MARK: - Private Properties
    private var elapsedTime: Double = 0
    
    // MARK: - Static Methods
    
    static func shouldGenerateLaser(forLevel level: Int) -> Bool {
        guard level >= 9 else { return false }
        
        let levelBonus = Double(level - 9) * Constants.levelBonus
        let laserProbability = min(Constants.baseProb + levelBonus, Constants.maxProb)
        
        return Double.random(in: 0...1) < laserProbability
    }
    
    static func getCooldownDuration(forLevel level: Int) -> Double {
        return max(Constants.baseCooldown - (Double(level - 9) * Constants.cooldownReduction), 
                  Constants.minCooldown)
    }
    
    static func generateLevelUpLaser(screenWidth: CGFloat, level: Int) -> RedLine? {
        guard level >= 9 else { return nil }
        return RedLine(screenWidth: screenWidth)
    }
    
    // MARK: - Initialization
    
    init(screenWidth: CGFloat) {
        let xPosition = CGFloat.random(in: Constants.safeMargin...(screenWidth - Constants.safeMargin))
        super.init(center: CGPoint(x: xPosition, y: 0), 
                  width: screenWidth, 
                  height: UIScreen.main.bounds.height)
        
        startAnimation()
    }
    
    // MARK: - Animation Methods
    
    private func startAnimation() {
        // Reset inicial
        isDeadly = false
        isBeaming = false
        isActive = true
        leftLineOpacity = 0.0
        rightLineOpacity = 0.0
        opacity = 0.0
        
        // Fase 1: Aparición inicial con rojo y naranja
        withAnimation(.easeInOut(duration: Constants.phaseOneDuration)) {
            isVisible = true
            opacity = Constants.initialOpacity
            leftLineOpacity = Constants.initialOpacity
            rightLineOpacity = Constants.initialOpacity
            currentColor = Constants.beamRed
            sideColor = Constants.warningOrange
            sideLineOffset = Constants.sideLineOffset
        }
        
        // Fase 2: Transición a fase mortal
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.phaseOneDuration) {
            withAnimation(.easeInOut(duration: Constants.phaseTwoDuration)) {
                self.opacity = Constants.warningOpacity
                self.leftLineOpacity = Constants.warningOpacity
                self.rightLineOpacity = Constants.warningOpacity
                self.currentColor = Constants.beamRed
                self.sideColor = Constants.warningOrange
                self.sideLineOffset = Constants.sideLineExpandedOffset
                self.isDeadly = true
                self.isBeaming = true
            }
            
            // Fase 3: Mantener fase mortal
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.firingDuration) {
                // Desactivar la fase mortal
                self.isDeadly = false
                self.isBeaming = false
                
                // Fase 4: Desvanecimiento
                withAnimation(.easeInOut(duration: Constants.phaseThreeDuration)) {
                    self.opacity = Constants.fadeOpacity
                    self.leftLineOpacity = Constants.fadeOpacity
                    self.rightLineOpacity = Constants.fadeOpacity
                    self.sideLineOffset = Constants.sideLineOffset
                    self.currentColor = Constants.beamRed.opacity(0.5)
                    self.sideColor = Constants.warningOrange.opacity(0.5)
                }
                
                // Fase 5: Desaparición final
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.phaseThreeDuration) {
                    withAnimation(.easeOut(duration: Constants.transitionDuration)) {
                        self.opacity = 0.0
                        self.leftLineOpacity = 0.0
                        self.rightLineOpacity = 0.0
                        self.glowIntensity = 0.0
                        self.glowRadius = 0.0
                    }
                    
                    // Limpieza final
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.transitionDuration) {
                        self.isVisible = false
                        self.isActive = false
                        self.isDeadly = false
                        self.isBeaming = false
                        self.currentColor = Constants.beamRed
                        self.sideColor = Constants.warningOrange
                        self.sideLineOffset = Constants.sideLineOffset
                        self.leftLineOpacity = 0.0
                        self.rightLineOpacity = 0.0
                        self.opacity = 0.0
                    }
                }
            }
        }
    }
    
    private func animateYellowPhase() {
        withAnimation(.easeIn(duration: 0.6)) {
            updateVisualState(opacity: 0.7, glow: 0.6, radius: 8.0, color: .yellow)
        }
    }
    
    private func animateOrangePhase() {
        withAnimation(.easeIn(duration: 0.6)) {
            updateVisualState(opacity: 0.8, glow: 0.8, radius: 10.0, color: .orange)
        }
    }
    
    private func animateFiringPhase() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.warningDuration) { [weak self] in
            self?.startFiring()
        }
    }
    
    private func startFiring() {
        isDeadly = true
        
        // Animación del disparo con spring suavizado
        withAnimation(
            .spring(
                response: 0.4,
                dampingFraction: 0.8,
                blendDuration: 0.3
            )
        ) {
            isBeaming = true
            beamWidth = Constants.beamWidth * 1.15 // Expansión suave
            
            updateVisualState(
                opacity: Constants.dangerOpacity,
                glow: 1.0,
                radius: 12.0,
                color: Constants.beamRed,
                sideColor: Constants.warningOrange
            )
        }

        // Ajuste fino del beam
        withAnimation(.easeInOut(duration: 0.2).delay(0.2)) {
            beamWidth = Constants.beamWidth
        }
        
        // Sonido sincronizado
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            SoundManager.shared.playLaserSound()
        }
        
        // Programar fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.firingDuration) { [weak self] in
            self?.startFadeOut()
        }
    }
    
    private func updateVisualState(opacity: Double, glow: Double, radius: CGFloat, color: Color, sideColor: Color? = nil) {
        // Actualización directa para mayor fluidez
        self.opacity = opacity
        self.shadowOpacity = opacity * 0.85
        self.leftLineOpacity = opacity
        self.rightLineOpacity = opacity
        self.glowIntensity = glow
        self.orangeLineShadowOpacity = opacity * 0.8
        self.glowRadius = radius
        self.laserColor = color
        self.currentColor = color
        self.sideLineColor = sideColor ?? color.opacity(opacity * 0.95)
        self.sideColor = sideColor ?? color.opacity(opacity * 0.95)
    }
    
    // MARK: - Fade Out Animation
    
    private func startFadeOut() {
        isDeadly = false
        isBeaming = false
        
        let totalFadeOutDuration = Constants.fadeOutDuration / 2
        
        // Fase 1: Reducción de intensidad manteniendo colores
        withAnimation(
            .spring(
                response: totalFadeOutDuration,
                dampingFraction: 0.8,
                blendDuration: 0.3
            )
        ) {
            updateVisualState(
                opacity: 0.6,
                glow: 0.6,
                radius: 8.0,
                color: Constants.beamRed,
                sideColor: Constants.warningOrange.opacity(0.6)
            )
        }
        
        // Fase 2: Desvanecimiento final suave
        withAnimation(
            .easeOut(duration: totalFadeOutDuration)
            .delay(totalFadeOutDuration)
        ) {
            updateVisualState(
                opacity: 0.0,
                glow: 0.0,
                radius: 0.0,
                color: .clear,
                sideColor: .clear
            )
        }
        
        // Limpieza
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.fadeOutDuration) { [weak self] in
            self?.isActive = false
        }
    }
    
    // MARK: - Game Loop
    
    func update() {
        guard !isPaused && isActive else { return }
        elapsedTime += 1.0 / 60.0 // 60 FPS
    }
    
    // MARK: - Collision Detection
    
    override func checkCollisionWith(_ frame: CGRect) -> Bool {
        guard isDeadly && isActive else { return false }
        
        let redLineRect = CGRect(
            x: center.x - beamWidth/2,
            y: 0,
            width: beamWidth,
            height: UIScreen.main.bounds.height
        )
        
        let sideLineRects = getSideLineRects()
        return frame.intersects(redLineRect) ||
               frame.intersects(sideLineRects.left) ||
               frame.intersects(sideLineRects.right)
    }
    
    private func getSideLineRects() -> (left: CGRect, right: CGRect) {
        let left = CGRect(
            x: center.x - (beamWidth/2 + sideLineOffset + Constants.sideLineWidth),
            y: 0,
            width: Constants.sideLineWidth,
            height: UIScreen.main.bounds.height
        )
        
        let right = CGRect(
            x: center.x + (beamWidth/2 + sideLineOffset),
            y: 0,
            width: Constants.sideLineWidth,
            height: UIScreen.main.bounds.height
        )
        
        return (left, right)
    }
    
    // MARK: - State Management
    
    func setPaused(_ paused: Bool) {
        isPaused = paused
    }
    
    func deactivate() {
        // Desactivar inmediatamente estados críticos
        isDeadly = false
        isBeaming = false
        
        // Animación de desaparición rápida
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0.0
            leftLineOpacity = 0.0
            rightLineOpacity = 0.0
            glowIntensity = 0.0
            glowRadius = 0.0
            currentColor = Constants.beamRed
            sideColor = Constants.warningOrange
            sideLineOffset = Constants.sideLineOffset
        }
        
        // Limpieza final
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isVisible = false
            self.isActive = false
            self.leftLineOpacity = 0.0
            self.rightLineOpacity = 0.0
            self.opacity = 0.0
        }
    }
} 
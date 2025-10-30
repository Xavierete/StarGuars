import Foundation
import SwiftUI

// MARK: - RedLine Class
class RedLine: Sprite, Identifiable {
    // MARK: - Properties
    let id = UUID()
    
    // MARK: - Visual Properties
    private enum Constants {
        // Main timings
        static let warningDuration: Double = 0.8
        static let firingDuration: Double = 1.0
        static let fadeOutDuration: Double = 0.6
        
        // Dimensions
        static let beamWidth: CGFloat = 24.0
        static let sideLineWidth: CGFloat = 4.0
        static let sideLineOffset: CGFloat = 6.0
        static let sideLineExpandedOffset: CGFloat = 12.0
        static let collisionMargin: CGFloat = 5.0
        static let safeMargin: CGFloat = 80.0
        
        // Probabilities
        static let baseProb: Double = 0.005
        static let levelBonus: Double = 0.002
        static let maxProb: Double = 0.02
        
        // Cooldown
        static let baseCooldown: Double = 5.0
        static let cooldownReduction: Double = 0.2
        static let minCooldown: Double = 3.0
        
        // Animation phases
        static let phaseOneDuration: Double = 0.4    // Warning phase
        static let phaseTwoDuration: Double = 0.3    // Transition to deadly phase
        static let phaseThreeDuration: Double = 0.4  // Fade out phase
        static let transitionDuration: Double = 0.15  // Transition duration
        
        // Opacities
        static let initialOpacity: Double = 0.4
        static let warningOpacity: Double = 0.8
        static let dangerOpacity: Double = 1.0
        static let fadeOpacity: Double = 0.5
        
        // Colors
        static let initialGreen = Color.green.opacity(0.6)
        static let warningOrange = Color.orange
        static let beamRed = Color.red
    }
    
    // Visual states
    private(set) var opacity: Double = 0.5
    private(set) var shadowOpacity: Double = 0.4
    private(set) var leftLineOpacity: Double = 0.5
    private(set) var rightLineOpacity: Double = 0.5
    private(set) var glowIntensity: Double = 0.3
    private(set) var pulseScale: Double = 1.0
    private(set) var beamWidth: CGFloat = Constants.beamWidth
    private(set) var orangeLineShadowOpacity: Double = 0.4
    private(set) var glowRadius: CGFloat = 4.0
    private(set) var laserColor: Color = .green
    private(set) var sideLineColor: Color = .green.opacity(0.7)
    private(set) var isVisible: Bool = false
    private(set) var currentColor: Color = .green
    private(set) var sideColor: Color = .green
    private(set) var sideLineOffset: CGFloat = 6.0
    
    // State properties
    private(set) var isActive: Bool = true
    private(set) var isDeadly: Bool = false
    private(set) var isBeaming: Bool = false
    private(set) var isPaused: Bool = false
    
    // Private properties
    private var elapsedTime: Double = 0
    private var animationTask: Task<Void, Never>?
    private var cachedCollisionRects: (beam: CGRect, left: CGRect, right: CGRect)?
    
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
    
    deinit {
        animationTask?.cancel()
    }
    
    // MARK: - Animation Methods
    private func startAnimation() {
        // Reset initial state
        isDeadly = false
        isBeaming = false
        isActive = true
        leftLineOpacity = 0.0
        rightLineOpacity = 0.0
        opacity = 0.0
        cachedCollisionRects = nil
        
        animationTask?.cancel()
        animationTask = Task {
            // Phase 1: Initial appearance
            await animatePhaseOne()
            
            // Phase 2: Transition to deadly phase
            await animatePhaseTwo()
            
            // Phase 3: Fade out
            await animatePhaseThree()
        }
    }
    
    private func animatePhaseOne() async {
        withAnimation(.spring(response: Constants.phaseOneDuration, dampingFraction: 0.7, blendDuration: 0.2)) {
            isVisible = true
            opacity = Constants.initialOpacity
            leftLineOpacity = Constants.initialOpacity
            rightLineOpacity = Constants.initialOpacity
            currentColor = Constants.beamRed
            sideColor = Constants.warningOrange
            sideLineOffset = Constants.sideLineOffset
        }
        try? await Task.sleep(nanoseconds: UInt64(Constants.phaseOneDuration * 1_000_000_000))
    }
    
    private func animatePhaseTwo() async {
        withAnimation(.spring(response: Constants.phaseTwoDuration, dampingFraction: 0.6, blendDuration: 0.2)) {
            opacity = Constants.warningOpacity
            leftLineOpacity = Constants.warningOpacity
            rightLineOpacity = Constants.warningOpacity
            currentColor = Constants.beamRed
            sideColor = Constants.warningOrange
            sideLineOffset = Constants.sideLineExpandedOffset
            isDeadly = true
            isBeaming = true
        }
        
        // Play sound effect
        SoundManager.shared.playLaserSound()
        
        try? await Task.sleep(nanoseconds: UInt64(Constants.firingDuration * 1_000_000_000))
        
        isDeadly = false
        isBeaming = false
    }
    
    private func animatePhaseThree() async {
        withAnimation(.spring(response: Constants.phaseThreeDuration, dampingFraction: 0.7, blendDuration: 0.2)) {
            opacity = Constants.fadeOpacity
            leftLineOpacity = Constants.fadeOpacity
            rightLineOpacity = Constants.fadeOpacity
            sideLineOffset = Constants.sideLineOffset
            currentColor = Constants.beamRed.opacity(0.5)
            sideColor = Constants.warningOrange.opacity(0.5)
        }
        
        try? await Task.sleep(nanoseconds: UInt64(Constants.phaseThreeDuration * 1_000_000_000))
        
        withAnimation(.spring(response: Constants.transitionDuration, dampingFraction: 0.8, blendDuration: 0.1)) {
            opacity = 0.0
            leftLineOpacity = 0.0
            rightLineOpacity = 0.0
            glowIntensity = 0.0
            glowRadius = 0.0
        }
        
        try? await Task.sleep(nanoseconds: UInt64(Constants.transitionDuration * 1_000_000_000))
        
        // Final cleanup
        isVisible = false
        isActive = false
        isDeadly = false
        isBeaming = false
        currentColor = Constants.beamRed
        sideColor = Constants.warningOrange
        sideLineOffset = Constants.sideLineOffset
        leftLineOpacity = 0.0
        rightLineOpacity = 0.0
        opacity = 0.0
        cachedCollisionRects = nil
    }
    
    // MARK: - Game Loop
    func update() {
        guard !isPaused && isActive else { return }
        elapsedTime += 1.0 / 60.0
    }
    
    // MARK: - Collision Detection
    override func checkCollisionWith(_ frame: CGRect) -> Bool {
        guard isDeadly && isActive else { return false }
        
        // Cache collision rectangles to avoid recalculating them
        if cachedCollisionRects == nil {
            let beamRect = CGRect(
                x: center.x - beamWidth/2,
                y: 0,
                width: beamWidth,
                height: UIScreen.main.bounds.height
            )
            
            let sideLineRects = getSideLineRects()
            cachedCollisionRects = (beamRect, sideLineRects.left, sideLineRects.right)
        }
        
        guard let rects = cachedCollisionRects else { return false }
        return frame.intersects(rects.beam) ||
               frame.intersects(rects.left) ||
               frame.intersects(rects.right)
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
        animationTask?.cancel()
        isDeadly = false
        isBeaming = false
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.1)) {
            opacity = 0.0
            leftLineOpacity = 0.0
            rightLineOpacity = 0.0
            glowIntensity = 0.0
            glowRadius = 0.0
            currentColor = Constants.beamRed
            sideColor = Constants.warningOrange
            sideLineOffset = Constants.sideLineOffset
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            isVisible = false
            isActive = false
            leftLineOpacity = 0.0
            rightLineOpacity = 0.0
            opacity = 0.0
            cachedCollisionRects = nil
        }
    }
} 

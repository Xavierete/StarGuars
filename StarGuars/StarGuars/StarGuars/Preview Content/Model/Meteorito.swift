import Foundation
import SwiftUI

// MARK: - Meteorito Class
class Meteorito: Sprite, Identifiable {
    // MARK: - Properties
    let id = UUID()
    
    // MARK: - Constants
    private enum Constants {
        static let baseSpeed: ClosedRange<CGFloat> = 1.5...3.0
        static let baseRotation: ClosedRange<Double> = -15...15
        static let specialRotation: ClosedRange<Double> = -30...30
        static let meteor3Rotation: ClosedRange<Double> = -0.3...0.3
        static let normalRotation: ClosedRange<Double> = -1...1
        static let deathstarRotation: ClosedRange<Double> = -0.08...0.08
        static let deathstarRotationDuration: Double = 1.2
        static let baseSize: CGFloat = 0.07
        static let bigSizeMultiplier: CGFloat = 1.5
        static let collisionMargin: CGFloat = 5.0
        static let collisionUpdateInterval: CFTimeInterval = 1.0 / 30.0
        
        // Velocidad
        static let specialSpeedMultiplier: CGFloat = 1.2
        static let zigzagSpeedMultiplier: CGFloat = 0.85
        static let bigSpeedMultiplier: CGFloat = 0.5
        static let levelSpeedIncrease: Double = 0.1
        
        // Zigzag (solo para meteoritos zigzag)
        static let zigzagAmplitudeRange: ClosedRange<CGFloat> = 30...80
        static let zigzagFrequencyRange: ClosedRange<CGFloat> = 2.0...3.5

        // Generación
        static let earlyLevelDoubleSpawnProbability: Double = 0.4
        static let maxEarlyLevel: Int = 4
        static let specialMinLevel: Int = 5
        static let zigzagMinLevel: Int = 8
        static let bigMinLevel: Int = 10
        static let deathstarBaseProbability: Double = 0.12
        static let deathstarLevelIncrease: Double = 0.015
        static let deathstarMaxProbability: Double = 0.25
    }
    
    // MARK: - Visual Properties
    var speed: CGFloat
    var iconColor: Color
    var rotation: Double = 0
    var imageName: String? = nil
    
    // MARK: - Movement Properties
    var zigzagAmplitude: CGFloat = 0
    var zigzagFrequency: CGFloat = 0
    var initialX: CGFloat = 0
    var elapsedTime: CGFloat = 0
    
    // MARK: - State Properties
    var isSpecial: Bool = false
    var isZigzag: Bool = false
    var isBig: Bool = false
    var currentLevel: Int = 1
    var isPaused: Bool = false
    var isColliding: Bool = false
    var collisionOpacity: Double = 1.0
    var puntosPorSalida: Int = 1
    
    // MARK: - Collision Properties
    private var collisionFrame: CGRect = .zero
    private var lastCollisionUpdate: CFTimeInterval = 0
    
    // MARK: - Initialization
    
    override init(center: CGPoint, width: CGFloat, height: CGFloat) {
        self.speed = CGFloat.random(in: Constants.baseSpeed)
        self.iconColor = Bool.random() ? .red : .orange
        self.rotation = Double.random(in: Constants.baseRotation)
        
        let meteoritoSize = min(width, height) * Constants.baseSize
        super.init(center: center, width: meteoritoSize, height: meteoritoSize)
        updateCollisionFrame()
    }
    
    convenience init(center: CGPoint, width: CGFloat, height: CGFloat, isSpecial: Bool, isZigzag: Bool = false, isBig: Bool = false, speedMultiplier: CGFloat = 1.0, currentLevel: Int = 1) {
        self.init(center: center, width: width, height: height)
        self.currentLevel = currentLevel
        
        configureSpeed(currentLevel: currentLevel)
        configureType(isSpecial: isSpecial, isZigzag: isZigzag, isBig: isBig, width: width)
    }
    
    // MARK: - Configuration Methods
    
    private func configureSpeed(currentLevel: Int) {
        let levelSpeedMultiplier = 1.0 + (Double(currentLevel - 1) * Constants.levelSpeedIncrease)
        self.speed *= CGFloat(levelSpeedMultiplier)
    }
    
    private func configureType(isSpecial: Bool, isZigzag: Bool, isBig: Bool, width: CGFloat) {
        if isSpecial {
            configureSpecial()
        }
        
        if isZigzag {
            configureZigzag(width: width)
        }
        
        if isBig {
            configureBig(width: width)
        }
    }
    
    private func configureSpecial() {
        isSpecial = true
        rotation = Double.random(in: Constants.specialRotation)
        puntosPorSalida = 2
        speed *= Constants.specialSpeedMultiplier
    }
    
    private func configureZigzag(width: CGFloat) {
        isZigzag = true
        zigzagAmplitude = min(width * 0.25, CGFloat.random(in: Constants.zigzagAmplitudeRange))
        zigzagFrequency = CGFloat.random(in: Constants.zigzagFrequencyRange)
        initialX = center.x
        speed *= Constants.zigzagSpeedMultiplier
        imageName = "meteor2"
        puntosPorSalida = 3
    }
    
    private func configureBig(width: CGFloat) {
        isBig = true
        speed *= Constants.bigSpeedMultiplier
        imageName = "deathstar"
        puntosPorSalida = 4
    }
    
    // MARK: - Static Generation Methods
    
    static func generateMeteoritosForLevel(in size: CGSize, currentLevel: Int, isEarlyLevel: Bool = false) -> [Meteorito] {
        if isEarlyLevel && currentLevel <= Constants.maxEarlyLevel {
            return generateEarlyLevelMeteorites(in: size, currentLevel: currentLevel)
        } else {
            return [generateRandomMeteorito(in: size, currentLevel: currentLevel)]
        }
    }

    private static func generateEarlyLevelMeteorites(in size: CGSize, currentLevel: Int) -> [Meteorito] {
        if Double.random(in: 0...1) < Constants.earlyLevelDoubleSpawnProbability {
            // Intentar generar dos meteoritos normales
            let meteorito1 = generateRandomMeteorito(in: size, currentLevel: currentLevel)
            let meteorito2 = generateRandomMeteorito(in: size, currentLevel: currentLevel)
            
            // Solo devolver ambos si son meteoritos normales
            if !meteorito1.isSpecial && !meteorito1.isZigzag && !meteorito1.isBig &&
               !meteorito2.isSpecial && !meteorito2.isZigzag && !meteorito2.isBig {
                return [meteorito1, meteorito2]
            }
        }
        
        // Si no se generaron dos, devolver uno solo
        return [generateRandomMeteorito(in: size, currentLevel: currentLevel)]
    }
    
    static func generateRandomMeteorito(in size: CGSize, currentLevel: Int) -> Meteorito {
        let isSpecial = Bool.random() && currentLevel >= Constants.specialMinLevel
        let isZigzag = Bool.random() && currentLevel >= Constants.zigzagMinLevel
        
        // Probabilidad del deathstar
        let deathstarProbability = min(
            Constants.deathstarBaseProbability + 
            (Double(currentLevel - Constants.bigMinLevel) * Constants.deathstarLevelIncrease),
            Constants.deathstarMaxProbability
        )
        let isBig = Double.random(in: 0...1) < deathstarProbability && currentLevel >= Constants.bigMinLevel
        
        let baseSize = min(size.width, size.height) * Constants.baseSize
        let actualSize = isBig ? baseSize * Constants.bigSizeMultiplier : baseSize
        
        let margin = actualSize / 2
        let x = CGFloat.random(in: margin...(size.width - margin))
        let y: CGFloat = -actualSize
        
        return Meteorito(
            center: CGPoint(x: x, y: y),
            width: actualSize,
            height: actualSize,
            isSpecial: isSpecial,
            isZigzag: isZigzag,
            isBig: isBig,
            currentLevel: currentLevel
        )
    }
    
    // MARK: - Movement
    
    func setPaused(_ paused: Bool) {
        isPaused = paused
    }
    
    func move() -> Int? {
        guard !isPaused else { return nil }
        
        updateRotation()
        updatePosition()
        updateCollisionFrame()
        
        return checkScreenCollision() ? puntosPorSalida : nil
    }
    
    private func updateRotation() {
        let rotationSpeed: Double
        let animationDuration: Double
        
        if isSpecial {
            rotationSpeed = Double.random(in: -3...3)
            animationDuration = 0.3
        } else if isBig {
            rotationSpeed = Double.random(in: Constants.deathstarRotation)
            animationDuration = Constants.deathstarRotationDuration
        } else if currentLevel >= 10 && !isZigzag {
            rotationSpeed = Double.random(in: Constants.meteor3Rotation)
            animationDuration = 0.4
        } else {
            rotationSpeed = Double.random(in: Constants.normalRotation)
            animationDuration = 0.5
        }
        
        if isBig {
            withAnimation(.spring(response: animationDuration, dampingFraction: 0.7, blendDuration: 0.3)) {
                rotation += rotationSpeed
            }
        } else {
            withAnimation(.linear(duration: animationDuration)) {
                rotation += rotationSpeed
            }
        }
    }
    
    private func updatePosition() {
        center.y += speed
        
        if isZigzag {
            elapsedTime += 0.016
            let newX = initialX + sin(elapsedTime * zigzagFrequency) * zigzagAmplitude
            let currentX = center.x
            let targetX = min(max(newX, minX + width/2), maxX - width/2)
            center.x = currentX + (targetX - currentX) * 0.1
        }
    }
    
    private func updateCollisionFrame() {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastCollisionUpdate >= Constants.collisionUpdateInterval else { return }
        
        collisionFrame = CGRect(
            x: center.x - (width / 2) + Constants.collisionMargin,
            y: center.y - (height / 2) + Constants.collisionMargin,
            width: width - (Constants.collisionMargin * 2),
            height: height - (Constants.collisionMargin * 2)
        )
        lastCollisionUpdate = currentTime
    }
    
    // MARK: - Collision Handling
    
    override func checkScreenCollision() -> Bool {
        return center.y > maxY
    }
    
    override func checkCollisionWith(_ frame: CGRect) -> Bool {
        if isColliding { return true }
        
        let currentTime = CACurrentMediaTime()
        if currentTime - lastCollisionUpdate >= Constants.collisionUpdateInterval {
            if center.y >= -height && center.y <= UIScreen.main.bounds.height + height {
                updateCollisionFrame()
                lastCollisionUpdate = currentTime
            }
        }
        
        let hasCollided: Bool
        if isBig {
            // Área de colisión más grande para Death Stars
            let expandedFrame = collisionFrame.insetBy(dx: -10, dy: -10)
            hasCollided = expandedFrame.intersects(frame)
        } else {
            hasCollided = collisionFrame.intersects(frame)
        }
        
        if hasCollided && !isColliding {
            handleCollision()
        }
        return hasCollided
    }
    
    private func handleCollision() {
        isColliding = true
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.3)) {
                self.collisionOpacity = 0.0
            }
            SoundManager.shared.playExplosionSound()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.restart()
        }
    }
    
    // MARK: - Reset & Restart
    
    private func resetPosition() {
        let safeMinX = minX + width
        let safeMaxX = maxX - width
        
        let randomX = safeMaxX > safeMinX ? 
            CGFloat.random(in: safeMinX...safeMaxX) : 
            (minX + maxX) / 2
        
        center.y = -height * 2
        center.x = randomX
        initialX = randomX
        elapsedTime = 0
        
        resetSpeed()
        resetZigzagProperties()
        
        isColliding = false
        collisionOpacity = 1.0
    }
    
    private func resetSpeed() {
        var baseSpeed = CGFloat.random(in: Constants.baseSpeed)
        if isSpecial {
            baseSpeed *= Constants.specialSpeedMultiplier
        } else if isBig {
            baseSpeed *= Constants.bigSpeedMultiplier
        } else if isZigzag {
            baseSpeed *= Constants.zigzagSpeedMultiplier
        }
        self.speed = baseSpeed
    }
    
    private func resetZigzagProperties() {
        if isZigzag || (isBig && currentLevel >= 9) {
            if isBig {
                if currentLevel >= 15 {
                    zigzagAmplitude = min(width * 0.4, CGFloat.random(in: Constants.zigzagAmplitudeRange))
                    zigzagFrequency = CGFloat.random(in: Constants.zigzagFrequencyRange)
                } else if currentLevel >= 9 {
                    zigzagAmplitude = min(width * 0.3, CGFloat.random(in: Constants.zigzagAmplitudeRange))
                    zigzagFrequency = CGFloat.random(in: Constants.zigzagFrequencyRange)
                }
            } else {
                zigzagAmplitude = min(width * 0.35, CGFloat.random(in: Constants.zigzagAmplitudeRange))
                zigzagFrequency = CGFloat.random(in: Constants.zigzagFrequencyRange)
            }
        }
    }
    
    func restart() {
        withAnimation(.easeOut(duration: 0.3)) {
            resetPosition()
        }
    }
    
    // MARK: - Image Name
    
    func getImageName() -> String {
        if let customName = imageName {
            return customName
        }
        
        if isZigzag {
            return "meteor2"
        }
        
        if isBig {
            return "deathstar"
        }
        
        return currentLevel >= 10 ? "meteor3" : "meteor"
    }
}

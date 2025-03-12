import Foundation
import SwiftUI

class Obstacle: Sprite, Identifiable {
    let id = UUID()
    var speed: CGFloat
    var iconColor: Color  // Cambiado de let a var
    var rotation: Double = 0 // Nueva propiedad para la rotación
    var isSpecial: Bool = false // Indica si es un meteorito especial
    var isZigzag: Bool = false  // Nueva propiedad para meteoritos zigzag
    var isBig: Bool = false  // Nueva propiedad para meteoritos grandes y lentos
    var imageName: String? = nil  // Nueva propiedad para la imagen personalizada
    var zigzagAmplitude: CGFloat = 0  // Amplitud del movimiento lateral
    var zigzagFrequency: CGFloat = 0  // Frecuencia del movimiento lateral
    var initialX: CGFloat = 0  // Posición X inicial para calcular el zigzag
    var elapsedTime: CGFloat = 0  // Tiempo transcurrido para el movimiento zigzag
    var currentLevel: Int = 1  // Añadimos el nivel actual
    
    // Inicializador que acepta center, width y height
    override init(center: CGPoint, width: CGFloat, height: CGFloat) {
        self.speed = CGFloat.random(in: 3...6)
        // Color aleatorio entre rojo y naranja
        self.iconColor = Bool.random() ? .red : .orange
        // Inicializar con una rotación aleatoria
        self.rotation = Double.random(in: -15...15)
        super.init(center: center, width: width, height: height)
    }
    
    // Inicializador para meteoritos especiales
    convenience init(center: CGPoint, width: CGFloat, height: CGFloat, isSpecial: Bool, isZigzag: Bool = false, isBig: Bool = false, speedMultiplier: CGFloat = 1.0, currentLevel: Int = 1) {
        self.init(center: center, width: width, height: height)
        
        if isSpecial {
            self.isSpecial = true
            self.rotation = Double.random(in: -30...30)
        }
        
        if isZigzag {
            self.isZigzag = true
            self.zigzagAmplitude = CGFloat.random(in: 50...100)
            self.zigzagFrequency = CGFloat.random(in: 1.5...3.0)
            self.initialX = center.x
            self.speed *= 0.7
            self.imageName = "meteor2"
        }

        if isBig {
            self.isBig = true
            self.speed *= 0.5
            self.imageName = "deathstar"
            self.currentLevel = currentLevel
            if currentLevel >= 15 {
                // Movimiento zigzag más pronunciado después del nivel 15
                self.zigzagAmplitude = CGFloat.random(in: 80...120)  // Mayor amplitud
                self.zigzagFrequency = CGFloat.random(in: 1.2...2.0)  // Frecuencia más alta
                self.initialX = center.x
            } else if currentLevel >= 9 {
                // Mantener el movimiento zigzag original para niveles 9-14
                self.zigzagAmplitude = CGFloat.random(in: 30...60)
                self.zigzagFrequency = CGFloat.random(in: 0.8...1.5)
                self.initialX = center.x
            }
        }
        
        self.speed *= speedMultiplier
    }
    
    func move() {
        // Incrementar la rotación ligeramente en cada movimiento
        if isSpecial {
            rotation += Double.random(in: -5...5)
        } else if isBig {
            // Rotación más suave para el deathstar
            rotation += Double.random(in: -0.8...0.8)
        } else {
            rotation += Double.random(in: -2...2)
        }
        
        // Mover el meteorito
        withAnimation(.linear(duration: 0.016)) {
            // Movimiento vertical para todos los meteoritos
            self.center.y += speed
            
            // Movimiento horizontal para meteoritos zigzag y deathstar nivel 9+
            if isZigzag || (isBig && currentLevel >= 9) {
                elapsedTime += 0.016
                let amplitude = isZigzag ? zigzagAmplitude : zigzagAmplitude
                let frequency = isZigzag ? zigzagFrequency : zigzagFrequency
                self.center.x = initialX + sin(elapsedTime * frequency) * amplitude
            }
        }
    }

    func restart() {
        self.center.y = 0
        self.center.x = CGFloat.random(in: 50..<UIScreen.main.bounds.maxX - 50)
        self.speed = CGFloat.random(in: 3...6)
    }

    // Usar el método checkScreenCollision de Sprite
    override func checkScreenCollision() -> Bool {
        return super.checkScreenCollision()
    }

    override func checkCollisionWith(_ frame: CGRect) -> Bool {
        // Crear un área de colisión más pequeña que el tamaño visual
        let collisionMargin: CGFloat = 5.0 // Margen de reducción
        let obstacleFrame = CGRect(
            x: center.x - (width / 2) + collisionMargin,
            y: center.y - (height / 2) + collisionMargin,
            width: width - (collisionMargin * 2),
            height: height - (collisionMargin * 2)
        )
        return obstacleFrame.intersects(frame)
    }
}

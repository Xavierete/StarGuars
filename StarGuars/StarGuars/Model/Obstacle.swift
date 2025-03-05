import Foundation
import SwiftUI

class Obstacle: Sprite, Identifiable {
    let id = UUID()
    var speed: CGFloat
    let iconColor: Color  // Nueva propiedad para el color
    
    // Inicializador que acepta center, width y height
    override init(center: CGPoint, width: CGFloat, height: CGFloat) {
        self.speed = CGFloat.random(in: 3...6)
        // Color aleatorio entre rojo y naranja
        self.iconColor = Bool.random() ? .red : .orange
        super.init(center: center, width: width, height: height)
    }
    
    func move() {
        withAnimation(.linear(duration: 0.016)) {  // Aproximadamente 60 FPS (1/60 ≈ 0.016)
            self.center.y += speed
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
        return super.checkCollisionWith(frame)
    }
}

import Foundation
import SwiftUI

class Player: Sprite {
    let color: Color = .white
    var selectedShipImage: String = "starship3"
    var isPaused: Bool = false
    
    override init(center: CGPoint, width: CGFloat, height: CGFloat) {
        let playerWidth: CGFloat = min(width, height) * 0.15
        let playerHeight: CGFloat = playerWidth
        
        let initialCenter = CGPoint(
            x: width / 2,
            y: height * 0.75
        )
        
        super.init(center: initialCenter, width: playerWidth, height: playerHeight)
        
        self.center = CGPoint(
            x: (maxX + minX) / 2,
            y: maxY * 0.75
        )
    }
    
    // Método para inicializar el jugador con un tamaño específico
    static func initialize(with size: CGSize) -> Player {
        return Player(center: CGPoint(x: size.width / 2, y: size.height * 0.75), width: size.width, height: size.height)
    }
    
    // Método para actualizar la imagen de la nave
    func updateShipImage(_ image: String) {
        selectedShipImage = image
    }
    
    // Método para obtener el tamaño de la nave según el tipo
    func getShipSize() -> (width: CGFloat, height: CGFloat) {
        return (width: width, height: height)
    }

    func moveToPoint(_ point: CGPoint) {
        let constrainedX = min(max(point.x, minX + width / 2), maxX - width / 2)
        let constrainedY = min(max(point.y, minY + height / 2), maxY - height / 2)
        withAnimation(.spring()) {
            self.center = CGPoint(x: constrainedX, y: constrainedY)
        }
    }
    
    // Método para pausar/reanudar el movimiento
    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    override func checkScreenCollision() -> Bool {
        return super.checkScreenCollision()
    }

    override func checkCollisionWith(_ frame: CGRect) -> Bool {
        let collisionScale: CGFloat = 0.8
        let collisionMargin: CGFloat = 10.0
        
        let collisionWidth = width * collisionScale
        let collisionHeight = height * collisionScale
        
        let playerFrame = CGRect(
            x: center.x - (collisionWidth / 2) + collisionMargin,
            y: center.y - (collisionHeight / 2) + collisionMargin,
            width: collisionWidth - (collisionMargin * 2),
            height: collisionHeight - (collisionMargin * 2)
        )
        return playerFrame.intersects(frame)
    }
    
    // Método para reiniciar la posición del jugador
    func resetPosition() {
        self.center = CGPoint(
            x: (maxX + minX) / 2,
            y: maxY * 0.75
        )
    }
}

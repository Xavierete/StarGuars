import Foundation
import SwiftUI

class Player: Sprite {
    let color: Color = .white
    
    override init(center: CGPoint, width: CGFloat, height: CGFloat) {
        let playerWidth: CGFloat = min(width, height) * 0.1
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

    func moveToPoint(_ point: CGPoint) {
        let constrainedX = min(max(point.x, minX + width / 2), maxX - width / 2)
        withAnimation(.spring()) {
            self.center = CGPoint(x: constrainedX, y: center.y)
        }
    }

    override func checkScreenCollision() -> Bool {
        return super.checkScreenCollision()
    }

    override func checkCollisionWith(_ frame: CGRect) -> Bool {
        return super.checkCollisionWith(frame)
    }
}

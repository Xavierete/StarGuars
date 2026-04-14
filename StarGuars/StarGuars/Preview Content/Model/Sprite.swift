import Foundation
import SwiftUI

// MARK: - Sprite Class
class Sprite {
    // MARK: - Properties
    var center: CGPoint
    var width: CGFloat
    var height: CGFloat
    let gameBounds: CGRect
    
    // MARK: - Computed Properties
    var frame: CGRect {
        return CGRect(x: center.x-width/2,
                     y: center.y-height/2,
                     width: width,
                     height: height)
    }
    
    // MARK: - Screen Boundaries
    var minX: CGFloat { gameBounds.minX }
    var maxX: CGFloat { gameBounds.maxX }
    var minY: CGFloat { gameBounds.minY }
    var maxY: CGFloat { gameBounds.maxY }
    
    // MARK: - Initialization
    init(center: CGPoint, width: CGFloat, height: CGFloat, gameBounds: CGRect) {
        self.center = center
        self.width = width
        self.height = height
        self.gameBounds = gameBounds
    }
    
    // MARK: - Collision Methods
    func checkScreenCollision() -> Bool {
        return center.x >= maxX || center.x <= minX || center.y >= maxY || center.y <= minY
    }
    
    func checkCollisionWith(_ frame: CGRect) -> Bool {
        return self.frame.intersects(frame)
    }
}

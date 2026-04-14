import Foundation
import SwiftUI

// MARK: - Sprite Class
class Sprite {
    // MARK: - Properties
    var center: CGPoint
    var width: CGFloat
    var height: CGFloat
    
    // MARK: - Computed Properties
    var frame: CGRect {
        return CGRect(x: center.x-width/2,
                     y: center.y-height/2,
                     width: width,
                     height: height)
    }
    
    // MARK: - Screen Boundaries
    let minX = UIScreen.main.bounds.minX
    let maxX = UIScreen.main.bounds.maxX
    let minY = UIScreen.main.bounds.minY
    let maxY = UIScreen.main.bounds.maxY
    
    // MARK: - Initialization
    init(center: CGPoint, width: CGFloat, height: CGFloat) {
        self.center = center
        self.width = width
        self.height = height
    }
    
    // MARK: - Collision Methods
    func checkScreenCollision() -> Bool {
        return center.x >= maxX || center.x <= minX || center.y >= maxY || center.y <= minY
    }
    
    func checkCollisionWith(_ frame: CGRect) -> Bool {
        return self.frame.intersects(frame)
    }
}

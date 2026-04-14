import SwiftUI

struct ObstacleAppearance {
    let imageName: String
    let size: CGFloat
    let opacity: Double
    let rotationAnimationDuration: Double

    init(meteorito: Meteorito, level: Int) {
        if let customImageName = meteorito.imageName {
            imageName = customImageName
        } else if meteorito.isZigzag {
            imageName = "meteor2"
        } else if meteorito.isBig {
            imageName = "deathstar"
        } else {
            imageName = level >= 10 ? "meteor3" : "meteor"
        }

        if meteorito.isBig {
            size = 100
        } else if meteorito.isZigzag {
            size = 60
        } else {
            size = 80
        }

        if meteorito.isSpecial {
            rotationAnimationDuration = 0.2
        } else if meteorito.isBig {
            rotationAnimationDuration = 0.5
        } else {
            rotationAnimationDuration = 0.3
        }

        opacity = meteorito.isZigzag ? 0.9 : 1.0
    }
}

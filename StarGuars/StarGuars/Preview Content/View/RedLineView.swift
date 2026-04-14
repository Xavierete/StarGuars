import SwiftUI

struct RedLineView: View {
    let redLine: RedLine
    let geometry: GeometryProxy

    var body: some View {
        ZStack {
            Rectangle()
                .fill(redLine.laserColor.opacity(0.15))
                .frame(width: 20, height: geometry.size.height)
                .position(x: redLine.center.x, y: geometry.size.height / 2)
                .opacity(redLine.opacity * 0.8)
                .blur(radius: redLine.glowRadius * 2)

            Rectangle()
                .fill(redLine.sideLineColor)
                .frame(width: 4, height: geometry.size.height)
                .position(
                    x: redLine.center.x - (redLine.isBeaming ? (redLine.beamWidth / 2 + 6) : redLine.beamWidth / 2),
                    y: geometry.size.height / 2
                )
                .opacity(redLine.leftLineOpacity)
                .shadow(color: redLine.sideLineColor.opacity(redLine.orangeLineShadowOpacity), radius: redLine.glowRadius, x: 0, y: 0)

            Rectangle()
                .fill(redLine.sideLineColor)
                .frame(width: 4, height: geometry.size.height)
                .position(
                    x: redLine.center.x + (redLine.isBeaming ? (redLine.beamWidth / 2 + 6) : redLine.beamWidth / 2),
                    y: geometry.size.height / 2
                )
                .opacity(redLine.rightLineOpacity)
                .shadow(color: redLine.sideLineColor.opacity(redLine.orangeLineShadowOpacity), radius: redLine.glowRadius, x: 0, y: 0)

            Rectangle()
                .fill(redLine.laserColor)
                .frame(width: 4, height: geometry.size.height)
                .position(x: redLine.center.x, y: geometry.size.height / 2)
                .opacity(redLine.opacity)
                .shadow(color: redLine.laserColor.opacity(redLine.shadowOpacity), radius: redLine.glowRadius, x: 0, y: 0)
        }
    }
}

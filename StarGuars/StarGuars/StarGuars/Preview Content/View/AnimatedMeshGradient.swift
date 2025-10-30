import SwiftUI

struct AnimatedMeshGradient: View {
    @State private var appear = false
    var cornerRadius: CGFloat = 0
    var size: CGSize = .zero
    
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], appear ? [0.5, 0.5] : [0.8, 0.2], [1.0, 0.5],
                [0.0, 1.0], [appear ? 0.5 : 1.0, 1.0], [1.0, 1.0]
            ],
            colors: [
                appear ? .mint : .mint, .mint, .mint,
                .indigo, .indigo, .indigo,
                .cyan, .blue, .cyan
            ]
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .frame(width: size.width > 0 ? size.width : nil, height: size.height > 0 ? size.height : nil)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                appear.toggle()
            }
        }
    }
}

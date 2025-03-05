import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State private var appear = false
    @State private var appear2 = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0],
                        [appear2 ? 0.3 : 0.7, 0.0],
                        [1.0, 0.0],
                        [0.0, 0.5],
                        appear ? [0.3, 0.5] : [0.7, 0.3],
                        [1.0, 0.5],
                        [0.0, 1.0],
                        [appear2 ? 0.7 : 0.3, 1.0],
                        [1.0, 1.0]
                    ],
                    colors: [
                        appear2 ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.3, green: 0.8, blue: 0.7),
                        appear ? Color(red: 0.3, green: 0.6, blue: 0.9) : Color(red: 0.4, green: 0.7, blue: 0.8),
                        appear ? Color(red: 0.4, green: 0.5, blue: 1.0) : Color(red: 0.2, green: 0.6, blue: 0.9),
                        appear ? Color(red: 0.2, green: 0.7, blue: 0.8) : Color(red: 0.8, green: 0.8, blue: 1.0),
                        appear ? Color(red: 0.3, green: 0.5, blue: 0.9) : Color(red: 0.5, green: 0.3, blue: 0.8),
                        appear ? Color(red: 0.4, green: 0.6, blue: 1.0) : Color(red: 0.3, green: 0.7, blue: 0.8),
                        appear ? Color(red: 0.3, green: 0.8, blue: 0.7) : Color(red: 0.4, green: 0.5, blue: 1.0),
                        appear2 ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.2, green: 0.6, blue: 0.9)
                    ]
                )
                .frame(width: geometry.size.width + 20, height: geometry.size.height + 20)
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(
                        Animation
                            .easeInOut(duration: 4)
                            .repeatForever(autoreverses: true)
                    ) {
                        appear.toggle()
                    }
                    
                    withAnimation(
                        Animation
                            .easeInOut(duration: 3)
                            .repeatForever(autoreverses: true)
                    ) {
                        appear2.toggle()
                    }
                }
                
                // Mostrar los obstáculos
                ForEach(viewModel.obstacles) { obstacle in
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: obstacle.width, height: obstacle.height)
                        Circle()
                            .strokeBorder(Color.gray.opacity(1), lineWidth: 3)
                            .frame(width: obstacle.width, height: obstacle.height)
                        Image(systemName: "fireworks")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(obstacle.iconColor)
                            .padding(20)
                    }
                    .frame(width: obstacle.width, height: obstacle.height)
                    .position(obstacle.center)
                }
                
                if let player = viewModel.player {
                    Image("starship")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: player.width, height: player.height)
                        .shadow(color: .blue, radius: 10)
                        .position(player.center)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    viewModel.movePlayer(to: CGPoint(x: value.location.x, y: player.center.y))
                                }
                        )
                }
            }
            .onAppear {
                viewModel.initializePlayer(with: geometry.size)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

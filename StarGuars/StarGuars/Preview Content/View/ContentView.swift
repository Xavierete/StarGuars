import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ViewModel
    @State private var showStartSheet = true
    @State private var levelChanged = false
    @State private var isPauseSheet = false
    @State private var showGoldenEffect = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                gameBackground(in: geometry)

                if !showStartSheet {
                    GameSceneView(geometry: geometry)
                }

                VStack {
                    GameHUDView(
                        score: viewModel.score,
                        level: viewModel.level,
                        levelChanged: levelChanged,
                        showGoldenEffect: showGoldenEffect,
                        onPauseTapped: pauseGame
                    )

                    Spacer()
                }
                .zIndex(10)
            }
            .sheet(isPresented: $showStartSheet) {
                StartView(
                    isPresented: $showStartSheet,
                    geometry: geometry,
                    lastScore: viewModel.lastScore,
                    isPaused: isPauseSheet
                )
                .interactiveDismissDisabled(true)
            }
            .onChange(of: viewModel.level) { oldValue, newValue in
                guard oldValue != newValue else { return }
                animateLevelChange()
            }
            .onChange(of: viewModel.isGameOver) { _, newValue in
                guard newValue else { return }
                viewModel.lastScore = viewModel.score
                isPauseSheet = false
                showStartSheet = true
            }
            .edgesIgnoringSafeArea(.all)
        }
    }

    @ViewBuilder
    private func gameBackground(in geometry: GeometryProxy) -> some View {
        Image("space")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
    }

    private func pauseGame() {
        let pauseFeedback = UIImpactFeedbackGenerator(style: .medium)
        pauseFeedback.prepare()
        pauseFeedback.impactOccurred()

        viewModel.pauseGame()
        isPauseSheet = true
        showStartSheet = true
    }

    private func animateLevelChange() {
        levelChanged = true
        showGoldenEffect = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            levelChanged = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showGoldenEffect = false
            }
        }
    }
}

private struct GameSceneView: View {
    @EnvironmentObject private var viewModel: ViewModel
    let geometry: GeometryProxy

    var body: some View {
        ZStack {
            ForEach(viewModel.obstacles) { meteorito in
                let appearance = ObstacleAppearance(meteorito: meteorito, level: viewModel.level)

                Image(appearance.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: appearance.size, height: appearance.size)
                    .rotationEffect(.degrees(meteorito.rotation))
                    .scaleEffect(meteorito.isSpecial ? 1.2 : 1.0)
                    .opacity(meteorito.isColliding ? meteorito.collisionOpacity : appearance.opacity)
                    .position(meteorito.center)
                    .animation(.linear(duration: appearance.rotationAnimationDuration), value: meteorito.rotation)
                    .animation(.easeOut(duration: 0.3), value: meteorito.collisionOpacity)
            }

            ForEach(viewModel.redLines) { redLine in
                RedLineView(redLine: redLine, geometry: geometry)
            }

            if let player = viewModel.player {
                Image(viewModel.selectedShipImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: player.width, height: player.height)
                    .position(player.center)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                viewModel.movePlayer(to: value.location)
                            }
                    )
            }
        }
    }
}

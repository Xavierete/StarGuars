import SwiftUI

struct GameHUDView: View {
    let score: Int
    let level: Int
    let levelChanged: Bool
    let showGoldenEffect: Bool
    let onPauseTapped: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack {
                scoreBadge

                Button(action: onPauseTapped) {
                    Image(systemName: "pause.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .zIndex(10)

                Spacer()

                levelBadge
            }
        }
        .padding(.top, 60)
        .padding(.horizontal)
    }

    private var scoreBadge: some View {
        HStack(spacing: 0) {
            Text("Points: ")
                .font(.headline.monospaced())
                .bold()
                .foregroundColor(.white)

            NumericText(value: score)
                .font(.headline.monospaced())
                .bold()
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: score)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassEffect(.regular.interactive(false), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .zIndex(10)
    }

    private var levelBadge: some View {
        HStack(spacing: 0) {
            Text("Level ")
                .font(.headline.monospaced())
                .bold()
                .foregroundColor(levelColor)

            NumericText(value: level)
                .font(.headline.monospaced())
                .bold()
                .foregroundColor(levelColor)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: level)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassEffect(.regular.interactive(false), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .scaleEffect(levelChanged ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: levelChanged)
        .overlay(levelOverlay)
        .zIndex(10)
    }

    private var levelColor: Color {
        showGoldenEffect ? Color(red: 1.0, green: 0.84, blue: 0.0) : .white
    }

    @ViewBuilder
    private var levelOverlay: some View {
        if showGoldenEffect {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 2)
                .opacity(showGoldenEffect ? 1 : 0)
        }
    }
}

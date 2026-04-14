import SwiftUI

struct InfoView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                InfoCard(
                    icon: "deathstar",
                    title: "Beware of the Death Laser",
                    description: "The laser changes from green to red before activating. Stay away from the orange lines on the sides.",
                    useCustomImage: true
                )

                InfoCard(
                    icon: "meteor",
                    title: "Types of Meteors",
                    description: "The more you progress, the more meteors will appear. Large meteors are worth more points.",
                    useCustomImage: true
                )

                InfoCard(
                    icon: "starship3",
                    title: "Choose Your Ship",
                    description: "Each spacecraft has a different size. Experiment to find the one that works best for you.",
                    useCustomImage: true
                )

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .navigationTitle("Game Tips")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let useCustomImage: Bool

    var body: some View {
        VStack(spacing: 16) {
            if useCustomImage {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.cyan)
                    .frame(width: 80, height: 80)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

import SwiftUI

struct PremiumButtonStyle: ButtonStyle {
    var gradientColors: [Color]
    var shadowColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.bold())
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Fondo degradado
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Brillo animado
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.8), .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: configuration.isPressed ? 3 : 2
                        )
                        .blur(radius: 2)
                        .opacity(configuration.isPressed ? 1 : 0.7)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)

                    // Efecto de destello cruzando
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .white.opacity(0.4), .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                        .mask(
                            Rectangle()
                                .offset(x: configuration.isPressed ? -200 : 200)
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: configuration.isPressed)
                        )
                }
            )
            .overlay(
                // Sombra brillante
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [shadowColor.opacity(0.5), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: shadowColor.opacity(0.4), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: shadowColor.opacity(0.3), radius: configuration.isPressed ? 15 : 10, x: 0, y: 5)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

struct StartView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    Spacer()
                    
                    NavigationLink(destination: ContentView().navigationBarBackButtonHidden(true)) {
                        Text("Start exploring Star Guars!")
                    }
                    .buttonStyle(
                        PremiumButtonStyle(
                            gradientColors: [Color.indigo, Color.blue, Color.purple],
                            shadowColor: Color.blue
                        )
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

#Preview {
    StartView()
}

import SwiftUI

struct NumericText: View {
    let value: Int
    let format: String

    @State private var animatedValue: Double

    init(value: Int, format: String = "%d") {
        self.value = value
        self.format = format
        self._animatedValue = State(initialValue: Double(value))
    }

    var body: some View {
        Text(String(format: format, Int(animatedValue)))
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animatedValue = Double(value)
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animatedValue = Double(newValue)
                }
            }
    }
}

struct ShipNameText: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.title3)
            .bold()
            .foregroundColor(.indigo)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: name)
    }
}

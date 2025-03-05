import SwiftUI
import QuartzCore  // Para CADisplayLink

class ViewModel: ObservableObject {
    @Published var player: Player?
    @Published var obstacles: [Obstacle] = []  // Array de obstáculos
    @Published var dragOffset: CGFloat = 0  // Añadimos esta propiedad para el drag gesture
    
    private var displayLink: CADisplayLink?
    private var elapsedTime: Double = 0
    private var screenSize: CGSize = .zero
    private var isGameOver: Bool = false
    
    init() {
        setupDisplayLink()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(gameLoop))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    @objc private func gameLoop() {
        guard !isGameOver else { return }
        
        elapsedTime += 1.0 / 60.0  // Aproximadamente 60 FPS
        
        // Crear nuevo obstáculo cada 2 segundos
        if elapsedTime >= 2.0 {
            createObstacle()
            elapsedTime = 0  // Reiniciar el contador
        }
        
        // Mover y comprobar obstáculos existentes
        obstacles.removeAll { (obstacle: Obstacle) in
            obstacle.move()
            
            // Comprobar colisión con el jugador
            if let player = player, obstacle.checkCollisionWith(player.frame) {
                print("🔥 Oh vaya...Colisión detectada!")
                isGameOver = true
                showGameOverAlert()
                return true
            }
            
            // Comprobar colisión con los límites de la pantalla
            return obstacle.checkScreenCollision()
        }
        
        objectWillChange.send()
    }
    
    private func createObstacle() {
        // Crear el primer obstáculo
        let randomX = CGFloat.random(in: 50..<(screenSize.width - 50))
        let obstacle = Obstacle(
            center: CGPoint(x: randomX, y: 0),
            width: 80,
            height: 80
        )
        obstacles.append(obstacle)
        
        // 30% de probabilidad de crear un segundo obstáculo
        if Double.random(in: 0...1) < 0.3 {
            // Asegurar que el segundo obstáculo no esté demasiado cerca del primero
            let minDistance: CGFloat = 100
            var secondX: CGFloat
            repeat {
                secondX = CGFloat.random(in: 50..<(screenSize.width - 50))
            } while abs(secondX - randomX) < minDistance
            
            let secondObstacle = Obstacle(
                center: CGPoint(x: secondX, y: 0),
                width: 80,
                height: 80
            )
            obstacles.append(secondObstacle)
        }
    }
    
    func initializePlayer(with size: CGSize) {
        self.screenSize = size
        // Aumentamos aún más el tamaño de la nave
        self.player = Player(center: CGPoint(x: size.width / 2, y: size.height * 0.75), width: 500, height: 500)
    }
    
    func movePlayer(to point: CGPoint) {
        player?.moveToPoint(point)
        objectWillChange.send()  // Forzamos la actualización de la UI
    }
    
    // Añadimos esta función para manejar el drag gesture
    func handleDrag(_ value: DragGesture.Value) {
        if let player = player {
            let newX = value.location.x
            movePlayer(to: CGPoint(x: newX, y: player.center.y))
        }
    }
    
    private func showGameOverAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "GAME OVER", message: "¿Quieres probar de nuevo?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "¡Vamooos!", style: .default, handler: { _ in
                self.restartGame()
            }))
            alert.addAction(UIAlertAction(title: "Me rindo...", style: .cancel, handler: { _ in
                self.displayLink?.invalidate() // Detener el CADisplayLink
            }))
            
            // Obtener la ventana principal usando el método recomendado
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let topController = windowScene.windows.first?.rootViewController {
                topController.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func restartGame() {
        isGameOver = false
        player = nil
        obstacles.removeAll()
        setupDisplayLink() // Reiniciar el CADisplayLink
        initializePlayer(with: screenSize) // Reiniciar el jugador
    }
}

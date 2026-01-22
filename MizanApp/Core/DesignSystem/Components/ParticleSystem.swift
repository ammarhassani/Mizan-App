//
//  ParticleSystem.swift
//  MizanApp
//
//  Ambient particle effects system for the Dark Matter theme.
//  Provides dust, stars, embers, and wisp particles for atmospheric effects.
//  Uses Canvas and TimelineView for efficient rendering.
//

import SwiftUI

// MARK: - Particle Type

/// Types of ambient particles for the Dark Matter theme
enum ParticleType {
    /// Tiny particles (2px) with slow drift, white at 20% opacity
    case dust
    /// Small particles (4px) with static twinkle, white at 60% opacity
    case stars
    /// Medium particles (6px) floating upward near prayers, gold color
    case embers
    /// Elongated particles (2x8px) with fluid flow and rotation, cyan color
    case wisps
}

// MARK: - Particle

/// Represents a single particle in the particle system
struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var opacity: Double
    var rotation: Angle
    let type: ParticleType
    let lifetime: TimeInterval
    var age: TimeInterval

    init(
        id: UUID = UUID(),
        position: CGPoint,
        velocity: CGVector = .zero,
        size: CGFloat,
        opacity: Double,
        rotation: Angle = .zero,
        type: ParticleType,
        lifetime: TimeInterval,
        age: TimeInterval = 0
    ) {
        self.id = id
        self.position = position
        self.velocity = velocity
        self.size = size
        self.opacity = opacity
        self.rotation = rotation
        self.type = type
        self.lifetime = lifetime
        self.age = age
    }
}

// MARK: - Particle System View

/// Ambient particle effects overlay for the Dark Matter theme.
/// Uses Canvas and TimelineView for efficient rendering.
struct ParticleSystem: View {
    // MARK: - Environment

    @Environment(\.deviceCapabilities) private var capabilities

    // MARK: - Properties

    /// The type of particles to render
    let type: ParticleType

    /// The current prayer period (0-5: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
    let prayerPeriod: Int

    // MARK: - State

    @State private var particles: [Particle] = []
    @State private var lastUpdate: Date = Date()
    @State private var isInitialized = false
    @State private var viewSize: CGSize = .zero

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            SwiftUI.TimelineView(.animation(minimumInterval: frameInterval)) { timeline in
                Canvas { context, _ in
                    for particle in particles {
                        renderParticle(particle, in: context)
                    }
                }
                .onChange(of: timeline.date) { _, newDate in
                    updateParticles(currentTime: newDate)
                }
            }
            .onAppear {
                viewSize = geometry.size
                initializeParticles(in: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                viewSize = newSize
                if !isInitialized {
                    initializeParticles(in: newSize)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Computed Properties

    /// Frame interval based on device capabilities
    private var frameInterval: TimeInterval {
        1.0 / Double(capabilities.targetFrameRate)
    }

    /// Maximum particle count based on device tier
    private var maxParticleCount: Int {
        capabilities.maxParticles
    }

    /// Particle color based on type and prayer period
    private var particleColor: Color {
        switch type {
        case .dust, .stars:
            return CinematicColors.textPrimary // White
        case .embers:
            return CinematicColors.prayerGold
        case .wisps:
            return wispColorForPrayerPeriod
        }
    }

    /// Wisp color varies by prayer period using DarkMatterTheme
    private var wispColorForPrayerPeriod: Color {
        let period = prayerPeriodFromInt(prayerPeriod)
        return DarkMatterTheme.shared.particleColor(for: period)
    }

    // MARK: - Initialization

    private func initializeParticles(in size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }

        particles = (0..<maxParticleCount).map { _ in
            createParticle(in: size, randomAge: true)
        }
        isInitialized = true
        lastUpdate = Date()
    }

    private func createParticle(in size: CGSize, randomAge: Bool = false, atBottom: Bool = false) -> Particle {
        let position: CGPoint
        let velocity: CGVector
        let particleSize: CGFloat
        let opacity: Double
        let rotation: Angle
        let lifetime: TimeInterval

        switch type {
        case .dust:
            position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            velocity = CGVector(
                dx: CGFloat.random(in: -0.3...0.3),
                dy: CGFloat.random(in: -0.2...0.2)
            )
            particleSize = 2
            opacity = 0.2
            rotation = .zero
            lifetime = Double.random(in: 8...15)

        case .stars:
            position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            velocity = .zero
            particleSize = 4
            opacity = 0.6
            rotation = .zero
            lifetime = Double.random(in: 5...10)

        case .embers:
            position = atBottom
                ? CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: size.height + CGFloat.random(in: 10...30)
                )
                : CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                )
            velocity = CGVector(
                dx: CGFloat.random(in: -0.5...0.5),
                dy: CGFloat.random(in: -1.5...(-0.8))
            )
            particleSize = 6
            opacity = Double.random(in: 0.5...0.8)
            rotation = .zero
            lifetime = Double.random(in: 6...12)

        case .wisps:
            position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            velocity = CGVector(
                dx: CGFloat.random(in: -0.4...0.4),
                dy: CGFloat.random(in: -0.2...0.2)
            )
            particleSize = 2 // Width, height is 4x (8)
            opacity = Double.random(in: 0.3...0.6)
            rotation = .degrees(Double.random(in: 0...360))
            lifetime = Double.random(in: 10...20)
        }

        let age: TimeInterval = randomAge ? Double.random(in: 0...lifetime) : 0

        return Particle(
            position: position,
            velocity: velocity,
            size: particleSize,
            opacity: opacity,
            rotation: rotation,
            type: type,
            lifetime: lifetime,
            age: age
        )
    }

    // MARK: - Update Logic

    private func updateParticles(currentTime: Date) {
        let deltaTime = currentTime.timeIntervalSince(lastUpdate)
        lastUpdate = currentTime

        // Avoid large time jumps (e.g., from backgrounding)
        let cappedDelta = min(deltaTime, 0.1)

        for i in particles.indices {
            particles[i].age += cappedDelta
            updateParticle(at: i, deltaTime: cappedDelta)
        }

        // Respawn expired particles
        respawnExpiredParticles()
    }

    private func updateParticle(at index: Int, deltaTime: TimeInterval) {
        guard index < particles.count else { return }

        switch type {
        case .dust:
            updateDustParticle(at: index, deltaTime: deltaTime)
        case .stars:
            updateStarParticle(at: index, deltaTime: deltaTime)
        case .embers:
            updateEmberParticle(at: index, deltaTime: deltaTime)
        case .wisps:
            updateWispParticle(at: index, deltaTime: deltaTime)
        }
    }

    private func updateDustParticle(at index: Int, deltaTime: TimeInterval) {
        // Slow random drift
        let noise = CGFloat.random(in: -0.1...0.1)
        particles[index].velocity.dx += noise
        particles[index].velocity.dy += noise * 0.5

        // Apply velocity
        particles[index].position.x += particles[index].velocity.dx
        particles[index].position.y += particles[index].velocity.dy

        // Wrap at edges
        wrapParticlePosition(at: index)

        // Dampen velocity
        particles[index].velocity.dx *= 0.99
        particles[index].velocity.dy *= 0.99
    }

    private func updateStarParticle(at index: Int, deltaTime: TimeInterval) {
        // Stars don't move, only twinkle
        // Opacity animation is handled in render
    }

    private func updateEmberParticle(at index: Int, deltaTime: TimeInterval) {
        // Float upward with slight horizontal drift
        particles[index].position.x += particles[index].velocity.dx
        particles[index].position.y += particles[index].velocity.dy

        // Add slight horizontal wobble
        let wobble = sin(particles[index].age * 2) * 0.3
        particles[index].position.x += CGFloat(wobble)
    }

    private func updateWispParticle(at index: Int, deltaTime: TimeInterval) {
        // Fluid-like motion using noise
        let time = particles[index].age
        let noiseX = sin(time * 0.5 + Double(index)) * 0.5
        let noiseY = cos(time * 0.3 + Double(index) * 1.5) * 0.3

        particles[index].velocity.dx += CGFloat(noiseX) * 0.1
        particles[index].velocity.dy += CGFloat(noiseY) * 0.1

        // Apply velocity
        particles[index].position.x += particles[index].velocity.dx
        particles[index].position.y += particles[index].velocity.dy

        // Slow rotation
        let rotationSpeed = 15.0 // degrees per second
        particles[index].rotation += .degrees(rotationSpeed * deltaTime)

        // Dampen velocity for smooth motion
        particles[index].velocity.dx *= 0.98
        particles[index].velocity.dy *= 0.98

        // Wrap at edges
        wrapParticlePosition(at: index)
    }

    private func wrapParticlePosition(at index: Int) {
        let margin: CGFloat = 20

        // Wrap horizontally
        if particles[index].position.x < -margin {
            particles[index].position.x = viewSize.width + margin
        } else if particles[index].position.x > viewSize.width + margin {
            particles[index].position.x = -margin
        }

        // Wrap vertically
        if particles[index].position.y < -margin {
            particles[index].position.y = viewSize.height + margin
        } else if particles[index].position.y > viewSize.height + margin {
            particles[index].position.y = -margin
        }
    }

    private func respawnExpiredParticles() {
        for i in particles.indices {
            let particle = particles[i]

            // Check if particle has exceeded lifetime
            if particle.age >= particle.lifetime {
                // Respawn at appropriate location
                let respawnAtBottom = type == .embers
                particles[i] = createParticle(in: viewSize, randomAge: false, atBottom: respawnAtBottom)
            }

            // For embers, also respawn if off-screen at top
            if type == .embers && particle.position.y < -30 {
                particles[i] = createParticle(in: viewSize, randomAge: false, atBottom: true)
            }
        }
    }

    // MARK: - Rendering

    private func renderParticle(_ particle: Particle, in context: GraphicsContext) {
        let color = particleColor

        // Calculate opacity with fade in/out
        let fadeIn = min(particle.age / 0.5, 1.0)
        let fadeOut = max(0, 1.0 - (particle.age - (particle.lifetime - 1.0)) / 1.0)
        var currentOpacity = particle.opacity * fadeIn * (particle.age > particle.lifetime - 1.0 ? fadeOut : 1.0)

        // Apply twinkle effect for stars
        if particle.type == .stars {
            let twinkle = 0.5 + 0.5 * sin(particle.age * 3 + Double(particle.id.hashValue % 100) * 0.1)
            currentOpacity *= twinkle
        }

        let resolvedColor = color.opacity(currentOpacity)

        switch particle.type {
        case .dust, .embers:
            // Filled circle
            let rect = CGRect(
                x: particle.position.x - particle.size / 2,
                y: particle.position.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            context.fill(Circle().path(in: rect), with: .color(resolvedColor))

        case .stars:
            // 4-point star shape
            let starPath = fourPointStarPath(at: particle.position, size: particle.size)
            context.fill(starPath, with: .color(resolvedColor))

        case .wisps:
            // Elongated capsule with rotation
            var wispContext = context
            wispContext.translateBy(x: particle.position.x, y: particle.position.y)
            wispContext.rotate(by: particle.rotation)

            let capsuleWidth = particle.size
            let capsuleHeight = particle.size * 4 // 2x8 aspect ratio
            let capsuleRect = CGRect(
                x: -capsuleWidth / 2,
                y: -capsuleHeight / 2,
                width: capsuleWidth,
                height: capsuleHeight
            )
            wispContext.fill(Capsule().path(in: capsuleRect), with: .color(resolvedColor))
        }
    }

    /// Creates a 4-point star path
    private func fourPointStarPath(at center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let outerRadius = size / 2
        let innerRadius = outerRadius * 0.4

        for i in 0..<8 {
            let angle = Double(i) * .pi / 4 - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Helpers

    /// Convert prayer period integer to PrayerPeriod enum
    private func prayerPeriodFromInt(_ period: Int) -> PrayerPeriod {
        switch period {
        case 0: return .fajr
        case 1: return .sunrise
        case 2: return .dhuhr
        case 3: return .asr
        case 4: return .maghrib
        case 5: return .isha
        default: return .isha
        }
    }
}

// MARK: - View Modifier

/// View modifier for adding particle overlay to any view
struct ParticleOverlayModifier: ViewModifier {
    let type: ParticleType
    let prayerPeriod: Int

    func body(content: Content) -> some View {
        content.overlay {
            ParticleSystem(type: type, prayerPeriod: prayerPeriod)
        }
    }
}

extension View {
    /// Adds an ambient particle overlay to the view.
    /// - Parameters:
    ///   - type: The type of particles to display
    ///   - prayerPeriod: The current prayer period (0-5)
    /// - Returns: A view with particle effects overlaid
    func particleOverlay(type: ParticleType, prayerPeriod: Int) -> some View {
        modifier(ParticleOverlayModifier(type: type, prayerPeriod: prayerPeriod))
    }
}

// MARK: - Preview

#if DEBUG
struct ParticleSystem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Dust particles
            ZStack {
                CinematicColors.voidBlack.ignoresSafeArea()
                ParticleSystem(type: .dust, prayerPeriod: 5)
            }
            .previewDisplayName("Dust")

            // Stars
            ZStack {
                CinematicColors.voidBlack.ignoresSafeArea()
                ParticleSystem(type: .stars, prayerPeriod: 5)
            }
            .previewDisplayName("Stars")

            // Embers
            ZStack {
                CinematicColors.voidBlack.ignoresSafeArea()
                ParticleSystem(type: .embers, prayerPeriod: 0)
            }
            .previewDisplayName("Embers (Fajr)")

            // Wisps
            ZStack {
                CinematicColors.voidBlack.ignoresSafeArea()
                ParticleSystem(type: .wisps, prayerPeriod: 4)
            }
            .previewDisplayName("Wisps (Maghrib)")

            // Combined with modifier
            Text("Dark Matter")
                .font(.largeTitle)
                .foregroundColor(CinematicColors.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CinematicColors.voidBlack)
                .particleOverlay(type: .wisps, prayerPeriod: 5)
                .previewDisplayName("With Modifier")
        }
    }
}
#endif

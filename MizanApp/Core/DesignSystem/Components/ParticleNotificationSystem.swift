//
//  ParticleNotificationSystem.swift
//  Mizan
//
//  A breathtaking particle-based notification system that creates
//  divine visual effects for prayer times and task reminders
//

import SwiftUI
import UserNotifications
import Combine

struct ParticleNotificationSystem: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var activeNotifications: [ParticleNotification] = []
    @State private var particleField: [NotificationParticle] = []
    @State private var lightBeams: [NotificationLightBeam] = []
    @State private var rippleEffects: [NotificationRippleEffect] = []
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        ZStack {
            // Dynamic particle field
            ForEach(particleField) { particle in
                NotificationParticleView(particle: particle, phase: animationPhase)
            }

            // Divine light beams for important notifications
            ForEach(lightBeams) { beam in
                NotificationBeamView(beam: beam, phase: animationPhase)
            }

            // Ripple effects for new notifications
            ForEach(rippleEffects) { ripple in
                NotificationRippleView(ripple: ripple, phase: animationPhase)
            }

            // Active notification cards
            VStack(spacing: MZSpacing.md) {
                Spacer()
                ForEach(activeNotifications) { notification in
                    ParticleNotificationCard(
                        notification: notification,
                        phase: animationPhase,
                        onDismiss: { dismissNotification(notification) }
                    )
                    .environmentObject(themeManager)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .padding(MZSpacing.md)
        }
        .onAppear {
            startParticleAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ShowParticleNotification"))) { notification in
            if let userInfo = notification.userInfo,
               let notificationData = userInfo["notification"] as? ParticleNotification {
                showNotification(notificationData)
            }
        }
    }

    // MARK: - Animation Control

    private func startParticleAnimation() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }

    // MARK: - Notification Management

    private func showNotification(_ notification: ParticleNotification) {
        // Generate particles for this notification
        generateNotificationParticles(for: notification)

        // Generate light beams for important notifications
        if notification.importance == .high || notification.importance == .critical {
            generateNotificationLightBeams(for: notification)
        }

        // Generate ripple effect
        generateRippleEffect(for: notification)

        // Add to active notifications
        withAnimation(MZAnimation.bouncy) {
            activeNotifications.append(notification)
        }

        // Trigger haptic based on importance
        switch notification.importance {
        case .critical:
            HapticManager.shared.trigger(.error)
        case .high:
            HapticManager.shared.trigger(.warning)
        case .medium:
            HapticManager.shared.trigger(.success)
        case .low:
            HapticManager.shared.trigger(.light)
        }

        // Auto-dismiss after duration
        if notification.duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) {
                dismissNotification(notification)
            }
        }
    }

    private func dismissNotification(_ notification: ParticleNotification) {
        withAnimation(MZAnimation.snappy) {
            if let index = activeNotifications.firstIndex(where: { $0.id == notification.id }) {
                activeNotifications.remove(at: index)
            }
        }

        // Generate dismissal particles
        generateDismissalParticles(for: notification)
    }

    // MARK: - Particle Generation

    private func generateNotificationParticles(for notification: ParticleNotification) {
        let screenSize = UIScreen.main.bounds
        let newParticles = (0..<50).map { _ in
            NotificationParticle(
                x: screenSize.width / 2,
                y: screenSize.height / 2,
                size: CGFloat.random(in: 2...8),
                color: notification.color,
                velocity: CGPoint(
                    x: CGFloat.random(in: -5...5),
                    y: CGFloat.random(in: -8...2)
                ),
                lifetime: Double.random(in: 2...4),
                opacity: Double.random(in: 0.6...1.0),
                shape: particleShapeForNotification(notification)
            )
        }

        particleField.append(contentsOf: newParticles)

        // Clean up old particles after they expire
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            cleanupOldParticles()
        }
    }

    private func generateNotificationLightBeams(for notification: ParticleNotification) {
        let screenSize = UIScreen.main.bounds
        let newBeams = (0..<6).map { index in
            NotificationLightBeam(
                angle: Double(index) * 60,
                color: notification.color,
                intensity: 0.6,
                width: 4,
                length: screenSize.height
            )
        }

        lightBeams.append(contentsOf: newBeams)

        // Remove beams after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                lightBeams.removeAll()
            }
        }
    }

    private func generateRippleEffect(for notification: ParticleNotification) {
        let screenSize = UIScreen.main.bounds
        let ripple = NotificationRippleEffect(
            x: screenSize.width / 2,
            y: screenSize.height / 2,
            color: notification.color,
            maxRadius: 300,
            duration: 2.0
        )

        rippleEffects.append(ripple)

        // Remove ripple after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let index = rippleEffects.firstIndex(where: { $0.id == ripple.id }) {
                rippleEffects.remove(at: index)
            }
        }
    }

    private func generateDismissalParticles(for notification: ParticleNotification) {
        let screenSize = UIScreen.main.bounds
        let dismissalParticles = (0..<20).map { _ in
            NotificationParticle(
                x: CGFloat.random(in: 0...screenSize.width),
                y: screenSize.height - 100,
                size: CGFloat.random(in: 3...10),
                color: notification.color,
                velocity: CGPoint(
                    x: CGFloat.random(in: -3...3),
                    y: CGFloat.random(in: -10...(-5))
                ),
                lifetime: Double.random(in: 1...2),
                opacity: Double.random(in: 0.4...0.8),
                shape: .circle
            )
        }

        particleField.append(contentsOf: dismissalParticles)
    }

    private func cleanupOldParticles() {
        // Keep only recent particles to avoid memory issues
        if particleField.count > 100 {
            particleField = Array(particleField.suffix(50))
        }
    }

    private func particleShapeForNotification(_ notification: ParticleNotification) -> NotificationParticle.ParticleShape {
        switch notification.type {
        case .prayer:
            return .star
        case .task:
            return .diamond
        case .achievement:
            return .hexagon
        case .reminder:
            return .circle
        }
    }
}

// MARK: - Particle Notification Model

struct ParticleNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let color: Color
    let importance: NotificationImportance
    let iconName: String
    let duration: TimeInterval
    let createdAt: Date

    enum NotificationType {
        case prayer, task, achievement, reminder
    }

    enum NotificationImportance {
        case low, medium, high, critical
    }
}

// MARK: - Particle Notification Card

struct ParticleNotificationCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let notification: ParticleNotification
    let phase: CGFloat
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var cardScale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: MZSpacing.sm) {
            // Header with icon and title
            HStack(spacing: MZSpacing.sm) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(notification.color.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .blur(radius: 10)

                    Image(systemName: notification.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(notification.color)
                }

                // Title and time
                VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                    Text(notification.title)
                        .font(MZTypography.titleMedium)
                        .foregroundColor(themeManager.textPrimaryColor)

                    Text(notification.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textSecondaryColor)
                }

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.textTertiaryColor)
                }
            }

            // Message
            Text(notification.message)
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Progress bar for time-based notifications
            if notification.duration > 0 {
                GeometryReader { geometry in
                    let elapsed = Date().timeIntervalSince(notification.createdAt)
                    let progress = min(max(elapsed / notification.duration, 0), 1)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(themeManager.surfaceSecondaryColor)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(notification.color)
                            .frame(width: geometry.size.width * CGFloat(1 - progress), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                        .stroke(notification.color.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: themeManager.backgroundColor.opacity(0.3), radius: 15, y: 8)
        )
        .scaleEffect(cardScale)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(MZAnimation.bouncy) {
                isVisible = true
                cardScale = 1.0
            }
        }
    }
}

// MARK: - Notification Particle View

struct NotificationParticleView: View {
    let particle: NotificationParticle
    let phase: CGFloat

    var body: some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)

            case .star:
                NotificationStarShape()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)

            case .diamond:
                NotificationDiamondShape()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)

            case .hexagon:
                NotificationHexagonShape()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            }
        }
        .position(
            x: particle.x + particle.velocity.x * phase * 60,
            y: particle.y + particle.velocity.y * phase * 60
        )
        .opacity(particle.opacity * max(0, 1.0 - phase / particle.lifetime))
        .rotationEffect(.degrees(Double(phase) * 180))
    }
}

// MARK: - Notification Light Beam View

struct NotificationBeamView: View {
    let beam: NotificationLightBeam
    let phase: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [beam.color.opacity(0), beam.color.opacity(beam.intensity), beam.color.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: beam.width)
            .frame(height: beam.length)
            .rotationEffect(.degrees(beam.angle))
            .opacity(0.3 + sin(Double(phase) * .pi * 4) * 0.2)
    }
}

// MARK: - Ripple Effect View

struct NotificationRippleView: View {
    let ripple: NotificationRippleEffect
    let phase: CGFloat

    @State private var rippleProgress: CGFloat = 0

    var body: some View {
        Circle()
            .stroke(ripple.color, lineWidth: 3)
            .frame(width: ripple.maxRadius * 2 * rippleProgress, height: ripple.maxRadius * 2 * rippleProgress)
            .position(x: ripple.x, y: ripple.y)
            .opacity(1.0 - rippleProgress)
            .onAppear {
                withAnimation(.easeOut(duration: ripple.duration)) {
                    rippleProgress = 1.0
                }
            }
    }
}

// MARK: - Custom Shapes

struct NotificationStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<5 {
            let angle = Double(i) * 2 * .pi / 5 - .pi / 2
            let nextAngle = Double(i + 1) * 2 * .pi / 5 - .pi / 2

            let innerPoint = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * 0.4,
                y: center.y + CGFloat(sin(angle)) * radius * 0.4
            )

            let outerPoint = CGPoint(
                x: center.x + CGFloat(cos((angle + nextAngle) / 2)) * radius,
                y: center.y + CGFloat(sin((angle + nextAngle) / 2)) * radius
            )

            if i == 0 {
                path.move(to: innerPoint)
            } else {
                path.addLine(to: innerPoint)
            }

            path.addLine(to: outerPoint)
        }

        path.closeSubpath()
        return path
    }
}

struct NotificationDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: center.x, y: center.y - height / 2))
        path.addLine(to: CGPoint(x: center.x + width / 2, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + height / 2))
        path.addLine(to: CGPoint(x: center.x - width / 2, y: center.y))
        path.closeSubpath()

        return path
    }
}

struct NotificationHexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
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
}

// MARK: - Data Models

struct NotificationParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let velocity: CGPoint
    let lifetime: Double
    let opacity: Double
    let shape: ParticleShape

    enum ParticleShape {
        case circle, star, diamond, hexagon
    }
}

struct NotificationLightBeam: Identifiable {
    let id = UUID()
    let angle: Double
    let color: Color
    var intensity: Double
    let width: CGFloat
    let length: CGFloat
}

struct NotificationRippleEffect: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let maxRadius: CGFloat
    let duration: Double
}

// MARK: - Notification Manager

class ParticleNotificationManager: ObservableObject {
    static let shared = ParticleNotificationManager()

    @Published var notifications: [ParticleNotification] = []

    func showPrayerNotification(prayer: PrayerTime, minutesUntil: Int) {
        let notification = ParticleNotification(
            type: .prayer,
            title: "\(prayer.displayName) قريباً",
            message: "تبقى \(minutesUntil) دقيقة على صلاة \(prayer.displayName)",
            color: Color(hex: prayer.colorHex),
            importance: minutesUntil <= 5 ? .high : .medium,
            iconName: prayer.prayerType.icon,
            duration: TimeInterval(minutesUntil * 60),
            createdAt: Date()
        )

        postNotification(notification)
    }

    func showTaskNotification(task: Task) {
        let notification = ParticleNotification(
            type: .task,
            title: "مهمة مجدولة",
            message: task.title,
            color: Color(hex: task.colorHex),
            importance: .medium,
            iconName: task.category.icon,
            duration: TimeInterval(task.duration * 60),
            createdAt: Date()
        )

        postNotification(notification)
    }

    func showAchievementNotification(achievement: String, color: Color) {
        let notification = ParticleNotification(
            type: .achievement,
            title: "إنجاز رائع!",
            message: achievement,
            color: color,
            importance: .high,
            iconName: "star.fill",
            duration: 5,
            createdAt: Date()
        )

        postNotification(notification)
    }

    func showReminderNotification(title: String, message: String, color: Color) {
        let notification = ParticleNotification(
            type: .reminder,
            title: title,
            message: message,
            color: color,
            importance: .medium,
            iconName: "bell.fill",
            duration: 10,
            createdAt: Date()
        )

        postNotification(notification)
    }

    private func postNotification(_ notification: ParticleNotification) {
        NotificationCenter.default.post(
            name: .init("ShowParticleNotification"),
            object: nil,
            userInfo: ["notification": notification]
        )
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.8).ignoresSafeArea()

        ParticleNotificationSystem()
            .environmentObject(ThemeManager())
            .onAppear {
                // Show sample notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let sampleNotification = ParticleNotification(
                        type: .prayer,
                        title: "المغرب قريباً",
                        message: "تبقى 10 دقائق على صلاة المغرب",
                        color: .orange,
                        importance: .high,
                        iconName: "sun.max.fill",
                        duration: 600,
                        createdAt: Date()
                    )

                    NotificationCenter.default.post(
                        name: .init("ShowParticleNotification"),
                        object: nil,
                        userInfo: ["notification": sampleNotification]
                    )
                }
            }
    }
}

//
//  LiquidLightEffect.swift
//  Mizan
//
//  Bioluminescent fluid dynamics for divine interactions.
//  Everything flows with liquid light.
//

import SwiftUI

// MARK: - Liquid Light Effect

struct LiquidLightEffect: View {
    @EnvironmentObject var themeManager: ThemeManager

    @Binding var touchPoint: CGPoint?
    @Binding var isDragging: Bool

    var color: Color?
    var intensity: Double = 1.0
    var showRipples: Bool = true
    var showTrail: Bool = true
    var showBlobs: Bool = true

    @State private var ripples: [LiquidRipple] = []
    @State private var trailPoints: [TrailPoint] = []
    @State private var blobs: [LiquidBlob] = []
    @State private var phase: Double = 0

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let effectColor = color ?? themeManager.primaryColor

                // Layer 1: Ambient blobs
                if showBlobs {
                    drawBlobs(context: context, size: size, color: effectColor)
                }

                // Layer 2: Touch ripples
                if showRipples {
                    drawRipples(context: context, color: effectColor)
                }

                // Layer 3: Drag trail
                if showTrail && trailPoints.count > 1 {
                    drawTrail(context: context, color: effectColor)
                }

                // Layer 4: Touch point glow
                if let point = touchPoint {
                    drawTouchGlow(context: context, at: point, color: effectColor)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: touchPoint) { oldValue, newValue in
            if let point = newValue {
                handleTouch(at: point)
            } else {
                // Touch ended - create final ripple
                if let lastPoint = trailPoints.last?.position {
                    createRipple(at: lastPoint, isEnd: true)
                }
                // Fade out trail
                withAnimation(.easeOut(duration: 0.5)) {
                    trailPoints.removeAll()
                }
            }
        }
        .onChange(of: isDragging) { _, newValue in
            if !newValue {
                // Clear trail when drag ends
                withAnimation(.easeOut(duration: 0.3)) {
                    trailPoints.removeAll()
                }
            }
        }
        .onAppear {
            generateAmbientBlobs()
            startAnimations()
        }
    }

    // MARK: - Drawing

    private func drawRipples(context: GraphicsContext, color: Color) {
        for ripple in ripples {
            let progress = ripple.progress
            let opacity = (1 - progress) * ripple.intensity * intensity
            let radius = ripple.maxRadius * progress

            // Outer ring
            var outerPath = Path()
            outerPath.addEllipse(in: CGRect(
                x: ripple.center.x - radius,
                y: ripple.center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))

            context.stroke(
                outerPath,
                with: .color(color.opacity(opacity * 0.8)),
                lineWidth: 2 * (1 - progress)
            )

            // Inner glow
            if progress < 0.5 {
                let innerRadius = radius * 0.5
                var innerPath = Path()
                innerPath.addEllipse(in: CGRect(
                    x: ripple.center.x - innerRadius,
                    y: ripple.center.y - innerRadius,
                    width: innerRadius * 2,
                    height: innerRadius * 2
                ))

                context.fill(
                    innerPath,
                    with: .color(color.opacity(opacity * 0.3 * (1 - progress * 2)))
                )
            }
        }
    }

    private func drawTrail(context: GraphicsContext, color: Color) {
        guard trailPoints.count > 1 else { return }

        var path = Path()
        path.move(to: trailPoints[0].position)

        for i in 1..<trailPoints.count {
            let point = trailPoints[i]
            let prevPoint = trailPoints[i - 1]

            // Smooth curve through points
            let midPoint = CGPoint(
                x: (prevPoint.position.x + point.position.x) / 2,
                y: (prevPoint.position.y + point.position.y) / 2
            )

            path.addQuadCurve(to: midPoint, control: prevPoint.position)
        }

        // Gradient stroke effect
        for i in stride(from: 0, to: trailPoints.count - 1, by: 1) {
            let progress = Double(i) / Double(trailPoints.count)
            let opacity = progress * intensity * 0.6
            let width = 4 + progress * 8

            var segmentPath = Path()
            segmentPath.move(to: trailPoints[i].position)
            if i + 1 < trailPoints.count {
                segmentPath.addLine(to: trailPoints[i + 1].position)
            }

            context.stroke(
                segmentPath,
                with: .color(color.opacity(opacity)),
                style: StrokeStyle(lineWidth: width, lineCap: .round)
            )
        }

        // Glow at end
        if let lastPoint = trailPoints.last?.position {
            let glowRadius: CGFloat = 20
            let gradient = Gradient(colors: [
                color.opacity(0.4 * intensity),
                color.opacity(0.1 * intensity),
                .clear
            ])

            context.drawLayer { ctx in
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: lastPoint.x - glowRadius,
                        y: lastPoint.y - glowRadius,
                        width: glowRadius * 2,
                        height: glowRadius * 2
                    )),
                    with: .radialGradient(
                        gradient,
                        center: lastPoint,
                        startRadius: 0,
                        endRadius: glowRadius
                    )
                )
            }
        }
    }

    private func drawTouchGlow(context: GraphicsContext, at point: CGPoint, color: Color) {
        let pulseScale = 1 + sin(phase * 8) * 0.2
        let baseRadius: CGFloat = 30 * pulseScale

        // Outer glow
        let gradient = Gradient(colors: [
            color.opacity(0.5 * intensity),
            color.opacity(0.2 * intensity),
            .clear
        ])

        context.fill(
            Path(ellipseIn: CGRect(
                x: point.x - baseRadius,
                y: point.y - baseRadius,
                width: baseRadius * 2,
                height: baseRadius * 2
            )),
            with: .radialGradient(
                gradient,
                center: point,
                startRadius: 0,
                endRadius: baseRadius
            )
        )

        // Inner bright core
        let coreRadius: CGFloat = 8
        context.fill(
            Path(ellipseIn: CGRect(
                x: point.x - coreRadius,
                y: point.y - coreRadius,
                width: coreRadius * 2,
                height: coreRadius * 2
            )),
            with: .color(color.opacity(0.8 * intensity))
        )
    }

    private func drawBlobs(context: GraphicsContext, size: CGSize, color: Color) {
        for blob in blobs {
            let x = blob.x * size.width + sin(phase * blob.speed + blob.phaseOffset) * 30
            let y = blob.y * size.height + cos(phase * blob.speed * 0.7 + blob.phaseOffset) * 20
            let scale = 1 + sin(phase * blob.speed * 2 + blob.phaseOffset) * 0.3

            let radius = blob.size * scale

            // Metaball-style blob
            let gradient = Gradient(colors: [
                color.opacity(blob.opacity * 0.4 * intensity),
                color.opacity(blob.opacity * 0.1 * intensity),
                .clear
            ])

            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - radius,
                    y: y - radius,
                    width: radius * 2,
                    height: radius * 2
                )),
                with: .radialGradient(
                    gradient,
                    center: CGPoint(x: x, y: y),
                    startRadius: 0,
                    endRadius: radius
                )
            )
        }
    }

    // MARK: - Interaction Handling

    private func handleTouch(at point: CGPoint) {
        // Create ripple on new touch
        if trailPoints.isEmpty {
            createRipple(at: point, isEnd: false)
        }

        // Add to trail
        let trailPoint = TrailPoint(position: point, timestamp: Date())
        trailPoints.append(trailPoint)

        // Limit trail length
        if trailPoints.count > 30 {
            trailPoints.removeFirst()
        }

        // Create small ripples along path
        if trailPoints.count % 5 == 0 {
            createRipple(at: point, isEnd: false, small: true)
        }
    }

    private func createRipple(at point: CGPoint, isEnd: Bool, small: Bool = false) {
        let ripple = LiquidRipple(
            center: point,
            maxRadius: small ? 40 : (isEnd ? 100 : 60),
            intensity: isEnd ? 1.0 : 0.6
        )

        ripples.append(ripple)

        // Animate ripple
        withAnimation(.easeOut(duration: small ? 0.5 : 0.8)) {
            if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                ripples[index].progress = 1.0
            }
        }

        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + (small ? 0.5 : 0.8)) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }

    // MARK: - Setup

    private func generateAmbientBlobs() {
        blobs = (0..<8).map { _ in
            LiquidBlob(
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...1),
                size: Double.random(in: 40...100),
                opacity: Double.random(in: 0.1...0.3),
                speed: Double.random(in: 0.3...1),
                phaseOffset: Double.random(in: 0...(.pi * 2))
            )
        }
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            phase = .pi * 2
        }
    }
}

// MARK: - Supporting Types

struct LiquidRipple: Identifiable {
    let id = UUID()
    let center: CGPoint
    let maxRadius: CGFloat
    var intensity: Double
    var progress: Double = 0
}

struct TrailPoint: Identifiable {
    let id = UUID()
    let position: CGPoint
    let timestamp: Date
}

struct LiquidBlob: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let size: Double
    let opacity: Double
    let speed: Double
    let phaseOffset: Double
}

// MARK: - Liquid Touch Modifier

struct LiquidTouchModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    @State private var touchPoint: CGPoint?
    @State private var isDragging: Bool = false

    var color: Color?
    var intensity: Double

    func body(content: Content) -> some View {
        content
            .overlay(
                LiquidLightEffect(
                    touchPoint: $touchPoint,
                    isDragging: $isDragging,
                    color: color,
                    intensity: intensity
                )
                .environmentObject(themeManager)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        touchPoint = value.location
                        isDragging = true
                    }
                    .onEnded { _ in
                        touchPoint = nil
                        isDragging = false
                    }
            )
    }
}

extension View {
    /// Adds liquid light touch effects to the view
    func liquidTouch(color: Color? = nil, intensity: Double = 1.0) -> some View {
        modifier(LiquidTouchModifier(color: color, intensity: intensity))
    }
}

// MARK: - Standalone Pulse Wave

struct PulseWave: View {
    @EnvironmentObject var themeManager: ThemeManager

    var center: CGPoint
    var color: Color?
    var maxRadius: CGFloat = 100
    var duration: Double = 1.0

    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .stroke(color ?? themeManager.primaryColor, lineWidth: 2)
            .frame(width: maxRadius * 2, height: maxRadius * 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(center)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    scale = 1
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    let themeManager = ThemeManager()
    ZStack {
        themeManager.overlayColor

        VStack {
            Text("Touch anywhere")
                .foregroundColor(themeManager.textOnPrimaryColor)
                .font(MZTypography.titleLarge)
        }
    }
    .liquidTouch()
    .environmentObject(themeManager)
}

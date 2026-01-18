//
//  SacredGeometryView.swift
//  Mizan
//
//  Infinitely tiling Islamic geometric patterns that breathe with divine rhythm.
//  Mathematical beauty meets spiritual depth.
//

import SwiftUI

// MARK: - Pattern Type

enum GeometricPatternType: CaseIterable {
    case octagram       // 8-point star
    case hexagonal      // 6-point tessellation
    case arabesque      // Flowing curves
    case muqarnas       // 3D honeycomb illusion

    var complexity: Int {
        switch self {
        case .octagram: return 8
        case .hexagonal: return 6
        case .arabesque: return 12
        case .muqarnas: return 10
        }
    }
}

// MARK: - Sacred Geometry View

struct SacredGeometryView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var patternType: GeometricPatternType = .octagram
    var opacity: Double = 0.1
    var lineWidth: Double = 0.5
    var animated: Bool = true
    var glowIntensity: Double = 0.3

    @State private var phase: Double = 0
    @State private var breatheScale: Double = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main pattern layer
                Canvas { context, size in
                    drawPattern(context: context, size: size)
                }

                // Glow layer at intersections
                if glowIntensity > 0 {
                    Canvas { context, size in
                        drawGlowPoints(context: context, size: size)
                    }
                    .blur(radius: 8)
                    .opacity(glowIntensity * (0.5 + sin(phase * 2) * 0.5))
                }
            }
            .rotationEffect(.degrees(animated ? phase * 6 : 0)) // Full rotation in 60s
            .scaleEffect(breatheScale)
        }
        .opacity(opacity)
        .onAppear {
            if animated {
                startAnimations()
            }
        }
    }

    // MARK: - Pattern Drawing

    private func drawPattern(context: GraphicsContext, size: CGSize) {
        switch patternType {
        case .octagram:
            drawOctagramTessellation(context: context, size: size)
        case .hexagonal:
            drawHexagonalTessellation(context: context, size: size)
        case .arabesque:
            drawArabesquePattern(context: context, size: size)
        case .muqarnas:
            drawMuqarnasPattern(context: context, size: size)
        }
    }

    // MARK: - Octagram (8-Point Star)

    private func drawOctagramTessellation(context: GraphicsContext, size: CGSize) {
        let cellSize: CGFloat = 100
        let cols = Int(size.width / cellSize) + 2
        let rows = Int(size.height / cellSize) + 2

        for row in -1..<rows {
            for col in -1..<cols {
                let center = CGPoint(
                    x: CGFloat(col) * cellSize + cellSize / 2,
                    y: CGFloat(row) * cellSize + cellSize / 2
                )
                drawOctagram(context: context, center: center, radius: cellSize * 0.45)
            }
        }
    }

    private func drawOctagram(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        var path = Path()
        let points = 8
        let innerRadius = radius * 0.4

        for i in 0..<points {
            let outerAngle = (Double(i) / Double(points)) * .pi * 2 - .pi / 2
            let innerAngle = outerAngle + .pi / Double(points)

            let outerPoint = CGPoint(
                x: center.x + CGFloat(cos(outerAngle)) * radius,
                y: center.y + CGFloat(sin(outerAngle)) * radius
            )

            let innerPoint = CGPoint(
                x: center.x + CGFloat(cos(innerAngle)) * innerRadius,
                y: center.y + CGFloat(sin(innerAngle)) * innerRadius
            )

            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }
            path.addLine(to: innerPoint)
        }
        path.closeSubpath()

        context.stroke(path, with: .color(themeManager.primaryColor), lineWidth: lineWidth)

        // Inner octagon
        var innerPath = Path()
        for i in 0..<points {
            let angle = (Double(i) / Double(points)) * .pi * 2 - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * innerRadius * 0.8,
                y: center.y + CGFloat(sin(angle)) * innerRadius * 0.8
            )
            if i == 0 {
                innerPath.move(to: point)
            } else {
                innerPath.addLine(to: point)
            }
        }
        innerPath.closeSubpath()
        context.stroke(innerPath, with: .color(themeManager.primaryColor.opacity(0.5)), lineWidth: lineWidth * 0.5)
    }

    // MARK: - Hexagonal (6-Point Star)

    private func drawHexagonalTessellation(context: GraphicsContext, size: CGSize) {
        let cellSize: CGFloat = 80
        let rowHeight = cellSize * 0.866 // sqrt(3)/2
        let cols = Int(size.width / cellSize) + 2
        let rows = Int(size.height / rowHeight) + 2

        for row in -1..<rows {
            for col in -1..<cols {
                let offset = (row % 2 == 0) ? 0 : cellSize / 2
                let center = CGPoint(
                    x: CGFloat(col) * cellSize + offset,
                    y: CGFloat(row) * rowHeight
                )
                drawHexStar(context: context, center: center, radius: cellSize * 0.4)
            }
        }
    }

    private func drawHexStar(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        var path = Path()
        let points = 6
        let innerRadius = radius * 0.5

        for i in 0..<points {
            let outerAngle = (Double(i) / Double(points)) * .pi * 2 - .pi / 2
            let innerAngle = outerAngle + .pi / Double(points)

            let outerPoint = CGPoint(
                x: center.x + CGFloat(cos(outerAngle)) * radius,
                y: center.y + CGFloat(sin(outerAngle)) * radius
            )

            let innerPoint = CGPoint(
                x: center.x + CGFloat(cos(innerAngle)) * innerRadius,
                y: center.y + CGFloat(sin(innerAngle)) * innerRadius
            )

            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }
            path.addLine(to: innerPoint)
        }
        path.closeSubpath()

        context.stroke(path, with: .color(themeManager.primaryColor), lineWidth: lineWidth)

        // Connecting lines to neighbors
        for i in 0..<points {
            let angle = (Double(i) / Double(points)) * .pi * 2 - .pi / 2
            var line = Path()
            line.move(to: CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            ))
            line.addLine(to: CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * 1.3,
                y: center.y + CGFloat(sin(angle)) * radius * 1.3
            ))
            context.stroke(line, with: .color(themeManager.primaryColor.opacity(0.3)), lineWidth: lineWidth * 0.5)
        }
    }

    // MARK: - Arabesque (Flowing Curves)

    private func drawArabesquePattern(context: GraphicsContext, size: CGSize) {
        let cellSize: CGFloat = 120
        let cols = Int(size.width / cellSize) + 2
        let rows = Int(size.height / cellSize) + 2

        for row in -1..<rows {
            for col in -1..<cols {
                let center = CGPoint(
                    x: CGFloat(col) * cellSize + cellSize / 2,
                    y: CGFloat(row) * cellSize + cellSize / 2
                )
                drawArabesqueCell(context: context, center: center, size: cellSize)
            }
        }
    }

    private func drawArabesqueCell(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        let radius = size * 0.4

        // Draw four interlocking curves
        for i in 0..<4 {
            let baseAngle = (Double(i) / 4.0) * .pi * 2

            var path = Path()

            let start = CGPoint(
                x: center.x + CGFloat(cos(baseAngle)) * radius,
                y: center.y + CGFloat(sin(baseAngle)) * radius
            )

            let end = CGPoint(
                x: center.x + CGFloat(cos(baseAngle + .pi / 2)) * radius,
                y: center.y + CGFloat(sin(baseAngle + .pi / 2)) * radius
            )

            let control1 = CGPoint(
                x: center.x + CGFloat(cos(baseAngle + .pi / 8)) * radius * 1.4,
                y: center.y + CGFloat(sin(baseAngle + .pi / 8)) * radius * 1.4
            )

            let control2 = CGPoint(
                x: center.x + CGFloat(cos(baseAngle + .pi / 2 - .pi / 8)) * radius * 1.4,
                y: center.y + CGFloat(sin(baseAngle + .pi / 2 - .pi / 8)) * radius * 1.4
            )

            path.move(to: start)
            path.addCurve(to: end, control1: control1, control2: control2)

            context.stroke(path, with: .color(themeManager.primaryColor), lineWidth: lineWidth)

            // Inner curve
            var innerPath = Path()
            let innerStart = CGPoint(
                x: center.x + CGFloat(cos(baseAngle)) * radius * 0.5,
                y: center.y + CGFloat(sin(baseAngle)) * radius * 0.5
            )
            let innerEnd = CGPoint(
                x: center.x + CGFloat(cos(baseAngle + .pi / 2)) * radius * 0.5,
                y: center.y + CGFloat(sin(baseAngle + .pi / 2)) * radius * 0.5
            )

            innerPath.move(to: innerStart)
            innerPath.addQuadCurve(to: innerEnd, control: center)

            context.stroke(innerPath, with: .color(themeManager.primaryColor.opacity(0.5)), lineWidth: lineWidth * 0.5)
        }

        // Center decoration
        var centerPath = Path()
        centerPath.addEllipse(in: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
        context.stroke(centerPath, with: .color(themeManager.primaryColor), lineWidth: lineWidth)
    }

    // MARK: - Muqarnas (3D Honeycomb)

    private func drawMuqarnasPattern(context: GraphicsContext, size: CGSize) {
        let cellSize: CGFloat = 60
        let cols = Int(size.width / cellSize) + 2
        let rows = Int(size.height / cellSize) + 2

        for row in -1..<rows {
            for col in -1..<cols {
                let offset = (row % 2 == 0) ? 0 : cellSize / 2
                let center = CGPoint(
                    x: CGFloat(col) * cellSize + offset,
                    y: CGFloat(row) * cellSize * 0.75
                )

                // Depth effect based on position
                let depth = (sin(Double(col) * 0.5 + phase) + 1) / 2
                drawMuqarnasCell(context: context, center: center, size: cellSize * 0.45, depth: depth)
            }
        }
    }

    private func drawMuqarnasCell(context: GraphicsContext, center: CGPoint, size: CGFloat, depth: Double) {
        // Hexagonal base
        var hexPath = Path()
        for i in 0..<6 {
            let angle = (Double(i) / 6.0) * .pi * 2 - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * size,
                y: center.y + CGFloat(sin(angle)) * size
            )
            if i == 0 {
                hexPath.move(to: point)
            } else {
                hexPath.addLine(to: point)
            }
        }
        hexPath.closeSubpath()

        context.stroke(hexPath, with: .color(themeManager.primaryColor.opacity(0.3 + depth * 0.3)), lineWidth: lineWidth)

        // 3D effect - lines from center
        for i in 0..<6 {
            let angle = (Double(i) / 6.0) * .pi * 2 - .pi / 2
            let innerSize = size * (0.3 + depth * 0.3)

            var line = Path()
            line.move(to: CGPoint(
                x: center.x + CGFloat(cos(angle)) * innerSize,
                y: center.y + CGFloat(sin(angle)) * innerSize
            ))
            line.addLine(to: CGPoint(
                x: center.x + CGFloat(cos(angle)) * size,
                y: center.y + CGFloat(sin(angle)) * size
            ))
            context.stroke(line, with: .color(themeManager.primaryColor.opacity(0.2 + depth * 0.4)), lineWidth: lineWidth * 0.5)
        }

        // Inner hexagon
        var innerHex = Path()
        let innerSize = size * (0.3 + depth * 0.3)
        for i in 0..<6 {
            let angle = (Double(i) / 6.0) * .pi * 2 - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * innerSize,
                y: center.y + CGFloat(sin(angle)) * innerSize
            )
            if i == 0 {
                innerHex.move(to: point)
            } else {
                innerHex.addLine(to: point)
            }
        }
        innerHex.closeSubpath()
        context.stroke(innerHex, with: .color(themeManager.primaryColor.opacity(0.5 + depth * 0.5)), lineWidth: lineWidth)
    }

    // MARK: - Glow Points

    private func drawGlowPoints(context: GraphicsContext, size: CGSize) {
        let cellSize: CGFloat = 100
        let cols = Int(size.width / cellSize) + 2
        let rows = Int(size.height / cellSize) + 2

        for row in 0..<rows {
            for col in 0..<cols {
                let center = CGPoint(
                    x: CGFloat(col) * cellSize + cellSize / 2,
                    y: CGFloat(row) * cellSize + cellSize / 2
                )

                var circle = Path()
                circle.addEllipse(in: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8))
                context.fill(circle, with: .color(themeManager.primaryColor))
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Rotation phase
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            phase = .pi * 2
        }

        // Breathing scale
        withAnimation(MZAnimation.breathe) {
            breatheScale = 1.02
        }
    }
}

// MARK: - Animated Pattern Modifier

struct AnimatedGeometryBackground: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    var patternType: GeometricPatternType
    var opacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                SacredGeometryView(
                    patternType: patternType,
                    opacity: opacity,
                    lineWidth: 0.5,
                    animated: true,
                    glowIntensity: 0.2
                )
                .environmentObject(themeManager)
            )
    }
}

extension View {
    func sacredGeometryBackground(
        pattern: GeometricPatternType = .octagram,
        opacity: Double = 0.1
    ) -> some View {
        modifier(AnimatedGeometryBackground(patternType: pattern, opacity: opacity))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var themeManager = ThemeManager()

    TabView {
        ZStack {
            themeManager.backgroundColor
            SacredGeometryView(patternType: .octagram, opacity: 0.3)
        }
        .tabItem { Text("Octagram") }

        ZStack {
            themeManager.backgroundColor
            SacredGeometryView(patternType: .hexagonal, opacity: 0.4, glowIntensity: 0.5)
        }
        .tabItem { Text("Hexagonal") }

        ZStack {
            themeManager.backgroundColor
            SacredGeometryView(patternType: .arabesque, opacity: 0.3)
        }
        .tabItem { Text("Arabesque") }

        ZStack {
            themeManager.backgroundColor
            SacredGeometryView(patternType: .muqarnas, opacity: 0.5)
        }
        .tabItem { Text("Muqarnas") }
    }
    .environmentObject(themeManager)
}

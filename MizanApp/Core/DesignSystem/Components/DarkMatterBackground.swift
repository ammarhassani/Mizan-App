//
//  DarkMatterBackground.swift
//  MizanApp
//
//  SwiftUI component wrapping MetalView for Dark Matter shader rendering.
//  Provides Metal resource management, touch gestures, and animation timing.
//  Falls back to gradient when Metal is unavailable or reduced motion is enabled.
//

import SwiftUI
import MetalKit
import UIKit

// MARK: - MetalResources

/// Manages Metal resources for DarkMatter shader rendering.
/// Use the async factory method `create()` to safely initialize Metal resources.
final class MetalResources {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let computePipeline: MTLComputePipelineState
    let renderPipeline: MTLRenderPipelineState

    private init(
        device: MTLDevice,
        commandQueue: MTLCommandQueue,
        computePipeline: MTLComputePipelineState,
        renderPipeline: MTLRenderPipelineState
    ) {
        self.device = device
        self.commandQueue = commandQueue
        self.computePipeline = computePipeline
        self.renderPipeline = renderPipeline
    }

    /// Creates MetalResources asynchronously.
    /// Returns nil if Metal is unavailable or shader compilation fails.
    static func create() async -> MetalResources? {
        // Create Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }

        // Create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        // Load the default library (contains our shaders)
        guard let library = device.makeDefaultLibrary() else {
            return nil
        }

        // Create compute pipeline for darkMatterKernel
        guard let computeFunction = library.makeFunction(name: "darkMatterKernel") else {
            return nil
        }

        let computePipeline: MTLComputePipelineState
        do {
            computePipeline = try await device.makeComputePipelineState(function: computeFunction)
        } catch {
            return nil
        }

        // Create render pipeline for vertex/fragment shaders
        guard let vertexFunction = library.makeFunction(name: "darkMatterVertex"),
              let fragmentFunction = library.makeFunction(name: "darkMatterFragment") else {
            return nil
        }

        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexFunction = vertexFunction
        renderDescriptor.fragmentFunction = fragmentFunction
        renderDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        let renderPipeline: MTLRenderPipelineState
        do {
            renderPipeline = try await device.makeRenderPipelineState(descriptor: renderDescriptor)
        } catch {
            return nil
        }

        return MetalResources(
            device: device,
            commandQueue: commandQueue,
            computePipeline: computePipeline,
            renderPipeline: renderPipeline
        )
    }
}

// MARK: - DarkMatterBackground

/// Dark Matter background view with Metal shader rendering.
/// Displays an animated fluid simulation that responds to touch and scroll.
/// Automatically falls back to a static gradient when Metal is unavailable
/// or when the user has enabled Reduce Motion accessibility setting.
struct DarkMatterBackground: View {
    // MARK: - Environment

    @Environment(\.deviceCapabilities) private var capabilities

    // MARK: - Input Properties

    /// The current prayer period (0-5: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
    let prayerPeriod: Int

    // MARK: - State

    @State private var metalResources: MetalResources?
    @State private var time: Float = 0
    @State private var touchPosition: SIMD2<Float> = SIMD2(0.5, 0.5)
    @State private var touchIntensity: Float = 0
    @State private var scrollVelocity: Float = 0
    @State private var displayLink: CADisplayLink?
    @State private var isMetalInitialized = false
    @State private var useReducedMotion = false

    // MARK: - Body

    var body: some View {
        ZStack {
            if useReducedMotion || metalResources == nil {
                // Fallback gradient for reduced motion or Metal unavailable
                fallbackGradient
            } else {
                // Metal shader view with touch gestures
                metalShaderView
            }
        }
        .ignoresSafeArea()
        .onAppear {
            checkReducedMotion()
            if !useReducedMotion {
                initializeMetalAsync()
            }
        }
        .onDisappear {
            stopDisplayLink()
        }
    }

    // MARK: - Metal Shader View

    @ViewBuilder
    private var metalShaderView: some View {
        if let resources = metalResources {
            MetalView(
                device: resources.device,
                commandQueue: resources.commandQueue,
                computePipeline: resources.computePipeline,
                renderPipeline: resources.renderPipeline,
                time: $time,
                touchPosition: $touchPosition,
                touchIntensity: $touchIntensity,
                scrollVelocity: $scrollVelocity,
                prayerPeriod: .constant(prayerPeriod),
                density: densityForCapabilities,
                noiseOctaves: capabilities.noiseOctaves
            )
            .gesture(touchGesture)
        }
    }

    // MARK: - Touch Gesture

    private var touchGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if capabilities.enableShaderInteraction {
                    handleTouchChanged(value)
                }
            }
            .onEnded { _ in
                if capabilities.enableShaderInteraction {
                    handleTouchEnded()
                }
            }
    }

    private func handleTouchChanged(_ value: DragGesture.Value) {
        guard capabilities.enableShaderInteraction else { return }

        // Get the view size from the gesture location context
        // Normalize position to 0-1 range
        let screenBounds = UIScreen.main.bounds
        let normalizedX = Float(value.location.x / screenBounds.width)
        let normalizedY = Float(value.location.y / screenBounds.height)

        touchPosition = SIMD2(
            min(max(normalizedX, 0), 1),
            min(max(normalizedY, 0), 1)
        )
        touchIntensity = 1.0
    }

    private func handleTouchEnded() {
        // Animate touch intensity fade out
        withAnimation(.easeOut(duration: 0.5)) {
            touchIntensity = 0
        }
    }

    // MARK: - Fallback Gradient

    private var fallbackGradient: some View {
        LinearGradient(
            colors: gradientColorsForPeriod(prayerPeriod),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Returns gradient colors based on prayer period
    private func gradientColorsForPeriod(_ period: Int) -> [Color] {
        switch period {
        case 0: // Fajr
            return [
                CinematicColors.periodFajr,
                CinematicColors.voidBlack
            ]
        case 1: // Sunrise
            return [
                CinematicColors.periodSunrise,
                CinematicColors.voidBlack
            ]
        case 2: // Dhuhr
            return [
                CinematicColors.periodDhuhr,
                CinematicColors.voidBlack
            ]
        case 3: // Asr
            return [
                CinematicColors.periodAsr,
                CinematicColors.voidBlack
            ]
        case 4: // Maghrib
            return [
                CinematicColors.periodMaghrib,
                CinematicColors.voidBlack
            ]
        case 5: // Isha
            return [
                CinematicColors.periodIsha,
                CinematicColors.voidBlack
            ]
        default:
            return [
                CinematicColors.darkMatter,
                CinematicColors.voidBlack
            ]
        }
    }

    // MARK: - Computed Properties

    private var densityForCapabilities: Float {
        switch capabilities.tier {
        case .high:
            return 1.0
        case .medium:
            return 0.8
        case .low:
            return 0.6
        }
    }

    // MARK: - Metal Initialization

    private func checkReducedMotion() {
        useReducedMotion = UIAccessibility.isReduceMotionEnabled
    }

    private func initializeMetalAsync() {
        _Concurrency.Task {
            let resources = await MetalResources.create()
            await MainActor.run {
                self.metalResources = resources
                self.isMetalInitialized = resources != nil
                if resources != nil {
                    startDisplayLink()
                }
            }
        }
    }

    // MARK: - Display Link (Animation Timer)

    private func startDisplayLink() {
        guard displayLink == nil else { return }

        let link = CADisplayLink(target: DisplayLinkTarget { [self] in
            self.updateAnimation()
        }, selector: #selector(DisplayLinkTarget.update))

        link.preferredFrameRateRange = CAFrameRateRange(
            minimum: Float(capabilities.targetFrameRate / 2),
            maximum: Float(capabilities.targetFrameRate),
            preferred: Float(capabilities.targetFrameRate)
        )

        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func updateAnimation() {
        // Increment time for shader animation
        let deltaTime: Float = 1.0 / Float(capabilities.targetFrameRate)
        time += deltaTime

        // Gradually fade touch intensity if not touching
        if touchIntensity > 0 {
            touchIntensity = max(0, touchIntensity - deltaTime * 2)
        }

        // Decay scroll velocity
        if scrollVelocity != 0 {
            scrollVelocity *= 0.95
            if abs(scrollVelocity) < 0.01 {
                scrollVelocity = 0
            }
        }
    }

    // MARK: - Scroll Velocity Update

    /// Call this method to update scroll velocity from a parent ScrollView
    func updateScrollVelocity(_ velocity: Float) {
        scrollVelocity = velocity
    }
}

// MARK: - DisplayLinkTarget

/// Helper class to bridge CADisplayLink callback to Swift closure.
private final class DisplayLinkTarget {
    private let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    @objc func update() {
        callback()
    }
}

// MARK: - View Modifier

/// View modifier for easily applying DarkMatterBackground to any view
struct DarkMatterBackgroundModifier: ViewModifier {
    let prayerPeriod: Int

    func body(content: Content) -> some View {
        ZStack {
            DarkMatterBackground(prayerPeriod: prayerPeriod)
            content
        }
    }
}

extension View {
    /// Applies the DarkMatterBackground as a background layer.
    /// - Parameter prayerPeriod: The current prayer period (0-5)
    /// - Returns: A view with the DarkMatter background applied
    func darkMatterBackground(prayerPeriod: Int) -> some View {
        modifier(DarkMatterBackgroundModifier(prayerPeriod: prayerPeriod))
    }
}

// MARK: - Preview

#if DEBUG
struct DarkMatterBackground_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DarkMatterBackground(prayerPeriod: 0)
                .previewDisplayName("Fajr")

            DarkMatterBackground(prayerPeriod: 4)
                .previewDisplayName("Maghrib")

            DarkMatterBackground(prayerPeriod: 5)
                .previewDisplayName("Isha")

            // Preview with content using modifier
            Text("Hello, Dark Matter")
                .font(.largeTitle)
                .foregroundColor(CinematicColors.textPrimary)
                .darkMatterBackground(prayerPeriod: 5)
                .previewDisplayName("With Modifier")
        }
    }
}
#endif

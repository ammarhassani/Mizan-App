//
//  MetalView.swift
//  MizanApp
//
//  UIViewRepresentable wrapper for Metal shader rendering.
//  Bridges the DarkMatter Metal shader to SwiftUI for the Event Horizon UI.
//

import SwiftUI
import MetalKit

// MARK: - DarkMatterUniforms

/// Swift representation of the DarkMatterUniforms struct from DarkMatterShader.metal.
/// IMPORTANT: This struct layout MUST match the Metal shader exactly for proper data passing.
struct DarkMatterUniforms {
    var time: Float
    var resolution: SIMD2<Float>
    var touchPosition: SIMD2<Float>
    var touchIntensity: Float
    var scrollVelocity: Float
    var prayerPeriod: Int32
    var density: Float
    var noiseOctaves: Int32
}

// MARK: - MetalView

/// SwiftUI wrapper for Metal shader rendering using UIViewRepresentable.
/// Renders the DarkMatter fluid simulation shader with touch and scroll interaction.
struct MetalView: UIViewRepresentable {

    // MARK: - Metal Resources

    let device: MTLDevice?
    let commandQueue: MTLCommandQueue?
    let computePipeline: MTLComputePipelineState?
    let renderPipeline: MTLRenderPipelineState?

    // MARK: - Dynamic Properties (Bindings)

    @Binding var time: Float
    @Binding var touchPosition: SIMD2<Float>
    @Binding var touchIntensity: Float
    @Binding var scrollVelocity: Float
    @Binding var prayerPeriod: Int

    // MARK: - Static Properties

    let density: Float
    let noiseOctaves: Int

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0)
        mtkView.preferredFramesPerSecond = DeviceCapabilities.current.targetFrameRate
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.colorPixelFormat = .bgra8Unorm
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Pass updated values to the coordinator for the next draw cycle
        context.coordinator.time = time
        context.coordinator.touchPosition = touchPosition
        context.coordinator.touchIntensity = touchIntensity
        context.coordinator.scrollVelocity = scrollVelocity
        context.coordinator.prayerPeriod = prayerPeriod
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            device: device,
            commandQueue: commandQueue,
            computePipeline: computePipeline,
            renderPipeline: renderPipeline,
            density: density,
            noiseOctaves: noiseOctaves
        )
    }

    // MARK: - Coordinator

    /// Coordinator class that conforms to MTKViewDelegate for handling Metal rendering.
    class Coordinator: NSObject, MTKViewDelegate {

        // MARK: - Metal Resources

        let device: MTLDevice?
        let commandQueue: MTLCommandQueue?
        let computePipeline: MTLComputePipelineState?
        let renderPipeline: MTLRenderPipelineState?

        // MARK: - Dynamic Properties

        var time: Float = 0
        var touchPosition: SIMD2<Float> = SIMD2(0.5, 0.5)
        var touchIntensity: Float = 0
        var scrollVelocity: Float = 0
        var prayerPeriod: Int = 5  // Default to Isha

        // MARK: - Static Properties

        let density: Float
        let noiseOctaves: Int

        // MARK: - Private State

        private var outputTexture: MTLTexture?
        private var samplerState: MTLSamplerState?

        // MARK: - Initialization

        init(
            device: MTLDevice?,
            commandQueue: MTLCommandQueue?,
            computePipeline: MTLComputePipelineState?,
            renderPipeline: MTLRenderPipelineState?,
            density: Float,
            noiseOctaves: Int
        ) {
            self.device = device
            self.commandQueue = commandQueue
            self.computePipeline = computePipeline
            self.renderPipeline = renderPipeline
            self.density = density
            self.noiseOctaves = noiseOctaves
            super.init()

            // Create sampler state for texture sampling in the fragment shader
            if let device = device {
                let samplerDescriptor = MTLSamplerDescriptor()
                samplerDescriptor.minFilter = .linear
                samplerDescriptor.magFilter = .linear
                samplerDescriptor.sAddressMode = .clampToEdge
                samplerDescriptor.tAddressMode = .clampToEdge
                self.samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
            }
        }

        // MARK: - MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Recreate output texture when the drawable size changes
            createOutputTexture(size: size)
        }

        func draw(in view: MTKView) {
            // Validate all required resources are available
            guard let device = device,
                  let commandQueue = commandQueue,
                  let computePipeline = computePipeline,
                  let renderPipeline = renderPipeline,
                  let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor else {
                return
            }

            let drawableSize = view.drawableSize

            // Ensure output texture exists and matches current size
            // Use DeviceCapabilities.current.shaderResolutionScale for scaled rendering
            let scale = CGFloat(DeviceCapabilities.current.shaderResolutionScale)
            let scaledWidth = Int(drawableSize.width * scale)
            let scaledHeight = Int(drawableSize.height * scale)

            if outputTexture == nil ||
               outputTexture?.width != scaledWidth ||
               outputTexture?.height != scaledHeight {
                createOutputTexture(size: drawableSize)
            }

            guard let outputTexture = outputTexture,
                  let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }

            // MARK: Compute Pass - Run the DarkMatter shader

            if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
                computeEncoder.setComputePipelineState(computePipeline)
                computeEncoder.setTexture(outputTexture, index: 0)

                // Create uniforms matching the Metal shader struct
                var uniforms = DarkMatterUniforms(
                    time: time,
                    resolution: SIMD2<Float>(Float(outputTexture.width), Float(outputTexture.height)),
                    touchPosition: touchPosition,
                    touchIntensity: touchIntensity,
                    scrollVelocity: scrollVelocity,
                    prayerPeriod: Int32(prayerPeriod),
                    density: density,
                    noiseOctaves: Int32(noiseOctaves)
                )
                computeEncoder.setBytes(&uniforms, length: MemoryLayout<DarkMatterUniforms>.stride, index: 0)

                // Calculate thread groups for dispatch
                let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
                let threadGroups = MTLSize(
                    width: (outputTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
                    height: (outputTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
                    depth: 1
                )

                computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
                computeEncoder.endEncoding()
            }

            // MARK: Render Pass - Draw the computed texture to screen

            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.setRenderPipelineState(renderPipeline)
                renderEncoder.setFragmentTexture(outputTexture, index: 0)

                if let samplerState = samplerState {
                    renderEncoder.setFragmentSamplerState(samplerState, index: 0)
                }

                // Draw a full-screen quad using 4 vertices as a triangle strip
                // The vertex shader generates the quad positions procedurally
                renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
                renderEncoder.endEncoding()
            }

            // Present and commit
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        // MARK: - Private Methods

        /// Creates or recreates the output texture at the specified size, scaled by device capabilities.
        private func createOutputTexture(size: CGSize) {
            guard let device = device else { return }

            let scale = DeviceCapabilities.current.shaderResolutionScale
            let scaledWidth = Int(size.width * CGFloat(scale))
            let scaledHeight = Int(size.height * CGFloat(scale))

            // Ensure minimum dimensions
            let width = max(scaledWidth, 1)
            let height = max(scaledHeight, 1)

            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm,
                width: width,
                height: height,
                mipmapped: false
            )
            descriptor.usage = [.shaderRead, .shaderWrite]
            descriptor.storageMode = .private

            outputTexture = device.makeTexture(descriptor: descriptor)
        }
    }
}

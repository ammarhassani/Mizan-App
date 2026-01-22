# Event Horizon Phase 2: Visual Foundation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create the visual infrastructure for the Dark Matter theme - Metal shaders, animated background, particle system, and device tier detection.

**Architecture:** Real-time Metal shader for fluid simulation with touch/scroll interaction, SwiftUI wrapper for integration, performance tiers based on device capability, and particle system for ambient effects.

**Tech Stack:** Metal Shading Language, SwiftUI, Core Animation, UIKit (for MetalView bridging)

---

## Pre-Implementation Checklist

- [x] Phase 1 Foundation complete
- [x] Build passing
- [x] Tests passing (49/50)

---

## Task 1: Create Device Tier Detection

**Files:**
- Create: `MizanApp/Core/DesignSystem/Performance/DeviceTier.swift`
- Test: Build verification

### Step 1: Create the device tier utility

Create directory first:
```bash
mkdir -p MizanApp/Core/DesignSystem/Performance
```

Create `MizanApp/Core/DesignSystem/Performance/DeviceTier.swift`:

```swift
//
//  DeviceTier.swift
//  Mizan
//
//  Device performance tier detection for shader quality scaling
//

import UIKit

/// Device performance tier for visual effect scaling
enum DeviceTier: Int, Comparable {
    /// Low tier (A11 and older): reduced effects
    case low = 0
    /// Medium tier (A12-A13): balanced effects
    case medium = 1
    /// High tier (A14+): full effects
    case high = 2

    static func < (lhs: DeviceTier, rhs: DeviceTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Device capabilities and performance tier detection
struct DeviceCapabilities {
    /// Singleton for easy access
    static let current = DeviceCapabilities()

    /// Detected performance tier
    let tier: DeviceTier

    /// Target frame rate based on tier
    var targetFrameRate: Int {
        switch tier {
        case .high: return 60
        case .medium: return 60
        case .low: return 30
        }
    }

    /// Shader resolution scale (1.0 = full resolution)
    var shaderResolutionScale: Float {
        switch tier {
        case .high: return 1.0
        case .medium: return 0.75
        case .low: return 0.5
        }
    }

    /// Maximum particle count
    var maxParticles: Int {
        switch tier {
        case .high: return 200
        case .medium: return 100
        case .low: return 50
        }
    }

    /// Noise octaves for shader complexity
    var noiseOctaves: Int {
        switch tier {
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        }
    }

    /// Whether to enable touch interactions on shader
    var enableShaderInteraction: Bool {
        tier >= .medium
    }

    /// Whether to enable particle system
    var enableParticles: Bool {
        tier >= .low
    }

    /// Whether to enable glass blur effects
    var enableGlassBlur: Bool {
        tier >= .medium
    }

    private init() {
        tier = DeviceCapabilities.detectTier()
    }

    /// Detect device tier based on processor
    private static func detectTier() -> DeviceTier {
        // Check for reduced motion preference first
        if UIAccessibility.isReduceMotionEnabled {
            return .low
        }

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        // Parse device identifier to determine chip generation
        // iPhone identifiers: iPhone{major},{minor}
        // iPad identifiers: iPad{major},{minor}

        if identifier.hasPrefix("iPhone") {
            let numbers = identifier.dropFirst(6).split(separator: ",")
            if let major = numbers.first, let majorNum = Int(major) {
                // iPhone 12 and later (A14+): iPhone13,x and above
                if majorNum >= 14 { return .high }  // iPhone 13+ (A15+)
                if majorNum >= 13 { return .high }  // iPhone 12 (A14)
                // iPhone XS/XR/11 (A12-A13): iPhone11,x - iPhone12,x
                if majorNum >= 11 { return .medium }
                // iPhone X and older (A11-): iPhone10,x and below
                return .low
            }
        }

        if identifier.hasPrefix("iPad") {
            let numbers = identifier.dropFirst(4).split(separator: ",")
            if let major = numbers.first, let majorNum = Int(major) {
                // iPad Pro M1/M2 and newer: iPad13,x and above
                if majorNum >= 13 { return .high }
                // iPad with A12/A13/A14: iPad11,x - iPad12,x
                if majorNum >= 11 { return .medium }
                return .low
            }
        }

        // Simulator or unknown device - default to high for development
        #if targetEnvironment(simulator)
        return .high
        #else
        return .medium
        #endif
    }
}

// MARK: - SwiftUI Environment Key

import SwiftUI

private struct DeviceCapabilitiesKey: EnvironmentKey {
    static let defaultValue = DeviceCapabilities.current
}

extension EnvironmentValues {
    var deviceCapabilities: DeviceCapabilities {
        get { self[DeviceCapabilitiesKey.self] }
        set { self[DeviceCapabilitiesKey.self] = newValue }
    }
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Performance/
git commit -m "feat(performance): add DeviceTier for visual effect scaling

Device capability detection for Event Horizon:
- Three tiers: low (A11-), medium (A12-13), high (A14+)
- Shader resolution scaling per tier
- Particle count limits
- Frame rate targets
- SwiftUI environment key for easy access

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Create DarkMatterShader.metal

**Files:**
- Create: `MizanApp/Core/DesignSystem/Shaders/DarkMatterShader.metal`
- Test: Build verification

### Step 1: Create the Metal shader directory and file

Create directory first:
```bash
mkdir -p MizanApp/Core/DesignSystem/Shaders
```

Create `MizanApp/Core/DesignSystem/Shaders/DarkMatterShader.metal`:

```metal
//
//  DarkMatterShader.metal
//  Mizan
//
//  Real-time fluid simulation for Dark Matter background
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Uniforms

struct DarkMatterUniforms {
    float time;
    float2 resolution;
    float2 touchPosition;
    float touchIntensity;
    float scrollVelocity;
    int prayerPeriod;  // 0-5: fajr, sunrise, dhuhr, asr, maghrib, isha
    float density;
    int noiseOctaves;
};

// MARK: - Helper Functions

// Simplex noise permutation
constant int perm[512] = {
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
    190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,
    20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,
    230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,
    169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,
    147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,
    2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,
    112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,
    107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,
    222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
    190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,
    20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,
    230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,
    169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,
    147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,
    2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,
    112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,
    107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,
    222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
};

// Simplex 3D noise
float simplex3D(float3 v) {
    const float F3 = 0.3333333;
    const float G3 = 0.1666667;

    float3 s = floor(v + dot(v, float3(F3)));
    float3 x = v - s + dot(s, float3(G3));

    float3 e = step(float3(0.0), x - x.yzx);
    float3 i1 = e * (1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy * (1.0 - e);

    float3 x1 = x - i1 + G3;
    float3 x2 = x - i2 + 2.0 * G3;
    float3 x3 = x - 1.0 + 3.0 * G3;

    float4 w, d;
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);

    w = max(0.6 - w, 0.0);

    d.x = dot(fract(sin(float3(dot(s, float3(1.0, 57.0, 113.0)))) * 43758.5453) * 2.0 - 1.0, x);
    d.y = dot(fract(sin(float3(dot(s + i1, float3(1.0, 57.0, 113.0)))) * 43758.5453) * 2.0 - 1.0, x1);
    d.z = dot(fract(sin(float3(dot(s + i2, float3(1.0, 57.0, 113.0)))) * 43758.5453) * 2.0 - 1.0, x2);
    d.w = dot(fract(sin(float3(dot(s + 1.0, float3(1.0, 57.0, 113.0)))) * 43758.5453) * 2.0 - 1.0, x3);

    w = w * w * w * w;
    d = d * w;

    return dot(d, float4(52.0));
}

// Fractal Brownian Motion
float fbm(float3 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < octaves && i < 4; i++) {
        value += amplitude * simplex3D(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value;
}

// Curl noise for fluid-like motion
float3 curlNoise(float3 p) {
    const float e = 0.0001;
    float3 dx = float3(e, 0.0, 0.0);
    float3 dy = float3(0.0, e, 0.0);
    float3 dz = float3(0.0, 0.0, e);

    float px = simplex3D(p + dy) - simplex3D(p - dy);
    float py = simplex3D(p + dz) - simplex3D(p - dz);
    float pz = simplex3D(p + dx) - simplex3D(p - dx);

    px -= simplex3D(p + dz) - simplex3D(p - dz);
    py -= simplex3D(p + dx) - simplex3D(p - dx);
    pz -= simplex3D(p + dy) - simplex3D(p - dy);

    return float3(px, py, pz) / (2.0 * e);
}

// Prayer period color temperature
float3 prayerColor(int period, float intensity) {
    // Base colors for each prayer period
    float3 colors[6] = {
        float3(0.10, 0.15, 0.35),  // Fajr: deep blue with gold hints
        float3(0.35, 0.25, 0.15),  // Sunrise: warm gold
        float3(0.30, 0.22, 0.12),  // Dhuhr: amber
        float3(0.28, 0.18, 0.10),  // Asr: copper bronze
        float3(0.25, 0.10, 0.20),  // Maghrib: deep red purple
        float3(0.05, 0.05, 0.15)   // Isha: deep void blue
    };

    int idx = clamp(period, 0, 5);
    return mix(float3(0.02, 0.02, 0.03), colors[idx], intensity);
}

// MARK: - Main Shader

[[kernel]]
void darkMatterKernel(
    texture2d<float, access::write> output [[texture(0)]],
    constant DarkMatterUniforms& uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Early exit for out of bounds
    if (gid.x >= uint(uniforms.resolution.x) || gid.y >= uint(uniforms.resolution.y)) {
        return;
    }

    // Normalized coordinates
    float2 uv = float2(gid) / uniforms.resolution;
    float2 centered = uv - 0.5;

    // Time with scroll velocity modulation (time dilation effect)
    float timeScale = 1.0 + uniforms.scrollVelocity * 2.0;
    float t = uniforms.time * 0.1 * timeScale;

    // Base fluid position
    float3 pos = float3(centered * 2.0, t);

    // Apply curl noise for fluid motion
    float3 curl = curlNoise(pos * 0.5) * 0.3;
    pos += curl;

    // Touch interaction - gravitational well
    if (uniforms.touchIntensity > 0.01) {
        float2 touchOffset = (uv - uniforms.touchPosition);
        float touchDist = length(touchOffset);
        float gravitationalPull = uniforms.touchIntensity * 0.5 / (touchDist + 0.1);
        pos.xy -= normalize(touchOffset) * gravitationalPull * 0.2;
    }

    // Layer multiple FBM samples for depth
    float noise1 = fbm(pos, uniforms.noiseOctaves);
    float noise2 = fbm(pos * 1.5 + float3(100.0, 0.0, t * 0.5), max(uniforms.noiseOctaves - 1, 1));
    float noise3 = fbm(pos * 0.7 - float3(0.0, 50.0, t * 0.3), max(uniforms.noiseOctaves - 2, 1));

    // Combine noise layers
    float combinedNoise = noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2;
    combinedNoise = combinedNoise * 0.5 + 0.5; // Remap to 0-1

    // Apply density
    combinedNoise = pow(combinedNoise, 1.0 / uniforms.density);

    // Get prayer period color
    float3 periodColor = prayerColor(uniforms.prayerPeriod, combinedNoise * 0.6);

    // Add subtle cyan accent highlights
    float highlight = pow(combinedNoise, 3.0);
    float3 accentCyan = float3(0.50, 0.86, 1.0);

    // Combine colors
    float3 finalColor = periodColor;
    finalColor += accentCyan * highlight * 0.15;

    // Add subtle vignette
    float vignette = 1.0 - length(centered) * 0.5;
    finalColor *= vignette;

    // Touch glow effect
    if (uniforms.touchIntensity > 0.01) {
        float2 touchOffset = uv - uniforms.touchPosition;
        float touchDist = length(touchOffset);
        float glow = uniforms.touchIntensity * exp(-touchDist * 8.0);
        finalColor += accentCyan * glow * 0.3;
    }

    // Output with full alpha
    output.write(float4(finalColor, 1.0), gid);
}

// MARK: - Vertex Shader for Full-Screen Quad

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut darkMatterVertex(
    uint vertexID [[vertex_id]]
) {
    // Full-screen quad vertices
    float2 positions[6] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0)
    };

    float2 texCoords[6] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(0.0, 0.0),
        float2(1.0, 1.0),
        float2(1.0, 0.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = texCoords[vertexID];
    return out;
}

fragment float4 darkMatterFragment(
    VertexOut in [[stage_in]],
    texture2d<float> texture [[texture(0)]]
) {
    constexpr sampler s(filter::linear);
    return texture.sample(s, in.texCoord);
}
```

### Step 2: Add Metal file to Xcode project

The Metal file needs to be added to the Xcode project. Since it's a new directory, we may need to add it.

### Step 3: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

### Step 4: Commit

```bash
git add MizanApp/Core/DesignSystem/Shaders/
git commit -m "feat(shaders): add DarkMatterShader.metal fluid simulation

Real-time fluid simulation for Event Horizon background:
- Simplex 3D noise for base turbulence
- Fractal Brownian Motion for layered detail
- Curl noise for fluid-like movement
- Touch interaction (gravitational wells)
- Scroll velocity time dilation
- Prayer period color temperature
- Performance-scaled noise octaves

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Create MetalView Bridge

**Files:**
- Create: `MizanApp/Core/DesignSystem/Components/MetalView.swift`
- Test: Build verification

### Step 1: Create the MetalView UIViewRepresentable

Create `MizanApp/Core/DesignSystem/Components/MetalView.swift`:

```swift
//
//  MetalView.swift
//  Mizan
//
//  UIViewRepresentable wrapper for Metal rendering
//

import SwiftUI
import MetalKit

/// SwiftUI wrapper for Metal shader rendering
struct MetalView: UIViewRepresentable {
    let device: MTLDevice?
    let commandQueue: MTLCommandQueue?
    let computePipeline: MTLComputePipelineState?
    let renderPipeline: MTLRenderPipelineState?

    @Binding var time: Float
    @Binding var touchPosition: SIMD2<Float>
    @Binding var touchIntensity: Float
    @Binding var scrollVelocity: Float
    @Binding var prayerPeriod: Int

    let density: Float
    let noiseOctaves: Int

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0)
        mtkView.preferredFramesPerSecond = DeviceCapabilities.current.targetFrameRate
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
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

    class Coordinator: NSObject, MTKViewDelegate {
        let device: MTLDevice?
        let commandQueue: MTLCommandQueue?
        let computePipeline: MTLComputePipelineState?
        let renderPipeline: MTLRenderPipelineState?

        var time: Float = 0
        var touchPosition: SIMD2<Float> = SIMD2(0.5, 0.5)
        var touchIntensity: Float = 0
        var scrollVelocity: Float = 0
        var prayerPeriod: Int = 5

        let density: Float
        let noiseOctaves: Int

        private var outputTexture: MTLTexture?

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
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Recreate output texture at new size
            createOutputTexture(size: size)
        }

        func draw(in view: MTKView) {
            guard let device = device,
                  let commandQueue = commandQueue,
                  let computePipeline = computePipeline,
                  let renderPipeline = renderPipeline,
                  let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor else { return }

            // Ensure output texture exists
            let drawableSize = view.drawableSize
            if outputTexture == nil ||
               outputTexture?.width != Int(drawableSize.width) ||
               outputTexture?.height != Int(drawableSize.height) {
                createOutputTexture(size: drawableSize)
            }

            guard let outputTexture = outputTexture,
                  let commandBuffer = commandQueue.makeCommandBuffer() else { return }

            // Compute pass - run shader
            if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
                computeEncoder.setComputePipelineState(computePipeline)
                computeEncoder.setTexture(outputTexture, index: 0)

                // Create uniforms
                var uniforms = DarkMatterUniforms(
                    time: time,
                    resolution: SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height)),
                    touchPosition: touchPosition,
                    touchIntensity: touchIntensity,
                    scrollVelocity: scrollVelocity,
                    prayerPeriod: Int32(prayerPeriod),
                    density: density,
                    noiseOctaves: Int32(noiseOctaves)
                )
                computeEncoder.setBytes(&uniforms, length: MemoryLayout<DarkMatterUniforms>.size, index: 0)

                // Dispatch threads
                let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
                let threadGroups = MTLSize(
                    width: (Int(drawableSize.width) + 15) / 16,
                    height: (Int(drawableSize.height) + 15) / 16,
                    depth: 1
                )
                computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
                computeEncoder.endEncoding()
            }

            // Render pass - draw to screen
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) {
                renderEncoder.setRenderPipelineState(renderPipeline)
                renderEncoder.setFragmentTexture(outputTexture, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                renderEncoder.endEncoding()
            }

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        private func createOutputTexture(size: CGSize) {
            guard let device = device else { return }

            let scale = DeviceCapabilities.current.shaderResolutionScale
            let scaledWidth = Int(size.width * CGFloat(scale))
            let scaledHeight = Int(size.height * CGFloat(scale))

            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm,
                width: max(scaledWidth, 1),
                height: max(scaledHeight, 1),
                mipmapped: false
            )
            descriptor.usage = [.shaderRead, .shaderWrite]
            outputTexture = device.makeTexture(descriptor: descriptor)
        }
    }
}

// MARK: - Uniforms Structure (must match Metal)

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
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Components/MetalView.swift
git commit -m "feat(metal): add MetalView SwiftUI bridge

UIViewRepresentable wrapper for Metal rendering:
- MTKView delegate for frame updates
- Uniform passing (time, touch, scroll, prayer period)
- Resolution scaling based on device tier
- Compute + render pass pipeline

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Create DarkMatterBackground

**Files:**
- Create: `MizanApp/Core/DesignSystem/Components/DarkMatterBackground.swift`
- Test: Build verification

### Step 1: Create the background component

Create `MizanApp/Core/DesignSystem/Components/DarkMatterBackground.swift`:

```swift
//
//  DarkMatterBackground.swift
//  Mizan
//
//  Animated Dark Matter background with Metal shader
//

import SwiftUI
import MetalKit

/// Animated Dark Matter background using Metal shader
/// Responds to touch, scroll, and prayer period changes
struct DarkMatterBackground: View {
    @Environment(\.deviceCapabilities) private var capabilities
    @State private var time: Float = 0
    @State private var touchPosition: SIMD2<Float> = SIMD2(0.5, 0.5)
    @State private var touchIntensity: Float = 0
    @State private var scrollVelocity: Float = 0

    let prayerPeriod: Int

    // Metal resources (lazy initialized)
    @State private var metalResources: MetalResources?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fallback gradient for reduced motion or initialization
                if metalResources == nil || UIAccessibility.isReduceMotionEnabled {
                    fallbackGradient
                } else if let resources = metalResources {
                    MetalView(
                        device: resources.device,
                        commandQueue: resources.commandQueue,
                        computePipeline: resources.computePipeline,
                        renderPipeline: resources.renderPipeline,
                        time: $time,
                        touchPosition: $touchPosition,
                        touchIntensity: $touchIntensity,
                        scrollVelocity: $scrollVelocity,
                        prayerPeriod: prayerPeriod,
                        density: 1.2,
                        noiseOctaves: capabilities.noiseOctaves
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard capabilities.enableShaderInteraction else { return }
                                let pos = value.location
                                touchPosition = SIMD2(
                                    Float(pos.x / geometry.size.width),
                                    Float(pos.y / geometry.size.height)
                                )
                                touchIntensity = 1.0
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.5)) {
                                    touchIntensity = 0
                                }
                            }
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            initializeMetal()
            startAnimationTimer()
        }
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [
                prayerPeriodColor(prayerPeriod),
                CinematicColors.voidBlack
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func prayerPeriodColor(_ period: Int) -> Color {
        switch period {
        case 0: return CinematicColors.periodFajr
        case 1: return CinematicColors.periodSunrise
        case 2: return CinematicColors.periodDhuhr
        case 3: return CinematicColors.periodAsr
        case 4: return CinematicColors.periodMaghrib
        default: return CinematicColors.periodIsha
        }
    }

    private func initializeMetal() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        Task {
            metalResources = await MetalResources.create()
        }
    }

    private func startAnimationTimer() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        // Use CADisplayLink for smooth animation
        let displayLink = DisplayLinkHandler { deltaTime in
            time += Float(deltaTime)

            // Fade touch intensity
            if touchIntensity > 0 {
                touchIntensity = max(0, touchIntensity - Float(deltaTime) * 2)
            }
        }
        displayLink.start()
    }
}

// MARK: - Metal Resources

private class MetalResources {
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

    static func create() async -> MetalResources? {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else {
            return nil
        }

        // Create compute pipeline
        guard let computeFunction = library.makeFunction(name: "darkMatterKernel"),
              let computePipeline = try? device.makeComputePipelineState(function: computeFunction) else {
            return nil
        }

        // Create render pipeline
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexFunction = library.makeFunction(name: "darkMatterVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "darkMatterFragment")
        renderDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        guard let renderPipeline = try? device.makeRenderPipelineState(descriptor: renderDescriptor) else {
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

// MARK: - Display Link Handler

private class DisplayLinkHandler {
    private var displayLink: CADisplayLink?
    private var lastTime: CFTimeInterval = 0
    private let onFrame: (TimeInterval) -> Void

    init(onFrame: @escaping (TimeInterval) -> Void) {
        self.onFrame = onFrame
    }

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleFrame))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func handleFrame(_ displayLink: CADisplayLink) {
        if lastTime == 0 {
            lastTime = displayLink.timestamp
            return
        }

        let deltaTime = displayLink.timestamp - lastTime
        lastTime = displayLink.timestamp

        onFrame(deltaTime)
    }
}

// MARK: - View Modifier

extension View {
    /// Apply Dark Matter animated background
    func darkMatterBackground(prayerPeriod: Int = 5) -> some View {
        self.background(DarkMatterBackground(prayerPeriod: prayerPeriod))
    }
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Components/DarkMatterBackground.swift
git commit -m "feat(visual): add DarkMatterBackground animated component

SwiftUI component for Dark Matter fluid background:
- Metal shader integration
- Touch interaction (gravitational wells)
- Prayer period color adaptation
- Fallback gradient for reduced motion
- CADisplayLink for smooth animation
- View modifier for easy application

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Create ParticleSystem

**Files:**
- Create: `MizanApp/Core/DesignSystem/Components/ParticleSystem.swift`
- Test: Build verification

### Step 1: Create the particle system

Create `MizanApp/Core/DesignSystem/Components/ParticleSystem.swift`:

```swift
//
//  ParticleSystem.swift
//  Mizan
//
//  Ambient particle effects for Dark Matter theme
//

import SwiftUI

/// Particle type for visual effects
enum ParticleType {
    /// Tiny (2px), slow drift, white 20% opacity
    case dust
    /// Small (4px), static twinkle, white 60% opacity
    case stars
    /// Medium (6px), float upward near prayers, gold
    case embers
    /// Elongated (2x8px), follow fluid flow, cyan
    case wisps
}

/// Individual particle data
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var opacity: Double
    var rotation: Angle
    var type: ParticleType
    var lifetime: TimeInterval
    var age: TimeInterval = 0
}

/// Ambient particle system overlay
struct ParticleSystem: View {
    @Environment(\.deviceCapabilities) private var capabilities
    @State private var particles: [Particle] = []
    @State private var lastUpdate: Date = Date()

    let type: ParticleType
    let prayerPeriod: Int

    private var particleCount: Int {
        min(capabilities.maxParticles, baseCount)
    }

    private var baseCount: Int {
        switch type {
        case .dust: return 100
        case .stars: return 50
        case .embers: return 30
        case .wisps: return 20
        }
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date
                    let deltaTime = now.timeIntervalSince(lastUpdate)

                    for particle in particles {
                        drawParticle(particle, in: context, size: size)
                    }

                    // Update on next frame
                    DispatchQueue.main.async {
                        updateParticles(deltaTime: deltaTime, bounds: size)
                        lastUpdate = now
                    }
                }
            }
            .onAppear {
                initializeParticles(bounds: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func drawParticle(_ particle: Particle, in context: GraphicsContext, size: CGSize) {
        var ctx = context

        let color = particleColor(for: particle.type)
        let adjustedOpacity = particle.opacity * (1.0 - particle.age / particle.lifetime)

        ctx.opacity = adjustedOpacity

        switch particle.type {
        case .dust, .embers:
            let rect = CGRect(
                x: particle.position.x - particle.size / 2,
                y: particle.position.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            ctx.fill(Circle().path(in: rect), with: .color(color))

        case .stars:
            // Draw 4-point star
            let path = starPath(at: particle.position, size: particle.size)
            ctx.fill(path, with: .color(color))

        case .wisps:
            // Draw elongated capsule
            ctx.translateBy(x: particle.position.x, y: particle.position.y)
            ctx.rotate(by: particle.rotation)
            let rect = CGRect(x: -1, y: -particle.size / 2, width: 2, height: particle.size)
            ctx.fill(Capsule().path(in: rect), with: .color(color))
        }
    }

    private func starPath(at center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let points = 4
        let innerRadius = size * 0.3
        let outerRadius = size

        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * .pi / Double(points) - .pi / 2
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

    private func particleColor(for type: ParticleType) -> Color {
        switch type {
        case .dust:
            return .white
        case .stars:
            return .white
        case .embers:
            return CinematicColors.prayerGold
        case .wisps:
            return DarkMatterTheme.shared.particleColor(for: PrayerPeriod(rawValue: prayerPeriod) ?? .isha)
        }
    }

    private func initializeParticles(bounds: CGSize) {
        particles = (0..<particleCount).map { _ in
            createParticle(bounds: bounds, randomAge: true)
        }
    }

    private func createParticle(bounds: CGSize, randomAge: Bool = false) -> Particle {
        let position = CGPoint(
            x: CGFloat.random(in: 0...bounds.width),
            y: type == .embers ? bounds.height + 10 : CGFloat.random(in: 0...bounds.height)
        )

        let velocity: CGVector
        let size: CGFloat
        let opacity: Double
        let lifetime: TimeInterval

        switch type {
        case .dust:
            velocity = CGVector(
                dx: CGFloat.random(in: -5...5),
                dy: CGFloat.random(in: -2...2)
            )
            size = 2
            opacity = 0.2
            lifetime = TimeInterval.random(in: 10...20)

        case .stars:
            velocity = .zero
            size = 4
            opacity = Double.random(in: 0.4...0.6)
            lifetime = TimeInterval.random(in: 5...15)

        case .embers:
            velocity = CGVector(
                dx: CGFloat.random(in: -10...10),
                dy: CGFloat.random(in: -30...-10)
            )
            size = 6
            opacity = 0.8
            lifetime = TimeInterval.random(in: 3...6)

        case .wisps:
            velocity = CGVector(
                dx: CGFloat.random(in: -20...20),
                dy: CGFloat.random(in: -10...10)
            )
            size = 8
            opacity = 0.4
            lifetime = TimeInterval.random(in: 8...12)
        }

        return Particle(
            position: position,
            velocity: velocity,
            size: size,
            opacity: opacity,
            rotation: .degrees(Double.random(in: 0...360)),
            type: type,
            lifetime: lifetime,
            age: randomAge ? TimeInterval.random(in: 0...lifetime) : 0
        )
    }

    private func updateParticles(deltaTime: TimeInterval, bounds: CGSize) {
        particles = particles.compactMap { particle in
            var updated = particle
            updated.age += deltaTime

            // Remove expired particles
            if updated.age >= updated.lifetime {
                return createParticle(bounds: bounds)
            }

            // Update position
            updated.position.x += updated.velocity.dx * deltaTime
            updated.position.y += updated.velocity.dy * deltaTime

            // Wrap around edges (except embers which respawn at bottom)
            if updated.type != .embers {
                if updated.position.x < -10 { updated.position.x = bounds.width + 10 }
                if updated.position.x > bounds.width + 10 { updated.position.x = -10 }
                if updated.position.y < -10 { updated.position.y = bounds.height + 10 }
                if updated.position.y > bounds.height + 10 { updated.position.y = -10 }
            } else if updated.position.y < -10 {
                return createParticle(bounds: bounds)
            }

            // Update rotation for wisps
            if updated.type == .wisps {
                updated.rotation += .degrees(deltaTime * 30)
            }

            // Twinkle effect for stars
            if updated.type == .stars {
                let twinkle = sin(updated.age * 3) * 0.2 + 0.8
                updated.opacity = 0.6 * twinkle
            }

            return updated
        }
    }
}

// MARK: - View Modifier

extension View {
    /// Add ambient particle overlay
    func particleOverlay(type: ParticleType = .dust, prayerPeriod: Int = 5) -> some View {
        self.overlay(ParticleSystem(type: type, prayerPeriod: prayerPeriod))
    }
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Components/ParticleSystem.swift
git commit -m "feat(visual): add ParticleSystem ambient effects

Ambient particle overlay for Dark Matter theme:
- Four particle types: dust, stars, embers, wisps
- Canvas-based rendering for performance
- Device tier scaling for particle count
- Prayer period color adaptation
- Lifecycle management with respawning
- View modifier for easy application

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Create Glass Effect Shaders

**Files:**
- Create: `MizanApp/Core/DesignSystem/Shaders/GlassShader.metal`
- Test: Build verification

### Step 1: Create the glass shader

Create `MizanApp/Core/DesignSystem/Shaders/GlassShader.metal`:

```metal
//
//  GlassShader.metal
//  Mizan
//
//  Glass morphism effect with blur and noise grain
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Glass Effect Kernel

struct GlassUniforms {
    float2 resolution;
    float blurRadius;
    float noiseIntensity;
    float borderGlow;
    float time;
};

// Simple hash for noise
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Gaussian weight
float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma));
}

// Single-pass blur approximation
[[kernel]]
void glassBlurKernel(
    texture2d<float, access::sample> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant GlassUniforms& uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= uint(uniforms.resolution.x) || gid.y >= uint(uniforms.resolution.y)) {
        return;
    }

    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float2 uv = float2(gid) / uniforms.resolution;
    float2 texelSize = 1.0 / uniforms.resolution;

    // Optimized blur with fewer samples
    float4 color = float4(0.0);
    float totalWeight = 0.0;

    int samples = int(uniforms.blurRadius / 4.0);
    samples = clamp(samples, 1, 8);

    for (int x = -samples; x <= samples; x++) {
        for (int y = -samples; y <= samples; y++) {
            float2 offset = float2(x, y) * texelSize * 4.0;
            float weight = gaussian(length(float2(x, y)), float(samples) * 0.5);
            color += input.sample(s, uv + offset) * weight;
            totalWeight += weight;
        }
    }

    color /= totalWeight;

    // Add noise grain
    float noise = hash(uv * uniforms.resolution + uniforms.time) * 2.0 - 1.0;
    color.rgb += noise * uniforms.noiseIntensity;

    output.write(color, gid);
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Shaders/GlassShader.metal
git commit -m "feat(shaders): add GlassShader for morphism effects

Glass morphism shader for card backgrounds:
- Gaussian blur approximation
- Noise grain overlay
- Configurable blur radius and intensity
- Performance-optimized sample count

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Create ImplosionShader

**Files:**
- Create: `MizanApp/Core/DesignSystem/Shaders/ImplosionShader.metal`
- Test: Build verification

### Step 1: Create the implosion shader

Create `MizanApp/Core/DesignSystem/Shaders/ImplosionShader.metal`:

```metal
//
//  ImplosionShader.metal
//  Mizan
//
//  Task completion implosion effect
//

#include <metal_stdlib>
using namespace metal;

struct ImplosionUniforms {
    float2 resolution;
    float2 center;
    float progress;    // 0.0 to 1.0
    float intensity;
};

[[kernel]]
void implosionKernel(
    texture2d<float, access::sample> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant ImplosionUniforms& uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= uint(uniforms.resolution.x) || gid.y >= uint(uniforms.resolution.y)) {
        return;
    }

    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float2 uv = float2(gid) / uniforms.resolution;

    // Vector from pixel to center
    float2 toCenter = uniforms.center - uv;
    float dist = length(toCenter);

    // Implosion phases
    // Phase 1 (0-0.3): Edges warp inward
    // Phase 2 (0.3-0.6): Particles rush toward center
    // Phase 3 (0.6-0.75): Collapse to point
    // Phase 4 (0.75-1.0): Flash and ripple

    float4 color;

    if (uniforms.progress < 0.75) {
        // Warp effect - pull pixels toward center
        float warpStrength = uniforms.progress * uniforms.intensity;
        float2 warpedUV = uv + normalize(toCenter) * warpStrength * (1.0 - dist);

        // Add stretch effect
        float stretch = 1.0 + uniforms.progress * 0.5;
        warpedUV = uniforms.center + (warpedUV - uniforms.center) / stretch;

        color = input.sample(s, warpedUV);

        // Fade as we approach center collapse
        float fade = 1.0 - smoothstep(0.5, 0.75, uniforms.progress);
        color.a *= fade;

    } else {
        // Flash phase
        float flashProgress = (uniforms.progress - 0.75) / 0.25;

        // Bright center point
        float brightness = exp(-dist * 20.0) * (1.0 - flashProgress);

        // Ripple emanating from center
        float ripplePhase = flashProgress * 3.0;
        float ripple = sin((dist - ripplePhase * 0.3) * 30.0) * 0.5 + 0.5;
        ripple *= exp(-dist * 5.0) * flashProgress;

        // Cyan accent color
        float3 accentCyan = float3(0.50, 0.86, 1.0);
        color = float4(accentCyan * (brightness + ripple * 0.3), brightness);
    }

    output.write(color, gid);
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Shaders/ImplosionShader.metal
git commit -m "feat(shaders): add ImplosionShader for task completion

Gravitational collapse effect for task completion:
- Four-phase animation (warp, rush, collapse, flash)
- Pixel warping toward center point
- Ripple emanation after collapse
- Cyan accent glow

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Create WarpTransitionShader

**Files:**
- Create: `MizanApp/Core/DesignSystem/Shaders/WarpTransitionShader.metal`
- Test: Build verification

### Step 1: Create the warp transition shader

Create `MizanApp/Core/DesignSystem/Shaders/WarpTransitionShader.metal`:

```metal
//
//  WarpTransitionShader.metal
//  Mizan
//
//  Warp speed transition effect between tabs
//

#include <metal_stdlib>
using namespace metal;

struct WarpUniforms {
    float2 resolution;
    float progress;      // 0.0 to 1.0
    float direction;     // -1.0 (left) or 1.0 (right)
};

[[kernel]]
void warpTransitionKernel(
    texture2d<float, access::sample> fromTexture [[texture(0)]],
    texture2d<float, access::sample> toTexture [[texture(1)]],
    texture2d<float, access::write> output [[texture(2)]],
    constant WarpUniforms& uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= uint(uniforms.resolution.x) || gid.y >= uint(uniforms.resolution.y)) {
        return;
    }

    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float2 uv = float2(gid) / uniforms.resolution;

    // Smooth progress curve
    float t = smoothstep(0.0, 1.0, uniforms.progress);

    // Motion blur stretch in direction of transition
    float stretch = sin(t * 3.14159) * 0.3;
    float2 stretchOffset = float2(stretch * uniforms.direction, 0.0);

    // Sample from both textures with motion blur
    float4 fromColor = float4(0.0);
    float4 toColor = float4(0.0);
    int blurSamples = 5;

    for (int i = 0; i < blurSamples; i++) {
        float offset = float(i) / float(blurSamples - 1) - 0.5;
        float2 blurOffset = stretchOffset * offset;

        // From texture slides out
        float2 fromUV = uv + blurOffset - float2(t * uniforms.direction * 1.5, 0.0);
        fromColor += fromTexture.sample(s, fromUV);

        // To texture slides in
        float2 toUV = uv + blurOffset + float2((1.0 - t) * uniforms.direction * 1.5, 0.0);
        toColor += toTexture.sample(s, toUV);
    }

    fromColor /= float(blurSamples);
    toColor /= float(blurSamples);

    // Cross-fade with brief void moment
    float voidMoment = smoothstep(0.4, 0.5, t) * smoothstep(0.6, 0.5, t);
    float4 voidColor = float4(0.02, 0.02, 0.03, 1.0);

    float4 mixed = mix(fromColor, toColor, t);
    float4 finalColor = mix(mixed, voidColor, voidMoment * 0.5);

    // Add edge darkening during transition
    float edgeDark = 1.0 - stretch * 0.5;
    finalColor.rgb *= edgeDark;

    output.write(finalColor, gid);
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Shaders/WarpTransitionShader.metal
git commit -m "feat(shaders): add WarpTransitionShader for tab navigation

Warp speed transition effect:
- Motion blur in transition direction
- Brief void moment between views
- Edge darkening during movement
- Smooth easing curves

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Update Xcode Project for Metal Files

**Files:**
- Modify: `Mizan.xcodeproj/project.pbxproj`
- Test: Build verification

### Step 1: Check if Metal files are auto-discovered

Modern Xcode projects often auto-discover .metal files. First, try building to see if they're included.

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED|metal)" | head -20
```

### Step 2: If needed, add files manually

If Metal files aren't found, we need to add them to the Xcode project.

### Step 3: Verify all shaders compile

```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

### Step 4: Commit any project file changes

```bash
git add -A
git commit -m "build(xcode): add Metal shader files to project

Include shader files in build:
- DarkMatterShader.metal
- GlassShader.metal
- ImplosionShader.metal
- WarpTransitionShader.metal

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Run Full Test Suite

**Files:**
- Test: All tests

### Step 1: Run build and tests

```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=CB32C2FD-421F-4D1E-ACE3-650C7D948ACB' test 2>&1 | grep -E "(Test Case|passed|failed|TEST SUCCEEDED|TEST FAILED)" | tail -40
```

### Step 2: Document any failures

If tests fail, create issues or fix immediately if simple.

### Step 3: Final commit for Phase 2

```bash
git add -A
git commit -m "test: verify Phase 2 visual foundation complete

All tests passing after Event Horizon Phase 2:
- DeviceTier performance detection
- DarkMatterShader.metal fluid simulation
- MetalView SwiftUI bridge
- DarkMatterBackground component
- ParticleSystem ambient effects
- GlassShader, ImplosionShader, WarpTransitionShader

Phase 2 Visual Foundation complete. Ready for Phase 3 (Core Components).

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Phase 2 Completion Checklist

- [ ] Task 1: DeviceTier detection created
- [ ] Task 2: DarkMatterShader.metal created
- [ ] Task 3: MetalView bridge created
- [ ] Task 4: DarkMatterBackground created
- [ ] Task 5: ParticleSystem created
- [ ] Task 6: GlassShader created
- [ ] Task 7: ImplosionShader created
- [ ] Task 8: WarpTransitionShader created
- [ ] Task 9: Xcode project updated
- [ ] Task 10: Full test suite passing

---

## Next Phase

After Phase 2 completion, proceed to **Phase 3: Core Components** which includes:
- CinematicContainer (glass cards)
- EventHorizonDock with all states
- WarpTransition SwiftUI component
- Replace MainTabView with dock navigation

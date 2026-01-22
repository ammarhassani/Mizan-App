//
//  WarpTransitionShader.metal
//  MizanApp
//
//  Warp speed transition shader for tab switching in Event Horizon UI
//  Creates a motion blur stretch effect with void moment for tab transitions
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Uniforms Structure

struct WarpUniforms {
    float2 resolution;
    float progress;      // 0.0 to 1.0
    float direction;     // -1.0 (left) or 1.0 (right)
};

// MARK: - Constants

constant int MOTION_BLUR_SAMPLES = 5;

// MARK: - Helper Functions

// Smooth easing function using smoothstep
float easeInOutCubic(float t) {
    return t < 0.5
        ? 4.0 * t * t * t
        : 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0;
}

// Calculate the void darkness factor (peaks at midpoint 0.4-0.6)
float voidFactor(float progress) {
    // Create a dark void at the midpoint of the transition
    float voidStart = 0.4;
    float voidEnd = 0.6;
    float voidPeak = 0.5;

    if (progress < voidStart || progress > voidEnd) {
        return 0.0;
    }

    // Smooth peak at midpoint
    float dist = abs(progress - voidPeak) / (voidEnd - voidStart);
    return 1.0 - smoothstep(0.0, 0.5, dist);
}

// Edge darkening based on stretch amount
float edgeDarkening(float2 uv, float stretchAmount) {
    // Darken edges more during high stretch
    float edgeX = smoothstep(0.0, 0.15, uv.x) * smoothstep(1.0, 0.85, uv.x);
    float edgeY = smoothstep(0.0, 0.1, uv.y) * smoothstep(1.0, 0.9, uv.y);
    float edge = edgeX * edgeY;

    // More darkening during stretch
    float darkAmount = stretchAmount * 0.5;
    return mix(1.0, edge, darkAmount);
}

// Sample texture with motion blur in the specified direction
float4 motionBlurSample(
    texture2d<float, access::sample> tex,
    sampler texSampler,
    float2 uv,
    float2 blurDirection,
    float blurAmount
) {
    float4 color = float4(0.0);
    float totalWeight = 0.0;

    for (int i = 0; i < MOTION_BLUR_SAMPLES; i++) {
        float t = float(i) / float(MOTION_BLUR_SAMPLES - 1) - 0.5;
        float2 offset = blurDirection * t * blurAmount;
        float2 sampleUV = uv + offset;

        // Clamp to valid UV range
        sampleUV = clamp(sampleUV, float2(0.0), float2(1.0));

        // Gaussian-like weight (center samples weighted more)
        float weight = exp(-4.0 * t * t);
        color += tex.sample(texSampler, sampleUV) * weight;
        totalWeight += weight;
    }

    return color / totalWeight;
}

// MARK: - Warp Transition Compute Kernel

kernel void warpTransitionKernel(
    texture2d<float, access::sample> fromTexture [[texture(0)]],
    texture2d<float, access::sample> toTexture [[texture(1)]],
    texture2d<float, access::write> outputTexture [[texture(2)]],
    constant WarpUniforms &uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Check bounds
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }

    // Calculate normalized UV coordinates
    float2 uv = float2(gid) / uniforms.resolution;

    // Create sampler for texture sampling
    constexpr sampler texSampler(
        filter::linear,
        address::clamp_to_edge
    );

    // Apply eased progress
    float easedProgress = easeInOutCubic(uniforms.progress);

    // Calculate motion blur direction (horizontal, in transition direction)
    float2 blurDirection = float2(uniforms.direction, 0.0);

    // Calculate stretch/blur amount (peaks in middle of transition)
    float stretchAmount = sin(easedProgress * 3.14159265359) * 0.3;

    // Calculate slide offset for each texture
    // From texture slides out in the direction
    float fromOffset = easedProgress * uniforms.direction;
    // To texture slides in from opposite direction
    float toOffset = (easedProgress - 1.0) * uniforms.direction;

    // Adjust UV for sliding effect
    float2 fromUV = uv;
    fromUV.x -= fromOffset;

    float2 toUV = uv;
    toUV.x -= toOffset;

    // Sample both textures with motion blur
    float4 fromColor = motionBlurSample(
        fromTexture,
        texSampler,
        fromUV,
        blurDirection,
        stretchAmount
    );

    float4 toColor = motionBlurSample(
        toTexture,
        texSampler,
        toUV,
        blurDirection,
        stretchAmount
    );

    // Determine visibility of each texture based on UV bounds
    float fromVisible = step(0.0, fromUV.x) * step(fromUV.x, 1.0);
    float toVisible = step(0.0, toUV.x) * step(toUV.x, 1.0);

    // Cross-fade between textures using progress
    float crossfade = smoothstep(0.3, 0.7, easedProgress);

    // Combine textures
    float4 color = float4(0.0, 0.0, 0.0, 1.0);

    if (fromVisible > 0.5 && toVisible > 0.5) {
        // Both visible - cross-fade
        color = mix(fromColor, toColor, crossfade);
    } else if (fromVisible > 0.5) {
        // Only from visible
        color = fromColor;
    } else if (toVisible > 0.5) {
        // Only to visible
        color = toColor;
    }
    // If neither visible, stays black (void)

    // Apply void darkening at midpoint
    float voidDarkness = voidFactor(uniforms.progress);
    color.rgb *= (1.0 - voidDarkness * 0.8);

    // Apply edge darkening during stretch
    float edgeDark = edgeDarkening(uv, stretchAmount);
    color.rgb *= edgeDark;

    // Ensure alpha is 1.0
    color.a = 1.0;

    // Write to output texture
    outputTexture.write(color, gid);
}

// MARK: - Alternative Fragment Shader Version
// For use when compute shaders are not preferred or available

struct WarpVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex WarpVertexOut warpTransitionVertex(
    uint vertexID [[vertex_id]]
) {
    // Full-screen quad vertices
    const float2 positions[4] = {
        float2(-1.0, -1.0),  // Bottom-left
        float2( 1.0, -1.0),  // Bottom-right
        float2(-1.0,  1.0),  // Top-left
        float2( 1.0,  1.0)   // Top-right
    };

    const float2 texCoords[4] = {
        float2(0.0, 1.0),  // Bottom-left (flip Y for Metal)
        float2(1.0, 1.0),  // Bottom-right
        float2(0.0, 0.0),  // Top-left
        float2(1.0, 0.0)   // Top-right
    };

    WarpVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = texCoords[vertexID];

    return out;
}

fragment float4 warpTransitionFragment(
    WarpVertexOut in [[stage_in]],
    texture2d<float> fromTexture [[texture(0)]],
    texture2d<float> toTexture [[texture(1)]],
    constant WarpUniforms &uniforms [[buffer(0)]]
) {
    float2 uv = in.texCoord;

    // Create sampler
    constexpr sampler texSampler(
        filter::linear,
        address::clamp_to_edge
    );

    // Apply eased progress
    float easedProgress = easeInOutCubic(uniforms.progress);

    // Calculate motion blur direction
    float2 blurDirection = float2(uniforms.direction, 0.0);

    // Calculate stretch amount
    float stretchAmount = sin(easedProgress * 3.14159265359) * 0.3;

    // Calculate slide offsets
    float fromOffset = easedProgress * uniforms.direction;
    float toOffset = (easedProgress - 1.0) * uniforms.direction;

    // Adjust UVs
    float2 fromUV = uv;
    fromUV.x -= fromOffset;

    float2 toUV = uv;
    toUV.x -= toOffset;

    // Sample with motion blur
    float4 fromColor = motionBlurSample(fromTexture, texSampler, fromUV, blurDirection, stretchAmount);
    float4 toColor = motionBlurSample(toTexture, texSampler, toUV, blurDirection, stretchAmount);

    // Visibility checks
    float fromVisible = step(0.0, fromUV.x) * step(fromUV.x, 1.0);
    float toVisible = step(0.0, toUV.x) * step(toUV.x, 1.0);

    // Cross-fade
    float crossfade = smoothstep(0.3, 0.7, easedProgress);

    // Combine
    float4 color = float4(0.0, 0.0, 0.0, 1.0);

    if (fromVisible > 0.5 && toVisible > 0.5) {
        color = mix(fromColor, toColor, crossfade);
    } else if (fromVisible > 0.5) {
        color = fromColor;
    } else if (toVisible > 0.5) {
        color = toColor;
    }

    // Apply void and edge darkening
    float voidDarkness = voidFactor(uniforms.progress);
    color.rgb *= (1.0 - voidDarkness * 0.8);

    float edgeDark = edgeDarkening(uv, stretchAmount);
    color.rgb *= edgeDark;

    color.a = 1.0;

    return color;
}

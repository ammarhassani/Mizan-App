//
//  GlassShader.metal
//  MizanApp
//
//  Glass morphism blur shader for Event Horizon UI
//  Creates frosted glass effects with blur, noise grain, and subtle glow
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Uniforms Structure

struct GlassUniforms {
    float2 resolution;
    float blurRadius;
    float noiseIntensity;
    float borderGlow;
    float time;
};

// MARK: - Constants

constant float PI = 3.14159265359;

// MARK: - Hash Function for Noise Grain

// Simple hash function for procedural noise
// Uses a combination of sine and dot product for pseudo-random values
float glassHash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Alternative hash with time variation for animated grain
float glassHashAnimated(float2 p, float time) {
    p += fract(time * 0.1);
    return glassHash(p);
}

// MARK: - Gaussian Weight Function

// Compute Gaussian weight for blur sampling
// sigma is derived from blur radius for natural falloff
float gaussianWeight(float offset, float sigma) {
    float coefficient = 1.0 / (sigma * sqrt(2.0 * PI));
    float exponent = -(offset * offset) / (2.0 * sigma * sigma);
    return coefficient * exp(exponent);
}

// Pre-computed Gaussian weights for optimized 9-tap blur
// These weights are normalized to sum to 1.0
// Weights for sigma = 1.5, normalized
constant float GAUSSIAN_WEIGHTS_9[9] = {
    0.0162, 0.0540, 0.1216, 0.1871, 0.2019,
    0.1871, 0.1216, 0.0540, 0.0162
};

float getGaussianWeight9(int index) {
    return GAUSSIAN_WEIGHTS_9[clamp(index, 0, 8)];
}

// Pre-computed Gaussian weights for optimized 5-tap blur
// Weights for sigma = 1.0, normalized
constant float GAUSSIAN_WEIGHTS_5[5] = {
    0.0614, 0.2442, 0.3877, 0.2442, 0.0614
};

float getGaussianWeight5(int index) {
    return GAUSSIAN_WEIGHTS_5[clamp(index, 0, 4)];
}

// MARK: - Glass Blur Compute Kernel

kernel void glassBlurKernel(
    texture2d<float, access::sample> inputTexture [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]],
    constant GlassUniforms &uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Check bounds
    uint width = outputTexture.get_width();
    uint height = outputTexture.get_height();

    if (gid.x >= width || gid.y >= height) {
        return;
    }

    // Configure sampler with linear filtering and clamp to edge
    constexpr sampler linearSampler(
        coord::normalized,
        filter::linear,
        address::clamp_to_edge
    );

    // Calculate normalized UV coordinates
    float2 uv = float2(gid) / float2(width, height);
    float2 texelSize = 1.0 / float2(width, height);

    // Determine blur sample count based on blur radius
    // Lower radius = fewer samples for performance
    float blurRadius = clamp(uniforms.blurRadius, 0.0, 20.0);

    float4 blurredColor = float4(0.0);
    float totalWeight = 0.0;

    if (blurRadius < 2.0) {
        // Minimal blur - use 5 samples (optimized)
        for (int i = -2; i <= 2; i++) {
            for (int j = -2; j <= 2; j++) {
                float2 offset = float2(float(i), float(j)) * texelSize * blurRadius * 0.5;
                float weight = getGaussianWeight5(i + 2) * getGaussianWeight5(j + 2);

                float4 sample = inputTexture.sample(linearSampler, uv + offset);
                blurredColor += sample * weight;
                totalWeight += weight;
            }
        }
    } else {
        // Full blur - use 9 samples per axis (81 total samples)
        // For performance, we use separable blur approximation
        float sigma = blurRadius * 0.25;

        for (int i = -4; i <= 4; i++) {
            for (int j = -4; j <= 4; j++) {
                float2 offset = float2(float(i), float(j)) * texelSize * blurRadius * 0.25;

                // Calculate Gaussian weight based on distance
                float dist = length(float2(float(i), float(j)));
                float weight = gaussianWeight(dist, sigma);

                float4 sample = inputTexture.sample(linearSampler, uv + offset);
                blurredColor += sample * weight;
                totalWeight += weight;
            }
        }
    }

    // Normalize by total weight
    if (totalWeight > 0.0) {
        blurredColor /= totalWeight;
    }

    // Add noise grain overlay for glass texture
    if (uniforms.noiseIntensity > 0.0) {
        // Generate animated noise grain
        float2 noiseCoord = float2(gid) + uniforms.time * 10.0;
        float noise = glassHashAnimated(noiseCoord * 0.1, uniforms.time);

        // Apply noise as subtle luminance variation
        float noiseEffect = (noise - 0.5) * 2.0 * uniforms.noiseIntensity;
        blurredColor.rgb += noiseEffect * 0.03;
    }

    // Add subtle border glow effect
    if (uniforms.borderGlow > 0.0) {
        // Calculate distance from edges
        float2 centered = abs(uv * 2.0 - 1.0);
        float edgeDist = max(centered.x, centered.y);

        // Soft glow falloff near edges
        float glowMask = smoothstep(0.85, 1.0, edgeDist);
        float glow = glowMask * uniforms.borderGlow;

        // Add subtle white glow
        blurredColor.rgb += float3(1.0, 1.0, 1.0) * glow * 0.15;
    }

    // Ensure color stays in valid range
    blurredColor = saturate(blurredColor);

    // Write to output texture
    outputTexture.write(blurredColor, gid);
}

// MARK: - Optimized Horizontal Blur Pass

kernel void glassBlurHorizontal(
    texture2d<float, access::sample> inputTexture [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]],
    constant GlassUniforms &uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint width = outputTexture.get_width();
    uint height = outputTexture.get_height();

    if (gid.x >= width || gid.y >= height) {
        return;
    }

    constexpr sampler linearSampler(
        coord::normalized,
        filter::linear,
        address::clamp_to_edge
    );

    float2 uv = float2(gid) / float2(width, height);
    float texelSizeX = 1.0 / float(width);
    float blurRadius = clamp(uniforms.blurRadius, 0.0, 20.0);

    float4 blurredColor = float4(0.0);
    float totalWeight = 0.0;

    // 9-tap horizontal blur
    for (int i = -4; i <= 4; i++) {
        float offset = float(i) * texelSizeX * blurRadius * 0.25;
        float weight = getGaussianWeight9(i + 4);

        float4 sample = inputTexture.sample(linearSampler, uv + float2(offset, 0.0));
        blurredColor += sample * weight;
        totalWeight += weight;
    }

    blurredColor /= totalWeight;
    outputTexture.write(blurredColor, gid);
}

// MARK: - Optimized Vertical Blur Pass

kernel void glassBlurVertical(
    texture2d<float, access::sample> inputTexture [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]],
    constant GlassUniforms &uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint width = outputTexture.get_width();
    uint height = outputTexture.get_height();

    if (gid.x >= width || gid.y >= height) {
        return;
    }

    constexpr sampler linearSampler(
        coord::normalized,
        filter::linear,
        address::clamp_to_edge
    );

    float2 uv = float2(gid) / float2(width, height);
    float texelSizeY = 1.0 / float(height);
    float blurRadius = clamp(uniforms.blurRadius, 0.0, 20.0);

    float4 blurredColor = float4(0.0);
    float totalWeight = 0.0;

    // 9-tap vertical blur
    for (int i = -4; i <= 4; i++) {
        float offset = float(i) * texelSizeY * blurRadius * 0.25;
        float weight = getGaussianWeight9(i + 4);

        float4 sample = inputTexture.sample(linearSampler, uv + float2(0.0, offset));
        blurredColor += sample * weight;
        totalWeight += weight;
    }

    blurredColor /= totalWeight;

    // Add noise grain on final pass
    if (uniforms.noiseIntensity > 0.0) {
        float2 noiseCoord = float2(gid) + uniforms.time * 10.0;
        float noise = glassHashAnimated(noiseCoord * 0.1, uniforms.time);
        float noiseEffect = (noise - 0.5) * 2.0 * uniforms.noiseIntensity;
        blurredColor.rgb += noiseEffect * 0.03;
    }

    // Add border glow on final pass
    if (uniforms.borderGlow > 0.0) {
        float2 centered = abs(uv * 2.0 - 1.0);
        float edgeDist = max(centered.x, centered.y);
        float glowMask = smoothstep(0.85, 1.0, edgeDist);
        float glow = glowMask * uniforms.borderGlow;
        blurredColor.rgb += float3(1.0, 1.0, 1.0) * glow * 0.15;
    }

    blurredColor = saturate(blurredColor);
    outputTexture.write(blurredColor, gid);
}

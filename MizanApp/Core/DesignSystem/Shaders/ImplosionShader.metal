//
//  ImplosionShader.metal
//  MizanApp
//
//  Metal shader for task completion implosion effect
//  Creates a dramatic visual collapse when a task is marked as complete
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Uniforms Structure

struct ImplosionUniforms {
    float2 resolution;
    float2 center;
    float progress;    // 0.0 to 1.0
    float intensity;
};

// MARK: - Vertex Data

struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// MARK: - Constants

constant float PI = 3.14159265359;

// Event Horizon signature cyan color
constant float3 IMPLOSION_CYAN = float3(0.3, 0.8, 0.9);
constant float3 IMPLOSION_WHITE = float3(1.0, 1.0, 1.0);

// MARK: - Utility Functions

// Simple pseudo-random function
float hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 2D noise function
float noise2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    // Smooth interpolation
    float2 u = f * f * (3.0 - 2.0 * f);

    // Four corners
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Smooth step with configurable edges
float smoothEdge(float edge0, float edge1, float x) {
    float t = saturate((x - edge0) / (edge1 - edge0));
    return t * t * (3.0 - 2.0 * t);
}

// MARK: - Phase Functions

// Phase 1 (0-0.3): Edges warp inward
float2 phase1EdgeWarp(float2 uv, float2 center, float progress, float intensity) {
    float phaseProgress = saturate(progress / 0.3);

    float2 toCenter = center - uv;
    float dist = length(toCenter);
    float2 dir = normalize(toCenter);

    // Warp strength increases from edges toward center
    float edgeFactor = smoothstep(0.0, 0.5, dist);
    float warpStrength = edgeFactor * phaseProgress * intensity * 0.15;

    // Add subtle waviness to the warp
    float wave = sin(dist * 20.0 + phaseProgress * PI) * 0.02 * phaseProgress;

    return uv + dir * (warpStrength + wave);
}

// Phase 2 (0.3-0.6): Particles rush toward center
float2 phase2ParticleRush(float2 uv, float2 center, float progress, float intensity) {
    float phaseProgress = saturate((progress - 0.3) / 0.3);

    float2 toCenter = center - uv;
    float dist = length(toCenter);
    float2 dir = normalize(toCenter);

    // Accelerating pull toward center
    float acceleration = pow(phaseProgress, 2.0);
    float pullStrength = acceleration * intensity * 0.4;

    // Distance-based falloff (closer pixels pulled more)
    float distFactor = 1.0 - smoothstep(0.0, 0.8, dist);
    pullStrength *= mix(0.3, 1.0, distFactor);

    // Add stretch effect along the pull direction
    float stretch = phaseProgress * 0.3 * intensity;

    float2 warpedUV = uv + dir * pullStrength;

    // Apply radial stretching
    float2 stretchOffset = dir * dist * stretch;
    warpedUV += stretchOffset;

    return warpedUV;
}

// Phase 3 (0.6-0.75): Collapse to bright point
float2 phase3Collapse(float2 uv, float2 center, float progress, float intensity) {
    float phaseProgress = saturate((progress - 0.6) / 0.15);

    // Strong collapse toward center
    float collapseStrength = pow(phaseProgress, 1.5) * intensity * 0.7;

    // Everything rushes to center
    float2 warpedUV = mix(uv, center, collapseStrength);

    return warpedUV;
}

// Phase 4 ripple emanation from center
float calculateRipple(float2 uv, float2 center, float progress) {
    float phaseProgress = saturate((progress - 0.75) / 0.25);

    float dist = length(uv - center);

    // Ripple expands outward from center
    float rippleRadius = phaseProgress * 1.5;
    float rippleWidth = 0.1;

    // Multiple concentric ripples
    float ripple1 = smoothstep(rippleRadius - rippleWidth, rippleRadius, dist) *
                    smoothstep(rippleRadius + rippleWidth, rippleRadius, dist);

    float ripple2Radius = rippleRadius * 0.6;
    float ripple2 = smoothstep(ripple2Radius - rippleWidth * 0.7, ripple2Radius, dist) *
                    smoothstep(ripple2Radius + rippleWidth * 0.7, ripple2Radius, dist);

    float ripple3Radius = rippleRadius * 0.3;
    float ripple3 = smoothstep(ripple3Radius - rippleWidth * 0.5, ripple3Radius, dist) *
                    smoothstep(ripple3Radius + rippleWidth * 0.5, ripple3Radius, dist);

    // Fade ripples as they expand
    float fade = 1.0 - phaseProgress * 0.7;

    return (ripple1 * 0.8 + ripple2 * 0.5 + ripple3 * 0.3) * fade;
}

// MARK: - Main Implosion Effect

float4 implosionEffect(
    float2 uv,
    float4 sourceColor,
    constant ImplosionUniforms &uniforms
) {
    float2 center = uniforms.center / uniforms.resolution;
    float progress = saturate(uniforms.progress);
    float intensity = uniforms.intensity;

    // Initialize output
    float4 color = sourceColor;
    float2 warpedUV = uv;

    // Apply phase-based UV warping
    if (progress < 0.3) {
        // Phase 1: Edges warp inward
        warpedUV = phase1EdgeWarp(uv, center, progress, intensity);
    } else if (progress < 0.6) {
        // Phase 2: Particles rush toward center (includes Phase 1 completion)
        float2 phase1UV = phase1EdgeWarp(uv, center, 0.3, intensity);
        warpedUV = phase2ParticleRush(phase1UV, center, progress, intensity);
    } else if (progress < 0.75) {
        // Phase 3: Collapse to bright point
        float2 phase1UV = phase1EdgeWarp(uv, center, 0.3, intensity);
        float2 phase2UV = phase2ParticleRush(phase1UV, center, 0.6, intensity);
        warpedUV = phase3Collapse(phase2UV, center, progress, intensity);
    } else {
        // Phase 4: After collapse - UV stays at center, effects take over
        warpedUV = center;
    }

    // Calculate distance from center for effects
    float distFromCenter = length(uv - center);

    // --- Visual Effects ---

    // Stretch effect during phases 2-3
    float stretchAmount = 0.0;
    if (progress >= 0.3 && progress < 0.75) {
        float stretchProgress = (progress - 0.3) / 0.45;
        stretchAmount = sin(stretchProgress * PI) * intensity * 0.5;

        // Radial stretch lines
        float angle = atan2(uv.y - center.y, uv.x - center.x);
        float stretchLines = abs(sin(angle * 12.0 + distFromCenter * 30.0));
        stretchLines = pow(stretchLines, 4.0) * stretchAmount * (1.0 - distFromCenter);

        color.rgb += IMPLOSION_CYAN * stretchLines * 0.3;
    }

    // Bright center flash during phase 3
    if (progress >= 0.6 && progress < 0.85) {
        float flashProgress = (progress - 0.6) / 0.25;
        float flashIntensity = sin(flashProgress * PI) * intensity;

        // Bright cyan core
        float coreRadius = 0.1 * (1.0 - flashProgress * 0.8);
        float coreBrightness = smoothstep(coreRadius, 0.0, distFromCenter);
        coreBrightness = pow(coreBrightness, 2.0) * flashIntensity;

        // Add white-hot center
        float whiteCore = smoothstep(coreRadius * 0.3, 0.0, distFromCenter);
        whiteCore = pow(whiteCore, 3.0) * flashIntensity;

        color.rgb = mix(color.rgb, IMPLOSION_CYAN, coreBrightness * 0.8);
        color.rgb = mix(color.rgb, IMPLOSION_WHITE, whiteCore * 0.9);
    }

    // Phase 4: Ripple waves emanating outward
    if (progress >= 0.75) {
        float ripple = calculateRipple(uv, center, progress);

        // Cyan-tinted ripples
        color.rgb += IMPLOSION_CYAN * ripple * intensity * 0.4;

        // Subtle glow at center that fades
        float fadeProgress = (progress - 0.75) / 0.25;
        float centerGlow = smoothstep(0.15, 0.0, distFromCenter);
        centerGlow *= (1.0 - fadeProgress) * intensity;
        color.rgb += IMPLOSION_CYAN * centerGlow * 0.3;
    }

    // Overall fade opacity as collapse completes
    float opacityFade = 1.0;
    if (progress > 0.6 && progress < 0.9) {
        float fadeProgress = (progress - 0.6) / 0.3;
        // Pixels further from center fade first
        float distanceFade = smoothstep(0.1, 0.6, distFromCenter);
        opacityFade = mix(1.0, 0.3, fadeProgress * distanceFade);
    } else if (progress >= 0.9) {
        // Final fade out
        float finalFade = (progress - 0.9) / 0.1;
        opacityFade = mix(0.3, 1.0, finalFade); // Restore opacity for ripple visibility
    }

    color.a *= opacityFade;

    // Ensure color stays in valid range
    color.rgb = saturate(color.rgb);
    color.a = saturate(color.a);

    return color;
}

// MARK: - Compute Kernel

kernel void implosionKernel(
    texture2d<float, access::read> inputTexture [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]],
    constant ImplosionUniforms &uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Check bounds
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }

    // Calculate normalized UV coordinates
    float2 uv = float2(gid) / uniforms.resolution;

    // Sample the source texture
    float4 sourceColor = inputTexture.read(gid);

    // Apply the implosion effect
    float4 color = implosionEffect(uv, sourceColor, uniforms);

    // Write to output texture
    outputTexture.write(color, gid);
}

// MARK: - Vertex Shader for Full-Screen Quad

vertex VertexOut implosionVertex(
    uint vertexID [[vertex_id]]
) {
    // Generate full-screen quad vertices (2 triangles)
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

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = texCoords[vertexID];

    return out;
}

// MARK: - Fragment Shader

fragment float4 implosionFragment(
    VertexOut in [[stage_in]],
    texture2d<float> sourceTexture [[texture(0)]],
    sampler textureSampler [[sampler(0)]],
    constant ImplosionUniforms &uniforms [[buffer(0)]]
) {
    // Sample the source texture
    float4 sourceColor = sourceTexture.sample(textureSampler, in.texCoord);

    // Apply the implosion effect
    return implosionEffect(in.texCoord, sourceColor, uniforms);
}

// MARK: - Alternative Direct Fragment Shader (no source texture)
// Use this when applying to a solid color or procedural background

fragment float4 implosionFragmentDirect(
    VertexOut in [[stage_in]],
    constant ImplosionUniforms &uniforms [[buffer(0)]]
) {
    // Create a base color (can be customized)
    float4 baseColor = float4(0.1, 0.1, 0.15, 1.0);

    // Apply the implosion effect
    return implosionEffect(in.texCoord, baseColor, uniforms);
}

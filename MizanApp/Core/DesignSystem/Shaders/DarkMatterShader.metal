//
//  DarkMatterShader.metal
//  MizanApp
//
//  Dark Matter fluid simulation shader for Event Horizon UI
//  Creates a dynamic, prayer-period-aware fluid background effect
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Uniforms Structure

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
constant float TAU = 6.28318530718;

// Prayer period base colors (RGB normalized)
// Fajr: Deep blue with gold hints (#0a0a23)
constant float3 FAJR_BASE = float3(0.039, 0.039, 0.137);
constant float3 FAJR_ACCENT = float3(0.85, 0.75, 0.4);

// Sunrise: Warm gold ribbons
constant float3 SUNRISE_BASE = float3(0.08, 0.04, 0.15);
constant float3 SUNRISE_ACCENT = float3(1.0, 0.85, 0.4);

// Dhuhr: Amber threads
constant float3 DHUHR_BASE = float3(0.06, 0.04, 0.12);
constant float3 DHUHR_ACCENT = float3(1.0, 0.7, 0.3);

// Asr: Copper bronze swirls
constant float3 ASR_BASE = float3(0.08, 0.04, 0.1);
constant float3 ASR_ACCENT = float3(0.85, 0.55, 0.35);

// Maghrib: Deep red collapsing to purple
constant float3 MAGHRIB_BASE = float3(0.12, 0.02, 0.08);
constant float3 MAGHRIB_ACCENT = float3(0.7, 0.2, 0.4);

// Isha: Pure deep blue-black with cyan wisps
constant float3 ISHA_BASE = float3(0.02, 0.02, 0.06);
constant float3 ISHA_ACCENT = float3(0.3, 0.8, 0.9);

// MARK: - Noise Functions

// Permutation polynomial for simplex noise (float3 version)
float3 permute3(float3 x) {
    return fmod(((x * 34.0) + 1.0) * x, 289.0);
}

// Permutation polynomial for simplex noise (float4 version)
float4 permute4(float4 x) {
    return fmod(((x * 34.0) + 1.0) * x, 289.0);
}

// Simplex 3D noise
float simplex3D(float3 v) {
    const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
    const float4 D = float4(0.0, 0.5, 1.0, 2.0);

    // First corner
    float3 i = floor(v + dot(v, C.yyy));
    float3 x0 = v - i + dot(i, C.xxx);

    // Other corners
    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);

    float3 x1 = x0 - i1 + C.xxx;
    float3 x2 = x0 - i2 + C.yyy;
    float3 x3 = x0 - D.yyy;

    // Permutations
    i = fmod(i, 289.0);
    float4 p = permute4(permute4(permute4(
        i.z + float4(0.0, i1.z, i2.z, 1.0))
        + i.y + float4(0.0, i1.y, i2.y, 1.0))
        + i.x + float4(0.0, i1.x, i2.x, 1.0));

    // Gradients: 7x7 points over a square, mapped onto an octahedron
    float n_ = 0.142857142857; // 1.0/7.0
    float3 ns = n_ * D.wyz - D.xzx;

    float4 j = p - 49.0 * floor(p * ns.z * ns.z);

    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_);

    float4 x = x_ * ns.x + ns.yyyy;
    float4 y = y_ * ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);

    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);

    float4 s0 = floor(b0) * 2.0 + 1.0;
    float4 s1 = floor(b1) * 2.0 + 1.0;
    float4 sh = -step(h, float4(0.0));

    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);

    // Normalize gradients
    float4 norm = rsqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// Fractal Brownian Motion with configurable octaves
float fbm(float3 p, int octaves, float persistence, float lacunarity) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * simplex3D(p * frequency);
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    return value / maxValue;
}

// Curl noise for fluid-like movement
float3 curlNoise(float3 p, float epsilon) {
    float3 curl;

    // Compute partial derivatives using central differences
    float n1 = simplex3D(p + float3(0.0, epsilon, 0.0));
    float n2 = simplex3D(p - float3(0.0, epsilon, 0.0));
    float n3 = simplex3D(p + float3(0.0, 0.0, epsilon));
    float n4 = simplex3D(p - float3(0.0, 0.0, epsilon));
    float n5 = simplex3D(p + float3(epsilon, 0.0, 0.0));
    float n6 = simplex3D(p - float3(epsilon, 0.0, 0.0));

    // Curl computation (cross product of gradient)
    curl.x = (n1 - n2 - (n3 - n4)) / (2.0 * epsilon);
    curl.y = (n3 - n4 - (n5 - n6)) / (2.0 * epsilon);
    curl.z = (n5 - n6 - (n1 - n2)) / (2.0 * epsilon);

    return normalize(curl);
}

// MARK: - Prayer Period Color Functions

float3 getPrayerBaseColor(int period) {
    switch (period) {
        case 0: return FAJR_BASE;
        case 1: return SUNRISE_BASE;
        case 2: return DHUHR_BASE;
        case 3: return ASR_BASE;
        case 4: return MAGHRIB_BASE;
        case 5: return ISHA_BASE;
        default: return ISHA_BASE;
    }
}

float3 getPrayerAccentColor(int period) {
    switch (period) {
        case 0: return FAJR_ACCENT;
        case 1: return SUNRISE_ACCENT;
        case 2: return DHUHR_ACCENT;
        case 3: return ASR_ACCENT;
        case 4: return MAGHRIB_ACCENT;
        case 5: return ISHA_ACCENT;
        default: return ISHA_ACCENT;
    }
}

// MARK: - Interaction Functions

// Gravitational well effect at touch position
float gravitationalWell(float2 uv, float2 touchPos, float intensity, float time) {
    float2 delta = uv - touchPos;
    float dist = length(delta);

    // Create gravitational distortion
    float wellStrength = intensity / (dist * dist + 0.01);
    wellStrength = min(wellStrength, 1.0);

    // Add time-based ripple
    float ripple = sin(dist * 20.0 - time * 3.0) * 0.5 + 0.5;
    ripple *= exp(-dist * 4.0);

    return wellStrength * (0.7 + 0.3 * ripple);
}

// Time dilation effect based on scroll velocity
float timeDilation(float time, float scrollVelocity) {
    // Faster scroll = stretched time (slower animation locally)
    float dilation = 1.0 / (1.0 + abs(scrollVelocity) * 0.5);
    return time * dilation;
}

// Scroll-induced fluid stretching
float2 scrollDistortion(float2 uv, float scrollVelocity) {
    float stretch = 1.0 + abs(scrollVelocity) * 0.3;
    float2 distorted = uv;
    distorted.y *= stretch;
    distorted.y += scrollVelocity * 0.1;
    return distorted;
}

// MARK: - Vignette

float vignette(float2 uv, float intensity) {
    float2 centered = uv * 2.0 - 1.0;
    float dist = length(centered);
    return 1.0 - smoothstep(0.5, 1.5, dist) * intensity;
}

// MARK: - Main Dark Matter Effect

float4 darkMatterEffect(float2 uv, constant DarkMatterUniforms &uniforms) {
    // Apply scroll distortion to UV
    float2 distortedUV = scrollDistortion(uv, uniforms.scrollVelocity);

    // Apply time dilation
    float dilatedTime = timeDilation(uniforms.time, uniforms.scrollVelocity);

    // Get prayer period colors
    float3 baseColor = getPrayerBaseColor(uniforms.prayerPeriod);
    float3 accentColor = getPrayerAccentColor(uniforms.prayerPeriod);

    // Clamp noise octaves to safe range
    int octaves = clamp(uniforms.noiseOctaves, 2, 4);

    // Create base position for noise sampling
    float3 noisePos = float3(distortedUV * 2.0, dilatedTime * 0.1);

    // Layer 1: Deep background turbulence
    float noise1 = fbm(noisePos * 0.5, octaves, 0.5, 2.0);
    noise1 = noise1 * 0.5 + 0.5; // Normalize to 0-1

    // Layer 2: Medium detail flow
    float3 curlOffset = curlNoise(noisePos * 0.3, 0.01) * 0.5;
    float noise2 = fbm(noisePos + curlOffset + float3(0.0, 0.0, dilatedTime * 0.05), octaves, 0.6, 2.2);
    noise2 = noise2 * 0.5 + 0.5;

    // Layer 3: Fine detail wisps
    float noise3 = simplex3D(noisePos * 3.0 + curlOffset * 2.0);
    noise3 = noise3 * 0.5 + 0.5;
    noise3 = pow(noise3, 2.0); // Increase contrast for wisps

    // Combine noise layers with density control
    float combinedNoise = mix(noise1, noise2, 0.5);
    combinedNoise = mix(combinedNoise, noise3, 0.3);
    combinedNoise *= uniforms.density;

    // Apply gravitational well if touch is active
    float wellEffect = 0.0;
    if (uniforms.touchIntensity > 0.01) {
        float2 normalizedTouch = uniforms.touchPosition / uniforms.resolution;
        wellEffect = gravitationalWell(uv, normalizedTouch, uniforms.touchIntensity, dilatedTime);

        // Distort noise based on gravitational well
        combinedNoise = mix(combinedNoise, 1.0 - combinedNoise, wellEffect * 0.5);
    }

    // Build color from layers
    float3 color = baseColor;

    // Add accent color based on noise patterns
    float accentMask = smoothstep(0.4, 0.7, combinedNoise);
    color = mix(color, accentColor * 0.5, accentMask * 0.3);

    // Add cyan highlight wisps (signature Event Horizon look)
    float3 cyanHighlight = float3(0.3, 0.8, 0.9);
    float cyanMask = pow(noise3, 3.0) * smoothstep(0.6, 0.9, combinedNoise);
    color += cyanHighlight * cyanMask * 0.15;

    // Add subtle glow from gravitational well
    if (wellEffect > 0.01) {
        float3 wellGlow = accentColor;
        color = mix(color, wellGlow, wellEffect * 0.3);
    }

    // Apply subtle shimmer animation
    float shimmer = sin(dilatedTime * 2.0 + uv.x * 10.0 + uv.y * 8.0) * 0.5 + 0.5;
    shimmer = pow(shimmer, 8.0) * noise3;
    color += accentColor * shimmer * 0.05;

    // Apply vignette
    float vig = vignette(uv, 0.4);
    color *= vig;

    // Ensure color stays in valid range
    color = saturate(color);

    return float4(color, 1.0);
}

// MARK: - Compute Kernel

kernel void darkMatterKernel(
    texture2d<float, access::write> outputTexture [[texture(0)]],
    constant DarkMatterUniforms &uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Check bounds
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }

    // Calculate normalized UV coordinates
    float2 uv = float2(gid) / uniforms.resolution;

    // Generate the dark matter effect
    float4 color = darkMatterEffect(uv, uniforms);

    // Write to output texture
    outputTexture.write(color, gid);
}

// MARK: - Vertex Shader for Full-Screen Quad

vertex VertexOut darkMatterVertex(
    uint vertexID [[vertex_id]]
) {
    // Generate full-screen quad vertices (2 triangles)
    // Vertex positions for a full-screen triangle strip
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

// MARK: - Fragment Shader for Texture Sampling

fragment float4 darkMatterFragment(
    VertexOut in [[stage_in]],
    texture2d<float> computedTexture [[texture(0)]],
    sampler textureSampler [[sampler(0)]]
) {
    // Sample the pre-computed texture
    float4 color = computedTexture.sample(textureSampler, in.texCoord);
    return color;
}

// MARK: - Alternative Direct Fragment Shader (no compute pass)
// Use this for lower-end devices or when compute is not available

fragment float4 darkMatterFragmentDirect(
    VertexOut in [[stage_in]],
    constant DarkMatterUniforms &uniforms [[buffer(0)]]
) {
    // Generate effect directly in fragment shader
    return darkMatterEffect(in.texCoord, uniforms);
}

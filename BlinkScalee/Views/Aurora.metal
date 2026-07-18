//
//  Aurora.metal
//  BlinkScalee
//
//  Metal translation of the WebGL/OGL "Aurora" fragment shader.
//  Exposed as a SwiftUI `colorEffect` stitchable function so it can be
//  applied to a filled Rectangle via `.colorEffect(...)`.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// --- Simplex noise (2D) ---------------------------------------------------

static float3 permute(float3 x) {
    return fmod(((x * 34.0) + 1.0) * x, 289.0);
}

static float snoise(float2 v) {
    const float4 C = float4(0.211324865405187,
                            0.366025403784439,
                           -0.577350269189626,
                            0.024390243902439);
    float2 i  = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = fmod(i, 289.0);
    float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0))
                              + i.x + float3(0.0, i1.x, 1.0));
    float3 m = max(0.5 - float3(dot(x0, x0),
                                dot(x12.xy, x12.xy),
                                dot(x12.zw, x12.zw)),
                   0.0);
    m = m * m;
    m = m * m;
    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    float3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// --- 3-stop color ramp ----------------------------------------------------

static half3 colorRamp(half3 c0, half3 c1, half3 c2, float factor) {
    // Stop positions: c0 @ 0.0, c1 @ 0.5, c2 @ 1.0
    if (factor < 0.5) {
        return mix(c0, c1, half(factor / 0.5));
    } else {
        return mix(c1, c2, half((factor - 0.5) / 0.5));
    }
}

// --- Aurora color effect --------------------------------------------------
//
// Args passed from SwiftUI:
//   size      - view size in pixels (.float2)
//   time      - seconds since start (.float)
//   amplitude - noise amplitude    (.float)
//   blend     - alpha falloff      (.float)
//   c0,c1,c2  - color stops        (.color, arrive as premultiplied half4)

[[ stitchable ]]
half4 aurora(float2 position,
             half4 currentColor,
             float2 size,
             float time,
             float amplitude,
             float blend,
             half4 c0,
             half4 c1,
             half4 c2) {

    // Normalize; flip Y so the aurora sweeps along the bottom like the original
    // (SwiftUI's origin is top-left, WebGL's is bottom-left).
    float2 uv = position / size;
    uv.y = 1.0 - uv.y;

    half3 rampColor = colorRamp(c0.rgb, c1.rgb, c2.rgb, uv.x);

    float height = snoise(float2(uv.x * 2.0 + time * 0.1, time * 0.25)) * 0.5 * amplitude;
    height = exp(height);
    height = (uv.y * 2.0 - height + 0.2);
    float intensity = 0.6 * height;

    float midPoint = 0.20;
    float auroraAlpha = smoothstep(midPoint - blend * 0.5,
                                   midPoint + blend * 0.5,
                                   intensity);

    half3 auroraColor = half(intensity) * rampColor;

    // Premultiplied output, matching the source shader.
    return half4(auroraColor * half(auroraAlpha), half(auroraAlpha));
}

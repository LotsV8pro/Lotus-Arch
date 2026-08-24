#version 440
layout(location = 0) in highp vec2 texCoord;
layout(location = 0) out highp vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float u_time;
    vec2 u_mouse;
    vec2 u_res;
    vec4 u_bg;
    vec4 u_p1;
    vec4 u_p2;
};

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int k = 0; k < 5; k++) {
        v += a * noise(p);
        p *= 2.03;
        a *= 0.55;
    }
    return v;
}

void main() {
    vec2 uv = texCoord;
    float aspect = u_res.x / max(u_res.y, 1.0);
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);

    // depth-layer parallax from mouse
    vec2 par1 = u_mouse * 0.015;
    vec2 par2 = u_mouse * 0.035;

    // base vertical gradient: darker at top
    vec3 col = mix(u_bg.rgb * 0.55, u_bg.rgb, pow(uv.y, 1.35));

    // far aurora bands
    float t = u_time * 0.05;
    float band = fbm(p * 1.6 + vec2(t * 0.6, -t * 0.25) + par1);
    band = smoothstep(0.42, 0.78, band);
    col = mix(col, u_p2.rgb, band * 0.38);

    // near flowing streaks tinted with the accent
    float s = fbm(p * 3.2 + vec2(-t * 1.4, t * 0.35) + par2);
    s = pow(smoothstep(0.48, 0.9, s), 1.6);
    col += u_p1.rgb * s * 0.30;

    // twinkling stars in the upper region
    vec2 sp = uv * vec2(aspect, 1.0) * 90.0;
    vec2 cell = floor(sp);
    float h = hash(cell);
    if (h > 0.995 && uv.y > 0.32) {
        vec2 c = fract(sp) - 0.5;
        float d = length(c);
        float tw = 0.6 + 0.4 * sin(u_time * 2.0 + h * 40.0);
        col += vec3(0.85, 0.85, 0.95)
             * smoothstep(0.18, 0.0, d)
             * tw
             * smoothstep(0.32, 0.62, uv.y);
    }

    // horizon glow near the bottom edge
    float glow = exp(-pow((uv.y - 0.10) * 3.4, 2.0));
    col += u_p1.rgb * glow * 0.22;

    // vignette
    float vig = smoothstep(1.25, 0.45, length(uv - 0.5));
    col *= mix(0.72, 1.0, vig);

    fragColor = vec4(col, 1.0) * qt_Opacity;
}

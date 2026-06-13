// smokescreen theme: pool-party
// Pastel vaporwave pool. A soft pink / peach / aqua / lavender water surface
// with bright cyan-white CAUSTIC shimmer — the same fwidth-isoline trick from
// the distortion cracks, here recoloured and made pervasive so it reads as
// sunlight reflecting off rippling water. CRT/VHS scanlines on top.
//
// Composites behind the terminal text via iChannel0 alpha; needs
// background-opacity < 1.

// --- value noise + fbm ------------------------------------------------------
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0, amp = 0.5;
    for (int i = 0; i < 5; i++) {
        v += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    float t  = iTime * 0.04;   // slow water drift
    float st = iTime * 0.22;   // caustic shimmer speed  [knob]
    vec2 p = uv;
    p.x *= iResolution.x / iResolution.y;
    p *= 1.4;

    // gentle domain warp => the water-surface gradient sloshes
    vec2 q = vec2(fbm(p + vec2(0.0, t)),
                  fbm(p + vec2(5.2, 1.3 - t)));
    vec2 r = vec2(fbm(p + 3.0 * q + vec2(1.7, 9.2) + t * 0.5),
                  fbm(p + 3.0 * q + vec2(8.3, 2.8) - t * 0.5));
    float f = fbm(p + 3.0 * r);

    // --- pastel pool palette (sunset reflected in turquoise water) ---
    vec3 c1 = vec3(0.96, 0.66, 0.80);  // pastel pink
    vec3 c2 = vec3(1.00, 0.82, 0.66);  // peach
    vec3 c3 = vec3(0.40, 0.82, 0.88);  // aqua
    vec3 c4 = vec3(0.66, 0.70, 0.97);  // lavender

    vec3 col = mix(c3, c1, smoothstep(0.10, 0.80, f));
    col = mix(col, c4, smoothstep(0.30, 0.95, r.x));
    col = mix(col, c2, smoothstep(0.25, 0.85, q.y));
    col *= 0.62;   // deeper pastel so bright caustics pop & light text stays readable  [knob]

    // --- caustic shimmer: two crossing animated isolines ---------------------
    vec2 op1 = mat2(1.0, 0.0,  0.7, 1.0) * p; op1 *= vec2(0.6, 1.8);
    vec2 op2 = mat2(1.0, 0.0, -0.7, 1.0) * p; op2 *= vec2(0.6, 1.8);
    float vf1 = fbm(op1 * 2.6 + 1.2 * r + vec2(0.0, st));
    float vf2 = fbm(op2 * 2.6 + 1.2 * r + vec2(9.1, 2.7 - st));
    float d1 = abs(vf1 - 0.5); float w1 = max(fwidth(vf1), 1e-3);
    float d2 = abs(vf2 - 0.5); float w2 = max(fwidth(vf2), 1e-3);
    float caustic = max(1.0 - smoothstep(0.0, w1 * 2.0, d1),
                        1.0 - smoothstep(0.0, w2 * 2.0, d2));   // bright shimmer lines
    float glow    = max(1.0 - smoothstep(0.0, w1 * 7.0, d1),
                        1.0 - smoothstep(0.0, w2 * 7.0, d2));   // soft reflective halo

    // sun-glint: brightness varies across the pool so caustics sparkle unevenly
    float glint = 0.35 + 0.65 * smoothstep(0.35, 0.90, fbm(p * 0.6 + vec2(st * 0.4, 0.0)));

    const vec3 CAUSTIC = vec3(0.80, 1.00, 0.98);  // bright cyan-white reflection
    col += glow    * glint * CAUSTIC * 0.35;
    col += caustic * glint * CAUSTIC * 0.90;

    // soft pastel lift (no dark crush) + gentle vignette
    col = pow(col, vec3(0.92));
    vec2 ce = uv - 0.5;
    col *= 1.0 - dot(ce, ce) * 0.35;

    // --- composite behind the terminal ---
    vec4 term = texture(iChannel0, uv);
    vec3 rgb = mix(col, term.rgb, term.a);   // water where bg, text where glyph
    float a = mix(0.92, 1.0, term.a);        // frosted panel; glyphs fully opaque
    fragColor = vec4(rgb, a);
}

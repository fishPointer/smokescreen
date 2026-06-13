// smokescreen theme: pool-party
// Vaporwave / cosmic-bowling-carpet under a blacklight: a STELLAR dark base
// (deep celestial violet/indigo/teal, not chthonic) lit ambiently by a confetti
// of twinkling neon sparkles, with UV-neon "squiggle" caustics (the fwidth
// isoline shimmer) glowing across it. CRT/VHS scanlines on top.
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

// --- twinkling neon starfield ----------------------------------------------
// One candidate star per grid cell; ~half the cells are lit. Each twinkles on
// its own phase and carries a neon colour, giving that UV-confetti ambient glow.
vec3 starLayer(vec2 sp, float density, float twinkleRate) {
    vec2 g  = sp * density;
    vec2 id = floor(g);
    vec2 fp = fract(g) - 0.5;
    float h = hash(id);
    vec2  off = (vec2(hash(id + 1.7), hash(id + 9.1)) - 0.5) * 0.7;
    float d = length(fp - off);
    float core = smoothstep(0.06, 0.0, d);          // tight point
    float halo = smoothstep(0.34, 0.0, d) * 0.22;   // soft UV bloom
    float present = step(0.55, h);                   // ~45% of cells lit
    float twk = 0.30 + 0.70 * pow(0.5 + 0.5 * sin(iTime * twinkleRate + h * 6.2831), 2.0);
    // neon colour per cell: cyan / magenta / violet
    float hc = hash(id + 4.2);
    vec3 cstar = mix(vec3(0.35, 1.00, 1.00), vec3(1.00, 0.35, 0.90), step(0.45, hc));
    cstar = mix(cstar, vec3(0.70, 0.55, 1.00), step(0.80, hc));
    return (core + halo) * present * twk * cstar;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;

    float t  = iTime * 0.04;   // slow drift
    float st = iTime * 0.06;   // caustic shimmer speed (much slower)  [knob]
    vec2 p = uv;
    p.x *= aspect;
    p *= 1.4;

    // gentle domain warp => the field sloshes
    vec2 q = vec2(fbm(p + vec2(0.0, t)),
                  fbm(p + vec2(5.2, 1.3 - t)));
    vec2 r = vec2(fbm(p + 3.0 * q + vec2(1.7, 9.2) + t * 0.5),
                  fbm(p + 3.0 * q + vec2(8.3, 2.8) - t * 0.5));
    float f = fbm(p + 3.0 * r);

    // --- nighttime: a BLACK void with TRANSLUCENT celestial colour clouds ---
    // density -> opacity (as in radiantmatter-readable): black dominates and the
    // nebula only thickens into view where the warped field is dense.
    vec3 nv = vec3(0.16, 0.05, 0.30);   // deep violet
    vec3 nt = vec3(0.04, 0.16, 0.24);   // deep teal
    vec3 nm = vec3(0.24, 0.06, 0.20);   // deep magenta
    vec3 cloud = mix(nv, nt, smoothstep(0.30, 0.92, r.x));
    cloud = mix(cloud, nm, smoothstep(0.30, 0.85, q.y));

    float dens = smoothstep(0.30, 0.80, f);          // nebula coverage from the field
    const float NEB_GAMMA   = 1.8;   // higher => more of the field falls to black   [knob]
    const float NEB_OPACITY = 0.55;  // densest nebula is still translucent           [knob]
    vec3 col = mix(vec3(0.0), cloud, pow(dens, NEB_GAMMA) * NEB_OPACITY);

    // --- UV-neon squiggle caustics: two crossing animated isolines ---
    vec2 op1 = mat2(1.0, 0.0,  0.7, 1.0) * p; op1 *= vec2(0.6, 1.8);
    vec2 op2 = mat2(1.0, 0.0, -0.7, 1.0) * p; op2 *= vec2(0.6, 1.8);
    float vf1 = fbm(op1 * 2.6 + 1.2 * r + vec2(0.0, st));
    float vf2 = fbm(op2 * 2.6 + 1.2 * r + vec2(9.1, 2.7 - st));
    float d1 = abs(vf1 - 0.5); float w1 = max(fwidth(vf1), 1e-3);
    float d2 = abs(vf2 - 0.5); float w2 = max(fwidth(vf2), 1e-3);
    float caustic = max(1.0 - smoothstep(0.0, w1 * 2.0, d1),
                        1.0 - smoothstep(0.0, w2 * 2.0, d2));
    float glow    = max(1.0 - smoothstep(0.0, w1 * 7.0, d1),
                        1.0 - smoothstep(0.0, w2 * 7.0, d2));
    float glint = 0.35 + 0.65 * smoothstep(0.35, 0.90, fbm(p * 0.6 + vec2(st * 0.4, 0.0)));
    vec3 neon = mix(vec3(0.35, 1.00, 1.00), vec3(1.00, 0.35, 0.85), smoothstep(0.3, 0.7, q.y));
    col += glow    * glint * neon * 0.15;   // shimmer activity reduced ~30%
    col += caustic * glint * neon * 0.46;

    // --- twinkling starfield (two depths) drifting slowly ---
    vec2 sp = uv * vec2(aspect, 1.0);
    vec3 stars  = starLayer(sp + vec2(iTime * 0.004, 0.0), 55.0, 2.4);
    stars      += starLayer(sp * 1.9 + vec2(-iTime * 0.006, 3.3), 95.0, 3.6) * 0.7;
    col += stars * 1.5;

    // gentle vignette
    vec2 ce = uv - 0.5;
    col *= 1.0 - dot(ce, ce) * 0.4;

    // --- composite behind the terminal ---
    vec4 term = texture(iChannel0, uv);
    vec3 rgb = mix(col, term.rgb, term.a);   // field where bg, text where glyph
    float a = mix(0.92, 1.0, term.a);        // frosted panel; glyphs fully opaque
    fragColor = vec4(rgb, a);
}

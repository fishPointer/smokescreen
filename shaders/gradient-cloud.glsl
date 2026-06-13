// Animated pastel "color cloud" background for Ghostty.
// A domain-warped FBM mesh-gradient (Stripe-banner vibe, dark-mode palette)
// painted BEHIND the terminal text. The terminal arrives as iChannel0; its
// alpha is the text mask, so glyphs stay crisp on top of the cloud.
//
// Requires background-opacity < 1 in config so background cells are
// transparent (alpha ~0) and the cloud shows through.

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

    // slow, evolving time + aspect-corrected sample space
    float t = iTime * 0.04;
    vec2 p = uv;
    p.x *= iResolution.x / iResolution.y;
    p *= 1.4;

    // --- domain warp: fbm of fbm of fbm => flowing cloud ---
    vec2 q = vec2(fbm(p + vec2(0.0, t)),
                  fbm(p + vec2(5.2, 1.3 - t)));
    vec2 r = vec2(fbm(p + 4.0 * q + vec2(1.7, 9.2) + t * 0.5),
                  fbm(p + 4.0 * q + vec2(8.3, 2.8) - t * 0.5));
    float f = fbm(p + 4.0 * r);

    // --- chthonic palette: obsidian, oxblood, plum, deep verdigris ---
    vec3 c1 = vec3(0.020, 0.018, 0.045); // obsidian indigo (near-black)
    vec3 c2 = vec3(0.180, 0.030, 0.055); // deep oxblood
    vec3 c3 = vec3(0.090, 0.025, 0.140); // dark plum/violet
    vec3 c4 = vec3(0.020, 0.090, 0.090); // deep verdigris (mineral teal)

    vec3 col = mix(c1, c2, smoothstep(0.05, 0.70, f));
    col = mix(col, c3, smoothstep(0.30, 0.95, r.x));
    col = mix(col, c4, smoothstep(0.25, 0.90, q.y));

    // molten ember glints rising from the deep — gated to the brightest
    // filaments so the field stays dark but rich, with veins of heat
    float ember = smoothstep(0.72, 1.0, f) * smoothstep(0.6, 1.0, r.x);
    col += ember * vec3(0.55, 0.20, 0.04);

    // keep the floor truly dark (crush the lowest values toward black)
    col = pow(col, vec3(1.15));

    // gentle vignette so edges sink into shadow
    vec2 ce = uv - 0.5;
    col *= 1.0 - dot(ce, ce) * 0.7;

    // --- composite behind the terminal ---
    vec4 term = texture(iChannel0, uv);
    vec3 rgb = mix(col, term.rgb, term.a);     // cloud where bg, text where glyph
    float a = mix(0.92, 1.0, term.a);          // frosted panel; glyphs fully opaque
    fragColor = vec4(rgb, a);
}

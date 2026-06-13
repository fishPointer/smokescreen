// smokescreen theme: distortion
// Giratina / Distortion-World vibe: a dark, domain-warped void threaded with
// glowing molten amber-gold VEINS that are sparse, intense, glittering, and
// fleeting. Built on the chthonic gradient-cloud base; the cloud is pushed
// darker so the veins are the focal heat.
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

    // slow field drift; fast effects key off iTime directly (glitter/pulse)
    float t = iTime * 0.05;
    vec2 p = uv;
    p.x *= iResolution.x / iResolution.y;
    p *= 1.4;

    // --- domain warp: fbm of fbm of fbm => flowing distortion ---
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

    col *= 0.65;   // push the void darker so the veins dominate  [knob]

    // --- discharging amber veins ---------------------------------------------
    // Oblique, sheared + stretched sample space => acute diagonal STREAKS rather
    // than round dispersed pools; reduced warp keeps the filaments taut.
    vec2 op = mat2(1.0, 0.0, 0.7, 1.0) * p;          // horizontal shear (oblique)
    op *= vec2(0.55, 2.1);                            // stretch into streaks
    float vf = fbm(op * 2.2 + 1.4 * r + vec2(0.0, t * 0.4));
    float ridgeBand = 1.0 - abs(2.0 * vf - 1.0);     // bright where vf ~ 0.5
    float vein = pow(ridgeBand, 9.0);                // sharp taut filaments
    float halo = pow(ridgeBand, 4.0);                // tighter glow (less dispersion)

    // Sparse hosting — baseline density, slightly thinned.  [knob]
    float pocket = smoothstep(0.62, 0.92, fbm(p * 0.7 + vec2(t * 0.05, -t * 0.05)));

    // Activation hot-zones: only a slow-drifting subset of the field is ever
    // "live" at once, so the TOTAL phase density (how much is active anywhere on
    // screen) stays low even though every pocket carries its own clock. This is
    // the master knob for overall activity.  [knob]
    float active = smoothstep(0.52, 0.80, fbm(p * 0.45 + vec2(t * 0.08, -t * 0.05)));

    // Per-region clock, STRONGLY decorrelated in space so discharges are
    // isolated local events (no screen-wide synchronized pulse). Slow rate
    // => infrequent.  [knobs]
    float region = fbm(p * 1.3 + 31.7);
    float phase  = fract(iTime * 0.24 + region * 8.0);

    // AR envelope: a SLOW, subtle wind-up (charging) across the whole cycle,
    // then a brief gentle snap at the crest, then dark.
    float windup = smoothstep(0.0, 0.95, phase) * 0.10;    // [knob: charge glow]
    float snap   = pow(smoothstep(0.90, 1.0, phase), 3.0); // [knob: snap window]
    float arc    = windup + snap;

    // acute travelling spike keeps each discharge directional along the streak
    float bolt = pow(0.5 + 0.5 * sin(vf * 13.0 - iTime * 5.0), 6.0);

    float life = pocket * active * arc;

    // Glitter: fast high-frequency sparks riding the filaments.
    float spark = noise(op * 40.0 + vec2(iTime * 4.0, iTime * 3.0));
    spark = pow(smoothstep(0.86, 1.0, spark), 2.0);
    float glitter = spark * vein * pocket * active;

    const vec3 AMBER = vec3(1.00, 0.50, 0.10);
    const vec3 GOLD  = vec3(1.00, 0.88, 0.58);

    col += halo * life                 * AMBER * 0.30;  // faint charging haze
    col += vein * life                 * AMBER * 1.10;  // filament cores (subtler)
    col += vein * pocket * snap * bolt * GOLD  * 0.60;  // gentle crack at the snap
    col += glitter                     * GOLD  * 1.60;  // sparkle (subtler)

    // keep the floor truly dark (crush the lowest values toward black)
    col = pow(col, vec3(1.20));

    // vignette so edges sink into shadow
    vec2 ce = uv - 0.5;
    col *= 1.0 - dot(ce, ce) * 0.7;

    // --- composite behind the terminal ---
    vec4 term = texture(iChannel0, uv);
    vec3 rgb = mix(col, term.rgb, term.a);     // field where bg, text where glyph
    float a = mix(0.92, 1.0, term.a);          // frosted panel; glyphs fully opaque
    fragColor = vec4(rgb, a);
}

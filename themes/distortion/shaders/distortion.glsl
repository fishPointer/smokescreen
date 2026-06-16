const float S_LOOP = 3600.0; // smokescreen: wrap iTime (~60min loop) to avoid float32 precision jitter
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

// --- freeze toggle (smokescreen) -------------------------------------------
// FREEZE_FRAME >= 0.0 pins the shader clock to that single frame -- a static
// render. Pair it with `custom-shader-animation = false` so Ghostty also stops
// its continuous redraw loop. A negative value keeps the shader live/animated.
// (crt-bloom.glsl has no iTime, so it needs no toggle.)  See README -> Freezing.
const float FREEZE_FRAME = -1.0;
float sceneTime() { return FREEZE_FRAME >= 0.0 ? FREEZE_FRAME : iTime; }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float iTime = sceneTime();  // freeze toggle: shadows the live iTime uniform
    vec2 uv = fragCoord / iResolution.xy;

    // slow field drift; fast effects key off iTime directly (glitter/pulse)
    float t = mod(iTime, S_LOOP) * 0.05;
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

    // --- glowing amber veins -------------------------------------------------
    // Filament structure: ridged contours of a finer warped field.
    float vf = fbm(p * 2.3 + 3.0 * r + vec2(0.0, t * 0.4));
    float ridgeBand = 1.0 - abs(2.0 * vf - 1.0);     // bright where vf ~ 0.5
    float vein = pow(ridgeBand, 8.0);                // SHARP thin filaments
    float halo = pow(ridgeBand, 2.5);                // soft glow around them

    // Sparse: veins only host in some low-frequency pockets.  [knob]
    float pocket = smoothstep(0.58, 0.92, fbm(p * 0.7 + vec2(t * 0.05, -t * 0.05)));

    // Fleeting: a traveling pulse + a drifting on/off envelope so veins flare
    // up and die rather than sitting static.
    float pulse = 0.5 + 0.5 * sin(vf * 9.0 - mod(iTime, S_LOOP) * 1.3);
    float onoff = smoothstep(0.32, 0.85, fbm(p * 1.0 + vec2(-mod(iTime, S_LOOP) * 0.06, mod(iTime, S_LOOP) * 0.05)));
    float life  = pocket * pulse * onoff;

    // Glitter: fast high-frequency sparks riding the filaments.
    float spark = noise(p * 36.0 + vec2(mod(iTime, S_LOOP) * 2.6, mod(iTime, S_LOOP) * 1.9));
    spark = pow(smoothstep(0.84, 1.0, spark), 2.0);
    float glitter = spark * vein * pocket;

    const vec3 AMBER = vec3(1.00, 0.50, 0.10);
    const vec3 GOLD  = vec3(1.00, 0.88, 0.58);

    col += halo  * life    * AMBER * 0.45;   // amber haze around veins
    col += vein  * life    * AMBER * 1.70;   // the molten filament cores
    col += glitter         * GOLD  * 2.40;   // hot gold sparkle

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

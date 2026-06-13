const float S_LOOP = 3600.0; // smokescreen: wrap iTime (~60min loop) to avoid float32 precision jitter
// smokescreen theme: deoxys
// The DNA Pokémon. A rotating crystalline DOUBLE HELIX down the center with a
// pulsing psychic core and radial energy spikes, washed in an iridescent
// (Iñigo-Quilez cosine) palette over a dark psychic void.
//
// New steps vs the rest of the collection:
//   * a central GEOMETRIC focal structure (helix) instead of full-field noise
//   * POLAR/radial corona spikes from the core
//   * iridescent hue-cycling palette
//   * FORME-MORPHING: the shader cycles Deoxys' four formes (Normal / Attack /
//     Defense / Speed), each a distinct geometry+hue, and fires a chromatic-
//     aberration "mutation" glitch at every forme change.
//
// Composites behind the terminal text via iChannel0 alpha; needs bg-opacity < 1.

#define PI 3.14159265

// --- value noise + fbm (faint background nebula) ---------------------------
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
    for (int i = 0; i < 4; i++) { v += amp * noise(p); p *= 2.0; amp *= 0.5; }
    return v;
}

// --- iridescent cosine palette (IQ) ----------------------------------------
vec3 pal(float t) {
    vec3 a  = vec3(0.50, 0.45, 0.55);
    vec3 b  = vec3(0.50, 0.45, 0.45);
    vec3 cc = vec3(1.00, 1.00, 1.00);
    vec3 d  = vec3(0.00, 0.20, 0.60);   // sweeps orange-red -> teal -> violet
    return a + b * cos(6.28318 * (cc * t + d));
}

// --- forme parameter sets: vec4(amp, twist, spikes, hueOffset) --------------
// Normal (balanced) / Attack (wide, spiky, hot) / Defense (tight, dense rays,
// teal) / Speed (fast twist, sparse rays, violet).
vec4 formeParams(float n) {
    n = mod(n, 4.0);
    vec4 A = vec4(0.16,  7.0,  3.0, 0.00);
    vec4 B = vec4(0.30, 10.0,  7.0, 0.08);
    vec4 C = vec4(0.09,  5.0, 12.0, 0.52);
    vec4 D = vec4(0.22, 16.0,  2.0, 0.78);
    float s1 = step(0.5, n), s2 = step(1.5, n), s3 = step(2.5, n);
    return A + (B - A) * s1 + (C - B) * s2 + (D - C) * s3;
}

// --- DNA double helix: two strands + depth + beads + rungs ------------------
float helix(vec2 c, float amp, float twist, float beadK, float time) {
    float ph = c.y * twist + time * 1.5;
    float sA = amp * sin(ph);          // strand A x-position
    float sB = -sA;                    // strand B (opposite)
    float dA = 0.5 + 0.5 * cos(ph);    // A "in front" weight
    float dB = 1.0 - dA;
    float bead = pow(0.5 + 0.5 * sin(c.y * beadK + time * 1.5), 2.0);
    float wA = mix(0.006, 0.022, dA);  // front strand is thicker/brighter
    float wB = mix(0.006, 0.022, dB);
    float gA = smoothstep(wA, 0.0, abs(c.x - sA)) * (0.35 + 0.65 * dA) * bead;
    float gB = smoothstep(wB, 0.0, abs(c.x - sB)) * (0.35 + 0.65 * dB) * bead;
    // rungs where the strands are at maximum separation (side-on view)
    float rungAt = smoothstep(0.86, 1.0, abs(sin(ph)));
    float rung = rungAt * (1.0 - smoothstep(amp * 0.92, amp, abs(c.x))) * 0.5;
    return gA + gB + rung;
}

// --- polar corona: radial psychic spikes from the core ---------------------
float corona(vec2 c, float spikes, float time) {
    float r = length(c);
    float a = atan(c.y, c.x);
    float ray = pow(0.5 + 0.5 * cos(a * spikes + time * 2.0), 6.0);
    return ray * smoothstep(0.55, 0.05, r) * 0.6;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float time = mod(iTime, S_LOOP);
    vec2 uv = fragCoord / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    vec2 c = uv - 0.5;
    c.x *= aspect;

    // --- forme morph: hold a forme, then morph to the next near the end ---
    const float FORME_PERIOD = 16.0;            // seconds per forme  [knob]
    float fp = time / FORME_PERIOD;
    float fi = floor(fp);
    float ff = fract(fp);
    float morphAmt = smoothstep(0.82, 1.0, ff);
    vec4 P = mix(formeParams(fi), formeParams(fi + 1.0), morphAmt);
    float amp = P.x, twist = P.y, spikes = P.z, hueOff = P.w;
    // mutation glitch: spikes right as a new forme arrives, then decays
    float trans = 1.0 - smoothstep(0.0, 0.10, ff);

    // chromatic aberration offset during the mutation
    float off = trans * 0.035;
    float beadK = 40.0;

    float fR = helix(c - vec2(off, 0.0), amp, twist, beadK, time) + corona(c - vec2(off, 0.0), spikes, time);
    float fG = helix(c, amp, twist, beadK, time)                  + corona(c, spikes, time);
    float fB = helix(c + vec2(off, 0.0), amp, twist, beadK, time) + corona(c + vec2(off, 0.0), spikes, time);

    // --- background: dark psychic nebula ---
    float neb = fbm(c * 1.6 + vec2(0.0, time * 0.05));
    vec3 bg = mix(vec3(0.010, 0.010, 0.030), vec3(0.050, 0.020, 0.110),
                  smoothstep(0.30, 0.85, neb)) * 0.55;

    // iridescent helix/corona colour (cycles along y, by forme, and slowly in time)
    vec3 ir = pal(c.y * 0.35 + hueOff + time * 0.04);
    vec3 col = bg + ir * vec3(fR, fG, fB);

    // --- pulsing white-hot core + iridescent halo ---
    float r = length(c);
    float pulse = 0.8 + 0.2 * sin(time * 3.0);
    col += vec3(1.0, 0.95, 1.0) * smoothstep(0.10 * pulse, 0.0, r);
    col += pal(time * 0.10 + 0.20) * smoothstep(0.24, 0.0, r) * 0.25;

    // mutation flash
    col += vec3(0.6, 0.5, 0.8) * trans * 0.5;

    // vignette + slight global dim
    col *= 1.0 - dot(c, c) * 0.25;
    col *= 0.90;

    // --- composite behind the terminal ---
    vec4 term = texture(iChannel0, uv);
    vec3 rgb = mix(col, term.rgb, term.a);
    float a = mix(0.90, 1.0, term.a);
    fragColor = vec4(rgb, a);
}

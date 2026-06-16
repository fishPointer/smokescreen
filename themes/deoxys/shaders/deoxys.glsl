const float S_LOOP = 3600.0; // smokescreen: wrap iTime (~60min loop) to avoid float32 precision jitter
// smokescreen theme: deoxys
// The DNA Pokémon — the alien that fell to earth in a meteor. Rebuilt as a DEEP
// VOID SPACE SCENE: a near-black sky dusted with a multi-coloured twinkling
// starfield, a slow psychic nebula (jirachi's domain-warped fBm cloud recoloured
// to Deoxys violet/teal), and TWO foreground bodies —
//   * a large looming PLANET (bottom-right): dark night side, a warm coral-lit
//     crescent with drifting cloud bands, and a cyan atmosphere rim.
//   * the DEOXYS CORE: a faceted, slowly-rotating, pulsing crystal gem (upper-
//     left) with an iridescent IQ-cosine body, cyan rim, and a white-hot heart.
//
// (The rotating DNA double-helix / forme-morph of the previous version is gone.)
//
// Composites behind the terminal text via iChannel0 alpha; needs bg-opacity < 1.

#define PI 3.14159265

// --- Ashima Arts 3D simplex noise (same backbone as jirachi/rayquaza) -------
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x * 34.0) + 10.0) * x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
  const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
  vec3 i = floor(v + dot(v, C.yyy));
  vec3 x0 = v - i + dot(i, C.xxx);
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy;
  vec3 x3 = x0 - D.yyy;
  i = mod289(i);
  vec4 p = permute(permute(permute(
    i.z + vec4(0.0, i1.z, i2.z, 1.0))
    + i.y + vec4(0.0, i1.y, i2.y, 1.0))
    + i.x + vec4(0.0, i1.x, i2.x, 1.0));
  float n_ = 0.142857142857;
  vec3 ns = n_ * D.wyz - D.xzx;
  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_);
  vec4 x = x_ * ns.x + ns.yyyy;
  vec4 y = y_ * ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);
  vec4 s0 = floor(b0) * 2.0 + 1.0;
  vec4 s1 = floor(b1) * 2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
  vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
  p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}
float fbm(vec3 p) { return snoise(p) * 0.667 + snoise(p * 2.0) * 0.333; }

// --- 2D hash + a MULTI-COLOURED twinkling starfield (jirachi's, recoloured) --
float h21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}
// Returns an already-tinted star contribution; each star cell picks one of a
// small palette of colours by hash (mostly white-blue, some cyan/violet/coral).
vec3 starsCol(vec2 g, float density, float tw) {
    vec2 gp = g * density;
    vec2 id = floor(gp);
    vec2 fp = fract(gp) - 0.5;
    float hh = h21(id);
    vec2 off = (vec2(h21(id + 1.7), h21(id + 9.1)) - 0.5) * 0.7;
    float d = length(fp - off);
    float core = smoothstep(0.055, 0.0, d);
    float present = step(0.86, hh);                  // sparse
    float twk = 0.50 + 0.85 * pow(0.5 + 0.5 * sin(mod(iTime, S_LOOP) * tw + hh * 6.2831), 1.7);
    float ch = h21(id + 13.7);                        // colour selector  [knob: thresholds]
    vec3 tint = ch < 0.55 ? vec3(0.80, 0.90, 1.00)   // white-blue (most common)
              : ch < 0.74 ? vec3(0.45, 0.90, 1.00)   // cyan
              : ch < 0.88 ? vec3(0.85, 0.55, 1.00)   // violet
              :             vec3(1.00, 0.65, 0.45);  // warm coral
    return core * present * twk * tint;
}

// --- crystal SDF: a hexagonal prism intersected with an elongated octahedron
// (the octa supplies the pointed quartz tips), raymarched for a true 3D look ---
float sdHexPrism(vec3 p, vec2 h) {
  const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
  p = abs(p);
  p.xy -= 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy;
  vec2 d = vec2(
      length(p.xy - vec2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x),
      p.z - h.y);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}
float sdOctahedron(vec3 p, float s) { p = abs(p); return (p.x + p.y + p.z - s) * 0.57735027; }

// Crystal centred at origin, long axis = y, spun about the VERTICAL (y) axis.
float mapCrystal(vec3 p, float rot) {
  float c = cos(rot), s = sin(rot);
  p.xz = mat2(c, -s, s, c) * p.xz;                 // rotate about vertical axis
  // slender double-terminated hexagonal spire (hex sides + pointed tips)
  float prism = sdHexPrism(vec3(p.x, p.z, p.y), vec2(0.34, 3.0));
  vec3 q = p; q.y *= 0.50;                          // elongate octahedron -> sharp tips
  float spire = max(prism, sdOctahedron(q, 0.66));
  // a fatter octahedral CORE gem bulging at the girdle (Deoxys' core)
  float core = sdOctahedron(p, 0.46);
  return min(spire, core);                          // union -> spire wearing a core gem
}
vec3 nCrystal(vec3 p, float rot) {
  vec2 e = vec2(0.0009, 0.0);
  return normalize(vec3(
    mapCrystal(p + e.xyy, rot) - mapCrystal(p - e.xyy, rot),
    mapCrystal(p + e.yxy, rot) - mapCrystal(p - e.yxy, rot),
    mapCrystal(p + e.yyx, rot) - mapCrystal(p - e.yyx, rot)));
}

// --- deoxys palette ---------------------------------------------------------
const vec3 VOID   = vec3(0.006, 0.008, 0.020);  // deep black void
const vec3 VIOLET = vec3(0.150, 0.055, 0.230);  // psychic violet (back nebula)
const vec3 TEAL   = vec3(0.040, 0.220, 0.260);  // teal (front nebula)
const vec3 CYAN   = vec3(0.220, 0.560, 0.680);  // brighter sheen
const vec3 DXR    = vec3(0.900, 0.260, 0.150);  // deoxys red-orange (crystal faces)
const vec3 DXT    = vec3(0.100, 0.620, 0.600);  // deoxys teal (accents / fresnel rim)
const vec3 DXV    = vec3(0.420, 0.160, 0.540);  // deoxys violet (crystal in shadow)
const vec3 DXG    = vec3(0.430, 0.460, 0.520);  // deoxys cool gray (extremities / base)

// --- freeze toggle (smokescreen) -------------------------------------------
// FREEZE_FRAME >= 0.0 pins the shader clock to that single frame -- a static
// render. Pair it with `custom-shader-animation = false` so Ghostty also stops
// its continuous redraw loop. A negative value keeps the shader live/animated.
// (crt-bloom.glsl has no iTime, so it needs no toggle.)  See README -> Freezing.
const float FREEZE_FRAME = -1.0;
float sceneTime() { return FREEZE_FRAME >= 0.0 ? FREEZE_FRAME : iTime; }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float iTime = sceneTime();  // freeze toggle: shadows the live iTime uniform
  vec2 suv = fragCoord / iResolution.xy;
  float aspect = iResolution.x / iResolution.y;
  const float SPEED = 1.0;                  // overall time scale  [knob]
  float time = mod(iTime, S_LOOP) * SPEED;
  float t = time * 0.012;                    // calm nebula drift

  vec2 P = vec2(suv.x * aspect, suv.y);      // aspect-corrected scene coords

  // ===================== PARTICLE TIMING (shared by lens + ribbon) =========
  const float FLIGHT_S = 2.0;    // [knob] crossing time (propagation speed)
  // wish timer: a random gap in [30,60]s each cycle. Fixed 45s cells with a
  // hashed +/-7.5s start offset make consecutive gaps land in [30,60].  [knob: CELL]
  const float CELL = 45.0;
  float c0 = floor(time / CELL);
  float startC = c0 * CELL + (h21(vec2(c0, 11.0)) - 0.5) * 15.0;
  float cyc = (time >= startC) ? c0 : (c0 - 1.0);    // index of the current/last wish
  float startE = cyc * CELL + (h21(vec2(cyc, 11.0)) - 0.5) * 15.0;
  float ph = time - startE;                           // seconds since this wish started
  float ang   = h21(vec2(cyc, 7.0)) * 6.2831;          // random heading per release
  float phase = h21(vec2(cyc, 3.0)) * 6.2831;          // random weave phase
  vec2  Dd = vec2(cos(ang), sin(ang));
  vec2  Nn = vec2(-Dd.y, Dd.x);
  float Ldiag = sqrt(aspect * aspect + 1.0);
  float Lpath = Ldiag * 1.15;
  vec2  Apath = vec2(aspect * 0.5, 0.5) - Dd * (Lpath * 0.5);
  float drawT = clamp(ph / FLIGHT_S, 0.0, 1.0);
  float headU = drawT * Lpath;
  vec2  Hpos = Apath + Dd * headU;                     // particle head = lens core
  float headLife = 1.0 - smoothstep(FLIGHT_S, FLIGHT_S + 0.6, ph);

  // ===================== GRAVITATIONAL LENS around the core ================
  const float LENS_STR = 0.030;  // [knob] deflection strength
  const float LRAD     = 0.075;  // [knob] lens radius
  vec2  dh = P - Hpos;
  float rh = length(dh);
  float lensMag = LENS_STR * exp(-rh * rh / (2.0 * LRAD * LRAD)) * headLife;
  vec2  lensDisp = (rh > 1e-4 ? dh / rh : vec2(0.0)) * lensMag; // bend the field toward the core
  vec2  lensDispUV = vec2(lensDisp.x / aspect, lensDisp.y);
  vec2  Pl = P + lensDisp;                              // warped coord for the procedural field

  vec2 ac = Pl;

  // --- psychic nebula: jirachi's two-layer domain-warped cloud, deoxys hues --
  vec2 q = vec2(snoise(vec3(ac, t)),
                snoise(vec3(ac + vec2(3.1, 1.7), t)));
  vec2 r = vec2(snoise(vec3(ac + q * 0.6 + vec2(1.7, 9.2), t * 0.5)),
                snoise(vec3(ac + q * 0.6 + vec2(8.3, 2.8), t * 0.5)));
  vec2 wuv = ac + r * 0.45;

  vec3 col = VOID;

  float s1 = fbm(vec3(wuv * 1.1 + vec2(0.0, 5.0), t * 0.6));
  float vis1 = smoothstep(0.12, 0.62, s1);
  vec3 c1 = mix(VOID, VIOLET, smoothstep(0.18, 0.72, s1));
  col = mix(col, c1, pow(vis1, 1.6) * 0.32);            // back violet haze  [knob]

  float s2 = fbm(vec3(wuv * 1.9 + vec2(4.0, 0.0), t * 0.9 + 20.0));
  float vis2 = smoothstep(0.28, 0.72, s2);
  vec3 c2 = mix(TEAL, CYAN, smoothstep(0.46, 0.86, s2));
  col = mix(col, c2, pow(vis2, 2.2) * 0.20);            // front teal filaments  [knob]

  // --- ergonomic tuning (saturation / dim / luminance ceiling) ------------
  const float SATURATION = 0.90;            // [knob]
  float gray = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(vec3(gray), col, SATURATION);
  col *= 0.55;                              // overall dim   [knob]
  float lum = dot(col, vec3(0.299, 0.587, 0.114));
  float ceiling = 0.13;                     // brightness cap [knob]
  col *= ceiling / max(lum, ceiling);

  // --- multi-coloured starfield (after the ceiling, so crisp; lensed too) -
  vec2 sg = Pl;
  col += starsCol(sg, 60.0, 1.1) * 0.85;
  col += starsCol(sg * 1.7 + 4.0, 110.0, 1.6) * 0.60;

#if 0  // --- bouncing crystal: temporarily disabled (kept for later) ---------
  // ===================== FOREGROUND: the CORE CRYSTAL ======================
  // Deoxys' core as a true 3D hexagonal-prism crystal, raymarched and spinning
  // about the vertical axis, drifting around the screen like a DVD-logo
  // screensaver (constant speed, reflecting off the edges). Deoxys-coloured:
  // red-orange faces <-> teal, violet in shadow, teal fresnel rim, aqua heart.
  float CORE_SCALE = 0.062;                  // [knob] crystal size (screen units per local unit)
  // DVD bounce: triangle waves give constant-speed travel + hard reflections.
  float mX = CORE_SCALE * 1.6, mY = CORE_SCALE * 1.6;          // edge margins (stay fully on-screen)
  float rangeX = aspect - 2.0 * mX, rangeY = 1.0 - 2.0 * mY;
  const float DVD_SPEED = 0.085;             // [knob] travel speed (screen units / sec)
  float vx = DVD_SPEED / (2.0 * rangeX), vy = DVD_SPEED / (2.0 * rangeY);
  float triX = abs(2.0 * fract(time * vx + 0.13) - 1.0);
  float triY = abs(2.0 * fract(time * vy + 0.41) - 1.0);
  vec2  cpos = vec2(mX + rangeX * triX, mY + rangeY * triY);   // bouncing crystal centre
  vec2  luv = (P - cpos) / CORE_SCALE;       // local orthographic plane
  vec3  crystalCol = vec3(0.0);
  float crystalCov = 0.0;
  if (dot(luv, luv) < 2.56) {                // bounding circle (radius 1.6) — skip elsewhere
    float rot = time * 1.6;                   // [knob] vertical-axis spin speed
    vec3 ro = vec3(luv, 1.6);                 // orthographic ray origin
    vec3 rd = vec3(0.0, 0.0, -1.0);
    float tt = 0.0, dd = 1.0;
    vec3 pp = ro;
    for (int i = 0; i < 72; i++) {
      pp = ro + rd * tt;
      dd = mapCrystal(pp, rot);
      if (dd < 0.0006) break;
      tt += dd;
      if (tt > 3.2) break;
    }
    float cov = 1.0 - smoothstep(0.0006, 0.012, dd);  // soft anti-aliased edge
    if (cov > 0.0) {
      vec3 n = nCrystal(pp, rot);
      vec3 Lc = normalize(vec3(-0.40, 0.55, 0.80));
      float diff = max(dot(n, Lc), 0.0);
      float fres = pow(1.0 - max(dot(n, -rd), 0.0), 3.0);       // facet edges
      float spec = pow(max(dot(reflect(-Lc, n), -rd), 0.0), 28.0);
      // body-space point (un-spin) -> SOLID Deoxys colour zones painted on the body
      float cc = cos(rot), ss = sin(rot);
      vec3 bp = pp; bp.xz = mat2(cc, -ss, ss, cc) * bp.xz;
      vec3 zone = mix(DXG, DXR, smoothstep(-0.18, 0.18, bp.y));  // gray base -> red-orange spire
      zone = mix(zone, DXT, smoothstep(0.50, 0.34, length(bp))); // teal core gem in the middle
      float shade = 0.42 + 0.58 * diff;                          // solid: ambient floor + diffuse
      crystalCol  = zone * shade;
      crystalCol += DXT * fres * 0.16;                           // faint teal edge (much reduced)
      crystalCol += vec3(1.00, 0.98, 0.95) * spec * 0.22;        // small glint, not a glow
      crystalCov  = cov;
    }
  }
  col = mix(col, crystalCol, crystalCov);                        // opaque solid body
  // way less radiance: a tiny aqua core shine gated to the body + a whisper of halo
  col += vec3(0.40, 0.90, 0.85) * exp(-dot(luv, luv) * 16.0) * crystalCov * 0.10;
  col += DXT * exp(-dot(luv, luv) * 3.0) * 0.03;
#endif

  // ===================== DNA / PCB DIFFERENTIAL-PAIR PARTICLE ===============
  // A small ephemeral particle streaks across (random heading) on a random
  // 30-60s cadence, drawing a pair of flat, fixed-width solid ribbons (orange +
  // blue) that snake
  // like a PCB differential pair and weave like a DNA double helix. The trail
  // decays fast behind the head (tuned to the propagation speed), then hangs on a
  // low, near-transparent asymptote for ~2s before vanishing.
  const float AMP   = 0.011;  // [knob] weave amplitude (small particle)
  const float HALFW = 0.0022; // [knob] ribbon half-width at the head (tapers along the tail)
  const float KK    = 80.0;   // [knob] meander frequency along the path
  const float TAU   = 0.28;   // [knob] trail decay time -> short, aggressive taper
  float wake = 0.0;           // CA-wake weight (also used at composite)
  {                                                       // particle ribbon block
    vec3 ORANGE = vec3(1.00, 0.45, 0.12);
    vec3 BLUE   = vec3(0.15, 0.55, 1.00);
    float u = dot(P - Apath, Dd);                          // along the path
    float v = dot(P - Apath, Nn);                          // perpendicular
    float aa = 0.0007;
    float ww = tanh(2.2 * sin(u * KK + phase)) / tanh(2.2);// squared (PCB-like) meander
    float so = AMP * ww;                                   // orange strand offset
    float sb = -so;                                        // blue strand (anti-phase) -> weave
    float phU = (u / Lpath) * FLIGHT_S;                    // time the head passed this u
    float age = ph - phU;                                  // seconds since drawn here
    float passed = step(0.0, u) * step(u, Lpath) * step(u, headU);
    float tail = exp(-max(age, 0.0) / TAU);                // aggressive exponential fade
    float hw = HALFW * (0.12 + 0.88 * tail);               // width tapers to a point along the tail
    float amp = tail * passed;
    float ro = (1.0 - smoothstep(hw - aa, hw, abs(v - so))) * amp;
    float rb = (1.0 - smoothstep(hw - aa, hw, abs(v - sb))) * amp;
    float m = floor((u * KK + phase) / 3.14159265);        // half-period index -> over/under
    if (mod(m, 2.0) < 0.5) { col = mix(col, BLUE, rb); col = mix(col, ORANGE, ro); }
    else                   { col = mix(col, ORANGE, ro); col = mix(col, BLUE, rb); }
    // bright leading head (only while the particle is flying)
    float hx = (u - headU) / 0.006;
    float hd = exp(-hx * hx) * passed * headLife;
    col += ORANGE * hd * (1.0 - smoothstep(HALFW * 1.4, HALFW * 2.6, abs(v - so))) * 0.7;
    col += BLUE   * hd * (1.0 - smoothstep(HALFW * 1.4, HALFW * 2.6, abs(v - sb))) * 0.7;
    // glitch / CA wake: broad band around the path, weighted by trail recency
    wake = amp * smoothstep(AMP * 6.0, 0.0, abs(v));
  }

  // --- composite: gravitational lens + PROJECT-style glitch / multichannel CA -
  const float CA_STR = 0.020;   // [knob] chromatic aberration strength in the wake
  const float GLITCH = 0.060;   // [knob] digital block-tear displacement strength
  vec2 lsuv = suv + lensDispUV;                       // lens bends the text around the core
  // digital block tearing (PROJECT): per-row random horizontal jump, gated to the wake
  float gby = floor(lsuv.y * 26.0);                   // horizontal tear rows
  float gframe = floor(time * 20.0);                  // ~20 glitch frames / sec (steppy, digital)
  float gtear = step(0.80, h21(vec2(gby + 3.0, gframe))) * wake;
  vec2 gsuv = lsuv + vec2((h21(vec2(gby, gframe)) - 0.5) * GLITCH * gtear, 0.0);
  // multichannel CA: R / G / B each displaced in a DIFFERENT direction
  vec2 cad = vec2(Dd.x / aspect, Dd.y);              // along travel (uv)
  vec2 cap = vec2(-cad.y, cad.x);                    // perpendicular
  float caw = CA_STR * wake;
  vec4 term;
  term.r = texture(iChannel0, gsuv + cad * caw + cap * caw * 0.45).r;
  term.g = texture(iChannel0, gsuv - cap * caw * 0.75).g;
  term.b = texture(iChannel0, gsuv - cad * caw + cap * caw * 0.45).b;
  term.a = texture(iChannel0, gsuv).a;
  vec3 rgb = mix(col, term.rgb, term.a);
  // neon RGB ghosts on glyph edges (red ahead / cyan behind) + glitch scanlines
  rgb += vec3(1.00, 0.12, 0.30) * texture(iChannel0, gsuv + cad * caw * 2.4).a * wake * 0.6;
  rgb += vec3(0.18, 0.90, 1.00) * texture(iChannel0, gsuv - cad * caw * 2.4).a * wake * 0.6;
  float scan = step(0.5, fract(lsuv.y * 130.0 + time * 7.0));
  rgb = mix(rgb, rgb * vec3(1.25, 0.85, 1.15), scan * wake * 0.5);

  // Text-only bloom: a soft cyan-violet glyph glow (alpha-weighted).  [knobs]
  const float BLOOM = 0.16;
  const float BLOOM_RADIUS = 2.0;
  const int   BLOOM_SAMPLES = 4;
  float bloom = 0.0;
  for (int x = -BLOOM_SAMPLES; x <= BLOOM_SAMPLES; x++) {
    for (int y = -BLOOM_SAMPLES; y <= BLOOM_SAMPLES; y++) {
      vec2 o = vec2(float(x), float(y)) * BLOOM_RADIUS / iResolution.xy;
      vec4 s = texture(iChannel0, suv + o);
      bloom += length(s.rgb) * s.a;
    }
  }
  bloom /= float((2 * BLOOM_SAMPLES + 1) * (2 * BLOOM_SAMPLES + 1));
  rgb += bloom * vec3(0.60, 0.78, 1.00) * BLOOM;

  float a = mix(0.92, 1.0, term.a);          // frosted panel; glyphs fully opaque
  fragColor = vec4(rgb, a);
}

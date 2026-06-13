const float S_LOOP = 3600.0; // smokescreen: wrap iTime (~60min loop) to avoid float32 precision jitter
// smokescreen theme: groudon
// The Continent Pokémon — Primal Groudon, the Ground/Fire titan of magma and
// drought. Read as TECTONIC PLATES OF GLOWING ROCK: near-black basalt broken
// into plates by a network of molten cracks (animated Voronoi cell borders) that
// flow orange -> yellow -> white-hot where the magma surges. A slow "breathe"
// pulses the heat, a faint heat-haze shimmers the seams, embers drift upward, and
// a low drought-sun warmth sits under everything. Built on the collection's
// Ashima-simplex backbone + ergonomic tuning (saturation / dim / luminance
// ceiling / text bloom) so the hot seams never wash out light text.
//
// Composites behind the terminal text via iChannel0 alpha; needs bg-opacity < 1.

// --- Ashima Arts 3D simplex noise (rock, heat flow, shimmer) ----------------
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

// --- hashes + animated Voronoi (returns distance to the nearest cell border) -
vec2 hash22(vec2 p) {
  p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
  return fract(sin(p) * 43758.5453);
}
float h21(vec2 p) {
  p = fract(p * vec2(123.34, 345.45));
  p += dot(p, p + 34.345);
  return fract(p.x * p.y);
}
// IQ-style voronoi: first find the nearest feature point, then the distance to
// the border between it and its neighbours (-> the magma crack network).
float voronoiBorder(vec2 x, float tt) {
  vec2 n = floor(x);
  vec2 f = fract(x);
  vec2 mg, mr;
  float md = 8.0;
  for (int j = -1; j <= 1; j++)
  for (int i = -1; i <= 1; i++) {
    vec2 g = vec2(float(i), float(j));
    vec2 o = hash22(n + g);
    o = 0.5 + 0.5 * sin(tt + 6.2831 * o);          // slow drift (plates shift)
    vec2 r = g + o - f;
    float d = dot(r, r);
    if (d < md) { md = d; mr = r; mg = g; }
  }
  md = 8.0;
  for (int j = -2; j <= 2; j++)
  for (int i = -2; i <= 2; i++) {
    vec2 g = mg + vec2(float(i), float(j));
    vec2 o = hash22(n + g);
    o = 0.5 + 0.5 * sin(tt + 6.2831 * o);
    vec2 r = g + o - f;
    if (dot(mr - r, mr - r) > 0.00001)
      md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
  }
  return md;                                         // small near a crack
}

// --- rising embers (sparse warm sparkles drifting upward) -------------------
float embers(vec2 g, float density) {
  vec2 gp = g * density;
  vec2 id = floor(gp);
  vec2 fp = fract(gp) - 0.5;
  float hh = h21(id);
  vec2 off = (vec2(h21(id + 2.3), h21(id + 7.1)) - 0.5) * 0.7;
  float d = length(fp - off);
  float core = smoothstep(0.05, 0.0, d);
  float present = step(0.93, hh);                    // rare
  float tw = 0.5 + 0.5 * sin(mod(iTime, S_LOOP) * 3.0 + hh * 6.2831);
  return core * present * tw;
}

// --- groudon palette (volcanic black rock + magma heat ramp) ----------------
const vec3 BASALT  = vec3(0.015, 0.010, 0.012);  // near-black volcanic rock
const vec3 DEEPRED = vec3(0.120, 0.030, 0.020);  // dark red-brown plate (body)
const vec3 EMBER   = vec3(0.950, 0.350, 0.070);  // magma orange
const vec3 YELLOW  = vec3(1.000, 0.720, 0.180);  // hot magma yellow
const vec3 WHITEH  = vec3(1.000, 0.930, 0.760);  // white-hot seam core

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 suv = fragCoord / iResolution.xy;
  float aspect = iResolution.x / iResolution.y;
  const float SPEED = 1.0;                  // overall time scale  [knob]
  float time = mod(iTime, S_LOOP) * SPEED;
  float t = time * 0.05;

  vec2 P = vec2(suv.x * aspect, suv.y);

  // heat-haze: wobble the sampling coords with a fast low-amplitude noise
  const float SHIMMER = 0.020;              // [knob] heat-haze strength
  vec2 shimmer = vec2(snoise(vec3(P * 2.5, t * 2.0)),
                      snoise(vec3(P * 2.5 + 5.0, t * 2.0))) * SHIMMER;
  vec2 pc = P + shimmer;

  // --- volcanic rock base -------------------------------------------------
  float rk = fbm(vec3(pc * 2.0, t * 0.3));
  vec3 col = mix(BASALT, DEEPRED, smoothstep(0.20, 0.85, rk));

  // --- tectonic magma cracks (animated Voronoi borders) -------------------
  const float CELLS  = 5.0;                 // [knob] plate size (bigger # = smaller plates)
  const float CRACKW = 0.075;               // [knob] crack width (border-distance threshold)
  float border = voronoiBorder(pc * CELLS, time * 0.15);
  float crack = smoothstep(CRACKW, 0.0, border);
  float core  = smoothstep(CRACKW * 0.30, 0.0, border);     // very centre of the seam

  // heat field: which seams are hottest right now (flowing magma)
  float heat = smoothstep(0.25, 0.85, fbm(vec3(pc * 1.3 + vec2(t * 0.6, 0.0), t * 0.25)));
  float breathe = 0.72 + 0.28 * sin(time * 0.6);            // slow magma surge
  const float MAGMA_I = 0.85;               // [knob] crack glow intensity
  vec3 magma = mix(EMBER, YELLOW, heat);
  col += magma * crack * (0.35 + 0.65 * heat) * breathe * MAGMA_I;

  // faint drought-sun warmth so the void isn't dead black
  col += DEEPRED * 0.25 * (0.4 + 0.6 * suv.y);

  // --- ergonomic tuning (saturation / dim / luminance ceiling) ------------
  const float SATURATION = 0.95;            // [knob] keep the magma fiery
  float gray = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(vec3(gray), col, SATURATION);
  col *= 0.62;                              // overall dim   [knob]
  float lum = dot(col, vec3(0.299, 0.587, 0.114));
  float ceiling = 0.16;                     // brightness cap [knob]
  col *= ceiling / max(lum, ceiling);

  // white-hot seam cores + embers AFTER the ceiling so they stay crisp
  col += WHITEH * core * heat * breathe * 0.6;             // [knob]
  vec2 eg = vec2(suv.x * aspect, suv.y + time * 0.03);     // sampling drifts down -> embers rise
  col += embers(eg, 55.0) * vec3(1.0, 0.50, 0.16) * 0.6;
  col += embers(eg * 1.7 + 3.0, 95.0) * vec3(1.0, 0.62, 0.22) * 0.35;

  // --- composite behind the terminal text ---
  vec4 term = texture(iChannel0, suv);
  vec3 rgb = mix(col, term.rgb, term.a);

  // Text-only bloom: a warm magma glow hugging the glyphs (alpha-weighted). [knobs]
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
  rgb += bloom * vec3(1.00, 0.55, 0.20) * BLOOM;           // warm glyph glow

  float a = mix(0.92, 1.0, term.a);          // frosted panel; glyphs fully opaque
  fragColor = vec4(rgb, a);
}

const float S_LOOP = 3600.0; // smokescreen: wrap iTime (~60min loop) to avoid float32 precision jitter
// smokescreen theme: rayquaza
// The sky serpent of the ozone layer — the legendary that calms the warring
// titans. Read as CALM, not spectacle: a slow emerald aurora over a near-black
// void, the dragon's undulating body rendered as serpentine vertical curtains
// of light, with only a whisper of gold (its ring markings) catching the crest.
//
// Built on Noah's radiantmatter architecture (Ashima 3D simplex -> 2-octave fBm
// -> two-iteration domain warp -> layers over black) plus the ergonomic tuning
// from radiantmatter-readable: density->opacity translucency, global saturation,
// overall dim, a luminance ceiling, and a text-only bloom. The one new move is
// ANISOTROPIC sampling (y compressed) so the flow elongates into tall aurora
// ribbons instead of round blobs. Designed for long, comfortable sessions:
// mostly black, low peaks, slow drift, nothing that flashes or distracts.
//
// Composites behind the terminal text via iChannel0 alpha; needs bg-opacity < 1.

// --- Ashima Arts 3D simplex noise -----------------------------------------
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

// --- small 2D hash + sparse twinkling starfield (the space backdrop) --------
float h21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}
float stars(vec2 g, float density, float tw) {
    vec2 gp = g * density;
    vec2 id = floor(gp);
    vec2 fp = fract(gp) - 0.5;
    float hh = h21(id);
    vec2 off = (vec2(h21(id + 1.7), h21(id + 9.1)) - 0.5) * 0.7;
    float d = length(fp - off);
    float core = smoothstep(0.055, 0.0, d);
    float present = step(0.86, hh);                  // sparse
    float twk = 0.40 + 0.60 * pow(0.5 + 0.5 * sin(mod(iTime, S_LOOP) * tw + hh * 6.2831), 2.0);
    return core * present * twk;
}

// --- slow-evolving atmospheric sky palette (muted) --------------------------
vec3 skyPal(float t) {
    vec3 a  = vec3(0.060, 0.080, 0.120);
    vec3 b  = vec3(0.050, 0.060, 0.080);
    vec3 cc = vec3(1.0, 1.0, 1.0);
    vec3 d  = vec3(0.00, 0.25, 0.50);
    return a + b * cos(6.28318 * (cc * t + d));
}

// --- rayquaza palette (deep ozone greens + a whisper of ring-gold) ----------
const vec3 VOID    = vec3(0.0, 0.0, 0.0);
const vec3 DEEP    = vec3(0.020, 0.090, 0.065);  // deep ozone green (near-black)
const vec3 EMERALD = vec3(0.055, 0.420, 0.235);  // serpent body
const vec3 JADE    = vec3(0.230, 0.720, 0.460);  // sheen on the crest
const vec3 GOLD    = vec3(0.850, 0.660, 0.260);  // ring markings catching light

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 suv = fragCoord / iResolution.xy;   // for sampling the terminal texture
  float aspect = iResolution.x / iResolution.y;
  float t = mod(iTime, S_LOOP) * 0.012;    // slow, calm drift

  // Anisotropic coords: compress y so noise features stretch into tall,
  // serpentine aurora curtains rather than round blobs.
  vec2 ac = suv; ac.x *= aspect;
  vec2 aw = vec2(ac.x, ac.y * 0.40);

  // Two-iteration domain warp (Noah) — gives the undulating, flowing body.
  vec2 q = vec2(snoise(vec3(aw, t)),
                snoise(vec3(aw + vec2(3.1, 1.7), t)));
  vec2 r = vec2(snoise(vec3(aw + q * 0.6 + vec2(1.7, 9.2), t * 0.5)),
                snoise(vec3(aw + q * 0.6 + vec2(8.3, 2.8), t * 0.5)));
  vec2 wuv = aw + r * 0.45;

  // --- atmospheric sky: a faint vertical gradient whose colours slowly migrate
  // upward (the sky evolving over time), fading to black space toward the top ---
  float st = mod(iTime, S_LOOP) * 0.010;        // very slow sky evolution  [knob]
  float band = suv.y * 1.6 - st;                // colour bands rise slowly
  float atmos = smoothstep(0.85, 0.0, suv.y);   // glow near the horizon (bottom)
  vec3 col = skyPal(band) * atmos * 0.45;       // faint atmospheric tint over black

  // Back curtain — broad, deep-green haze, the body in shadow.
  float s1 = fbm(vec3(wuv * 1.2 + vec2(0.0, 5.0), t * 0.6));
  float vis1 = smoothstep(0.15, 0.60, s1);
  vec3 c1 = mix(DEEP, EMERALD, smoothstep(0.20, 0.70, s1));
  const float BACK_GAMMA   = 1.6;
  const float BACK_OPACITY = 0.20;
  col = mix(col, c1, pow(vis1, BACK_GAMMA) * BACK_OPACITY);

  // Front ribbon — narrower, brighter jade sheen, with a whisper of ring-gold
  // only at the very crest.
  float s2 = fbm(vec3(wuv * 1.9 + vec2(4.0, 0.0), t * 0.9 + 20.0));
  float vis2 = smoothstep(0.28, 0.70, s2);
  vec3 c2 = mix(EMERALD, JADE, smoothstep(0.45, 0.85, s2));
  c2 = mix(c2, GOLD, smoothstep(0.80, 0.96, s2) * 0.30);
  const float FRONT_GAMMA   = 2.4;
  const float FRONT_OPACITY = 0.17;
  col = mix(col, c2, pow(vis2, FRONT_GAMMA) * FRONT_OPACITY);

  // --- ergonomic tuning (mirrors radiantmatter-readable) ------------------
  // Global saturation: keep the greens green but not garish.  [knob]
  const float SATURATION = 0.80;
  float gray = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(vec3(gray), col, SATURATION);

  // Overall dim + a luminance ceiling so peaks never wash out light text.
  col *= 0.55;                                       // overall dim   [knob]
  float lum = dot(col, vec3(0.299, 0.587, 0.114));
  float ceiling = 0.13;                              // brightness cap [knob]
  col *= ceiling / max(lum, ceiling);

  // --- stars: sparse, gentle, added AFTER the ceiling so they stay crisp;
  // weighted toward the upper "space" region, fewer near the horizon glow ---
  vec2 sg = vec2(suv.x * aspect, suv.y);
  float spaceMask = smoothstep(0.15, 0.75, suv.y);
  float sf = stars(sg, 60.0, 1.1) + stars(sg * 1.7 + 4.0, 110.0, 1.6) * 0.6;
  col += sf * spaceMask * vec3(0.65, 0.80, 1.00) * 0.35;   // faint blue-white glints

  // --- composite behind the terminal text ---
  vec4 term = texture(iChannel0, suv);
  vec3 rgb = mix(col, term.rgb, term.a);   // aurora where bg, text where glyph

  // Text-only bloom: a soft emerald glow that hugs the glyphs (alpha-weighted),
  // never the aurora. Calm and subtle.  [knobs]
  const float BLOOM = 0.18;
  const float BLOOM_RADIUS = 2.0;
  const int   BLOOM_SAMPLES = 4;
  float bloom = 0.0;
  for (int x = -BLOOM_SAMPLES; x <= BLOOM_SAMPLES; x++) {
    for (int y = -BLOOM_SAMPLES; y <= BLOOM_SAMPLES; y++) {
      vec2 off = vec2(float(x), float(y)) * BLOOM_RADIUS / iResolution.xy;
      vec4 s = texture(iChannel0, suv + off);
      bloom += length(s.rgb) * s.a;
    }
  }
  bloom /= float((2 * BLOOM_SAMPLES + 1) * (2 * BLOOM_SAMPLES + 1));
  vec3 glowColor = vec3(0.45, 0.95, 0.68);   // emerald glyph glow
  rgb += bloom * glowColor * BLOOM;

  float a = mix(0.92, 1.0, term.a);          // frosted panel; glyphs fully opaque
  fragColor = vec4(rgb, a);
}

const float S_LOOP = 3600.0; // smokescreen: wrap iTime (~60min loop) to avoid float32 precision jitter
// smokescreen theme: kyogre
// The Sea Basin Pokémon — Primal Kyogre, the Water titan of the deep ocean and
// the endless rain. The oceanic counterpart to groudon: read as a DEEP-SEA
// ABYSS. A dark blue depth gradient (abyssal black-blue below, teal near the
// surface), shimmering WATER CAUSTICS (fwidth isolines of a drifting current),
// swaying GOD-RAY light shafts from the surface, and drifting BIOLUMINESCENT
// plankton — mostly cyan, with rare warm-red motes echoing Kyogre's markings.
// Built on the collection's Ashima-simplex backbone + ergonomic tuning so the
// caustics and rays never wash out light text.
//
// Composites behind the terminal text via iChannel0 alpha; needs bg-opacity < 1.

// --- Ashima Arts 3D simplex noise -------------------------------------------
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

// --- 2D hash + drifting bioluminescent plankton -----------------------------
float h21(vec2 p) {
  p = fract(p * vec2(123.34, 345.45));
  p += dot(p, p + 34.345);
  return fract(p.x * p.y);
}
vec3 plankton(vec2 g, float density) {
  vec2 gp = g * density;
  vec2 id = floor(gp);
  vec2 fp = fract(gp) - 0.5;
  float hh = h21(id);
  vec2 off = (vec2(h21(id + 2.3), h21(id + 7.1)) - 0.5) * 0.7;
  float d = length(fp - off);
  float core = smoothstep(0.05, 0.0, d);
  float present = step(0.90, hh);                              // sparse
  float tw = 0.45 + 0.55 * pow(0.5 + 0.5 * sin(mod(iTime, S_LOOP) * 1.3 + hh * 6.2831), 2.0);
  float ch = h21(id + 19.3);
  vec3 tint = ch < 0.85 ? vec3(0.45, 0.85, 1.00)              // cyan plankton (common)
                        : vec3(1.00, 0.35, 0.25);            // rare warm-red Kyogre mote
  return core * present * tw * tint;
}

// --- kyogre palette ---------------------------------------------------------
const vec3 ABYSS = vec3(0.002, 0.010, 0.028);  // abyssal black-blue (deep)
const vec3 DEEP  = vec3(0.010, 0.045, 0.120);  // deep ocean blue
const vec3 TEAL  = vec3(0.025, 0.140, 0.220);  // sunlit teal (near surface)
const vec3 CYAN  = vec3(0.300, 0.600, 0.860);  // caustic / light highlight

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 suv = fragCoord / iResolution.xy;
  float aspect = iResolution.x / iResolution.y;
  const float SPEED = 1.0;                  // overall time scale  [knob]
  float time = mod(iTime, S_LOOP) * SPEED;
  float t = time * 0.05;

  vec2 P = vec2(suv.x * aspect, suv.y);

  // --- ocean depth gradient (abyss below -> teal near the surface) --------
  vec3 col = mix(ABYSS, DEEP, smoothstep(0.0, 0.55, suv.y));
  col = mix(col, TEAL, smoothstep(0.5, 1.0, suv.y));

  // --- slow current: a two-iteration domain warp drives the caustics ------
  vec2 cc = P; cc.y *= 1.25;
  vec2 q = vec2(snoise(vec3(cc * 1.4, t)),
                snoise(vec3(cc * 1.4 + vec2(4.0, 1.0), t)));
  vec2 wuv = cc + q * 0.40;

  // --- water caustics: fwidth isolines of the drifting field (two scales) -
  const float BANDS = 7.0;                  // [knob] caustic line density
  float f1 = fbm(vec3(wuv * 2.2 + vec2(t * 0.6, 0.0), t * 0.5)) * BANDS;
  float c1 = smoothstep(fwidth(f1) * 1.5, 0.0, abs(fract(f1) - 0.5));
  float f2 = fbm(vec3(wuv * 3.8 + vec2(0.0, t * 0.7), t * 0.4 + 9.0)) * BANDS;
  float c2 = smoothstep(fwidth(f2) * 1.5, 0.0, abs(fract(f2) - 0.5));
  float caustic = max(c1, c2 * 0.7);
  float depthLit = smoothstep(0.0, 1.0, suv.y * 0.85 + 0.15);  // light penetrates from the top
  const float CAUSTIC_I = 0.45;             // [knob] caustic brightness
  col += CYAN * caustic * depthLit * CAUSTIC_I;

  // --- god rays: swaying light shafts descending from the surface ----------
  float rt = time * 0.08;
  float shaft = fbm(vec3((P.x - suv.y * 0.35) * 2.4 + rt, 5.0, 0.0));
  float rays = pow(smoothstep(0.45, 0.95, shaft), 2.0) * smoothstep(0.0, 0.75, suv.y);
  const float RAYS_I = 0.22;                 // [knob] god-ray strength
  col += CYAN * rays * RAYS_I;

  // --- ergonomic tuning (saturation / dim / luminance ceiling) ------------
  const float SATURATION = 0.90;            // [knob]
  float gray = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(vec3(gray), col, SATURATION);
  col *= 0.62;                              // overall dim   [knob]
  float lum = dot(col, vec3(0.299, 0.587, 0.114));
  float ceiling = 0.15;                     // brightness cap [knob]
  col *= ceiling / max(lum, ceiling);

  // --- bioluminescent plankton AFTER the ceiling (crisp), drifting upward --
  vec2 bg = vec2(suv.x * aspect, suv.y - time * 0.012);       // sampling drifts down -> motes rise
  col += plankton(bg, 55.0) * 0.7;
  col += plankton(bg * 1.7 + 4.0, 95.0) * 0.45;

  // --- composite behind the terminal text ---
  vec4 term = texture(iChannel0, suv);
  vec3 rgb = mix(col, term.rgb, term.a);

  // Text-only bloom: a cool blue glow hugging the glyphs (alpha-weighted). [knobs]
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
  rgb += bloom * vec3(0.35, 0.70, 1.00) * BLOOM;             // cool glyph glow

  float a = mix(0.92, 1.0, term.a);          // frosted panel; glyphs fully opaque
  fragColor = vec4(rgb, a);
}

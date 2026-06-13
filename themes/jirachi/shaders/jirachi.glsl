const float S_LOOP = 3600.0; // smokescreen: wrap iTime (~60min loop) to avoid float32 precision jitter
// smokescreen theme: jirachi
// The Wish Pokemon — Psychic / Steel, the Millennium star from space that sleeps
// a thousand years and wakes only to grant wishes. Read as CALM DREAMING SLEEP,
// PUNCTUATED BY A GRANTED WISH: a slow psychic nebula (deep indigo -> teal, the
// colours of its wish-tags) drifts over a near-black cosmic void, dusted with a
// sparse twinkling gold/white starfield. Riding the brightest nebula filaments
// are tiny GOLD METALLIC FLECKS — the Steel-type sheen, the economic gold. Then,
// rarely, the signature move: the MILLENNIUM COMET streaks across with a sharp
// 5-POINT STAR head (Jirachi itself) and a gold tail — a single granted wish,
// crisp as a machinist's cut, not a strobe.
//
// For Brennan (0xjirachi): NASA machinist & engineer (the precise comet streak,
// the steel sheen), crypto BD (the economic gold), the economic wishmaster.
//
// Built on Noah's radiantmatter architecture (Ashima 3D simplex -> 2-octave fBm
// -> two-iteration domain warp -> layers over black) plus the ergonomic tuning
// from radiantmatter-readable (density->opacity, saturation, dim, luminance
// ceiling, text-only bloom). Designed for long, comfortable sessions: mostly
// black, low peaks, slow drift, one rare delight.
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

// --- small 2D hash + sparse twinkling starfield (the cosmic backdrop) -------
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

// --- 5-point star sparkle (Jirachi's head) — round core + 5 radiating spikes -
float starSpark(vec2 d, float size) {
    float r = length(d) / size;
    float a = atan(d.y, d.x);
    float spikes = pow(max(0.0, cos(a * 5.0)), 8.0);   // 5 narrow points
    float core = exp(-r * r * 6.0);                    // bright round core
    float ray  = exp(-r * 2.6) * spikes;               // the star points
    return core + ray * 0.9;
}

// --- jirachi palette (psychic indigo/teal of the wish-tags + economic gold) --
const vec3 VOID    = vec3(0.010, 0.012, 0.030);  // near-black cosmic blue
const vec3 INDIGO  = vec3(0.110, 0.075, 0.260);  // deep psychic violet (back nebula)
const vec3 TEAL    = vec3(0.050, 0.250, 0.300);  // wish-tag cyan-teal (front)
const vec3 CYAN    = vec3(0.300, 0.620, 0.780);  // brighter psychic sheen
const vec3 GOLD    = vec3(0.950, 0.780, 0.340);  // Jirachi gold / economic
const vec3 WHITEH  = vec3(1.000, 0.960, 0.870);  // white-hot comet head

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 suv = fragCoord / iResolution.xy;   // for sampling the terminal texture
  float aspect = iResolution.x / iResolution.y;
  const float SPEED = 1.0;                  // overall time scale  [knob]
  float mt = mod(iTime, S_LOOP) * SPEED;
  float t = mt * 0.012;                     // calm nebula drift (the long sleep)

  // Isotropic cosmic coords (round, cloudy nebula — not stretched ribbons).
  vec2 ac = suv; ac.x *= aspect;

  // Two-iteration domain warp (Noah) — slow billowing psychic cloud.
  vec2 q = vec2(snoise(vec3(ac, t)),
                snoise(vec3(ac + vec2(3.1, 1.7), t)));
  vec2 r = vec2(snoise(vec3(ac + q * 0.6 + vec2(1.7, 9.2), t * 0.5)),
                snoise(vec3(ac + q * 0.6 + vec2(8.3, 2.8), t * 0.5)));
  vec2 wuv = ac + r * 0.45;

  // Base: the cosmic void.
  vec3 col = VOID;

  // Back nebula — broad, deep psychic indigo haze (Jirachi dreaming).
  float s1 = fbm(vec3(wuv * 1.1 + vec2(0.0, 5.0), t * 0.6));
  float vis1 = smoothstep(0.12, 0.62, s1);
  vec3 c1 = mix(VOID, INDIGO, smoothstep(0.18, 0.72, s1));
  const float BACK_GAMMA   = 1.6;   // [knob] higher = sparser
  const float BACK_OPACITY = 0.34;  // [knob]
  col = mix(col, c1, pow(vis1, BACK_GAMMA) * BACK_OPACITY);

  // Front nebula — narrower teal/cyan filaments (the wish-tag colour).
  float s2 = fbm(vec3(wuv * 1.9 + vec2(4.0, 0.0), t * 0.9 + 20.0));
  float vis2 = smoothstep(0.28, 0.72, s2);
  vec3 c2 = mix(TEAL, CYAN, smoothstep(0.46, 0.86, s2));
  const float FRONT_GAMMA   = 2.2;  // [knob]
  const float FRONT_OPACITY = 0.22; // [knob]
  col = mix(col, c2, pow(vis2, FRONT_GAMMA) * FRONT_OPACITY);

  // --- ergonomic tuning (mirrors radiantmatter-readable) ------------------
  const float SATURATION = 0.85;    // [knob] keep psychic blues vivid, not garish
  float gray = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(vec3(gray), col, SATURATION);

  col *= 0.58;                                       // overall dim   [knob]
  float lum = dot(col, vec3(0.299, 0.587, 0.114));
  float ceiling = 0.13;                              // brightness cap [knob]
  col *= ceiling / max(lum, ceiling);

  // --- gold metallic flecks: the Steel-type sheen / economic gold. High-freq
  // shimmer riding ONLY the brightest front filaments, twinkling. Added after
  // the ceiling so the flecks read as crisp metal.  [knobs]
  float fleckN = fbm(vec3(wuv * 7.5 + vec2(11.0, 3.0), t * 1.6));
  float fleckMask = smoothstep(0.58, 0.86, fleckN) * pow(vis2, 1.5);
  float fleckTwk = 0.5 + 0.5 * sin(mt * 2.3 + fleckN * 18.0);
  col += GOLD * fleckMask * fleckTwk * 0.45;

  // --- starfield: sparse gold/white cosmic dust, AFTER the ceiling so crisp.
  vec2 sg = vec2(suv.x * aspect, suv.y);
  float sf = stars(sg, 60.0, 1.1) + stars(sg * 1.7 + 4.0, 110.0, 1.6) * 0.6;
  col += sf * mix(vec3(0.70, 0.82, 1.00), GOLD, 0.35) * 0.6;

  // --- the Millennium Comet: the signature granted-wish event. Rare single
  // streak with a sharp 5-point star head + a gold tail. One per period; each
  // wish comes from a fresh hashed start/angle. Single-event (not a strobe).
  const float T_WISH    = 24.0;   // [knob] seconds between wishes
  const float TRAVEL_F  = 0.075;  // [knob] fraction of the period the comet is in flight (~1.8s)
  const float TAIL_LEN  = 0.34;   // [knob] tail length (aspect space)
  const float TAIL_W    = 0.0045; // [knob] streak half-width (thin = precise)
  const float HEAD_SIZE = 0.052;  // [knob] star-head radius
  const float WISH_INT  = 1.15;   // [knob] peak brightness of the wish
  float cyc = floor(mt / T_WISH);
  float ph  = fract(mt / T_WISH);
  float travel = ph / TRAVEL_F;                       // 0..1 during flight, >1 idle
  float env = smoothstep(0.0, 0.12, travel) * (1.0 - smoothstep(0.62, 1.0, travel));

  vec2 P = vec2(suv.x * aspect, suv.y);
  // per-wish hashed origin (upper region) and a downward diagonal heading.
  vec2 S = vec2(mix(0.05, aspect - 0.05, h21(vec2(cyc, 1.0))),
                mix(0.78, 1.08, h21(vec2(cyc, 2.0))));
  vec2 dir = normalize(vec2(mix(-0.75, 0.75, h21(vec2(cyc, 3.0))), -1.0));
  vec2 head = S + dir * travel * 1.7;                 // sweep ~1.7 of height
  float sAxis = dot(P - head, -dir);                  // distance behind the head
  vec2 closest = head - dir * clamp(sAxis, 0.0, TAIL_LEN);
  float perp = length(P - closest);
  float streak = smoothstep(TAIL_W, 0.0, perp) * (1.0 - clamp(sAxis / TAIL_LEN, 0.0, 1.0));
  float headG = starSpark(P - head, HEAD_SIZE);
  float comet = env * (streak * 0.85 + headG * 1.4);
  vec3 cometCol = mix(GOLD, WHITEH, clamp(headG, 0.0, 1.0));
  col += comet * cometCol * WISH_INT;

  // --- composite behind the terminal text ---
  vec4 term = texture(iChannel0, suv);
  vec3 rgb = mix(col, term.rgb, term.a);   // nebula where bg, text where glyph

  // Text-only bloom: a soft warm-gold glow hugging the glyphs (alpha-weighted),
  // never the nebula.  [knobs]
  const float BLOOM = 0.16;
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
  vec3 glowColor = vec3(0.85, 0.80, 0.58);   // soft gold glyph glow
  rgb += bloom * glowColor * BLOOM;

  float a = mix(0.92, 1.0, term.a);          // frosted panel; glyphs fully opaque
  fragColor = vec4(rgb, a);
}

// smokescreen theme: radiantmatter-readable
// The radiantmatter.io gradient (by Noah), tuned for terminal legibility:
// identical noise/warp/layers as radiantmatter-default, but the bright peaks
// are dimmed and highlight-capped so light terminal text isn't washed out.
// See the "readability tuning" block in main() for the knobs.
//
// Original: a Three.js fullscreen-quad WebGL effect — Ashima 3D simplex noise,
// a 2-octave fBm, a two-iteration domain warp, and two color layers (a cool
// blue->cyan->green layer and a warm purple->magenta->pink layer) composited
// over near-black. Brand palette lifted from the site's CSS variables.
//
// Adapted for the terminal: the original wrote an opaque fullscreen color; here
// we composite the gradient BEHIND the terminal text, using iChannel0's alpha
// as a text mask so glyphs stay crisp. Requires background-opacity < 1.

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

// --- radiant-matter brand palette -----------------------------------------
const vec3 BLACK   = vec3(0.0, 0.0, 0.0);        // pure black base
const vec3 DKBLUE  = vec3(0.082, 0.047, 0.702);  // #150cb3
const vec3 PURPLE  = vec3(0.255, 0.0,   0.659);  // #4100a8
const vec3 MAGENTA = vec3(0.859, 0.424, 0.827);  // #db6cd3
const vec3 PINK    = vec3(0.918, 0.616, 0.922);  // #ea9deb
const vec3 CYAN    = vec3(0.063, 0.882, 0.973);  // #10e1f8
const vec3 GREEN   = vec3(0.0,   1.0,   0.616);  // #00ff9d

// 2-octave fBm — weighted toward the low octave for a softer, more diffuse body
float fbm(vec3 p) {
  return snoise(p) * 0.78 + snoise(p * 1.9) * 0.22;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 suv = fragCoord / iResolution.xy;   // for sampling the terminal texture
  vec2 uv = suv;
  float aspect = iResolution.x / iResolution.y;
  uv.x *= aspect;
  // RM used u_time(ms) * 0.00005 (=> 0.05 in seconds); slowed to 25% for a
  // calmer drift.
  float t = iTime * 0.0125;

  // Domain warping — two iterations for organic flowing forms
  vec2 q = vec2(
    snoise(vec3(uv * 1.0, t * 0.6)),
    snoise(vec3(uv * 1.0 + vec2(5.2, 1.3), t * 0.6))
  );
  vec2 r = vec2(
    snoise(vec3(uv + q * 0.7 + vec2(1.7, 9.2), t * 0.35)),
    snoise(vec3(uv + q * 0.7 + vec2(8.3, 2.8), t * 0.35))
  );
  vec2 wuv = uv + r * 0.62;   // a touch more warp -> color pools spread wider

  vec3 col = BLACK;

  // Diffusion pass: lower layer frequencies broaden the color pools, and the
  // wider smoothsteps feather every edge so colors bleed gently instead of
  // breaking into tight filaments.

  // Density -> opacity relation. Each layer's alpha against the black is its
  // density raised to a power: thin/wispy regions fall off steeply toward
  // transparent (black shows through), only DENSE cores approach opaque. This
  // is what makes it read as translucent smoke over a dominant black instead
  // of flat color painted on top. Separate from brightness (dim/ceiling).
  const float DENSITY_GAMMA = 2.6;   // higher = thin areas vanish faster   [knob]
  const float MAX_OPACITY   = 0.85;  // densest cores still let some black through [knob]

  // Cool layer — cyan at peaks, deep blue at base, green filaments
  float s1 = fbm(vec3(wuv * 0.85 + vec2(3.0, 7.0), t * 0.2 + 40.0));
  float vis1 = smoothstep(-0.10, 0.45, s1);
  vec3 c1 = mix(DKBLUE, CYAN, smoothstep(0.00, 0.85, s1));
  c1 = mix(c1, GREEN, smoothstep(0.20, 0.70, s1) * 0.55);
  col = mix(col, c1, pow(vis1, DENSITY_GAMMA) * MAX_OPACITY);

  // Warm layer — magenta/pink at peaks, purple at base
  float s2 = fbm(vec3(wuv * 1.05, t * 0.3));
  float vis2 = smoothstep(-0.10, 0.45, s2);
  vec3 c2 = mix(PURPLE, MAGENTA, smoothstep(0.05, 0.80, s2));
  c2 = mix(c2, PINK, smoothstep(0.35, 0.95, s2));
  col = mix(col, c2, pow(vis2, DENSITY_GAMMA) * MAX_OPACITY);

  // --- readability tuning -------------------------------------------------
  // Terminal text is light; the brightest cyan/pink/green peaks wash it out.
  // Dim the field overall, then apply a luminance ceiling that pulls down ONLY
  // the brightest peaks (hue preserved) while leaving the dark strata intact.
  col *= 0.36;                                       // overall dim  [knob]
  float lum = dot(col, vec3(0.299, 0.587, 0.114));
  float ceiling = 0.05;                              // brightness cap  [knob]
  col *= ceiling / max(lum, ceiling);                // soft-clip highlights

  // --- composite behind the terminal text ---
  vec4 term = texture(iChannel0, suv);
  vec3 rgb = mix(col, term.rgb, term.a);   // gradient where bg, text where glyph
  float a = mix(0.92, 1.0, term.a);        // frosted panel; glyphs fully opaque
  fragColor = vec4(rgb, a);
}

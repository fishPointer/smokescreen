# smokescreen

Animated background shaders for [Ghostty](https://ghostty.org), bundled as
**themes**. Each theme is a flowing, full-panel color field rendered *behind*
your terminal text — the terminal arrives to the shader as a texture and its
alpha is used as a text mask, so the field fills the background while your glyphs
stay crisp on top.

## Themes

Each theme is a self-contained bundle under `themes/<name>/`: a `ghostty.conf`
snippet plus its `shaders/`.

### `default`
A "chthonic diffusion" — a domain-warped fBm mesh-gradient cloud in deep
obsidian, oxblood, plum, and verdigris, with rare molten-ember veins rising from
the brightest filaments. CRT scanlines + soft bloom layer on top.
Files: `gradient-cloud.glsl`, `crt-bloom.glsl`.

### `distortion`
Giratina / Distortion-World: a darker chthonic void threaded with molten
**amber-gold veins** — sparse (they only host in drifting low-frequency
patches), intense (sharp ridged filament cores), glittering (fast high-frequency
gold sparks riding the filaments), and fleeting (a traveling pulse + drifting
on/off envelope so veins flare up and die). Same obsidian/oxblood/plum/verdigris
palette as `default`, pushed darker so the heat dominates. CRT on top.
Files: `distortion.glsl`, `crt-bloom.glsl`.

### `pool-party`
Vaporwave / cosmic-bowling-carpet under a blacklight: a **stellar** dark base
(deep celestial violet / indigo / teal) lit ambiently by a confetti of twinkling
neon sparkles, with UV-neon "squiggle" caustics (the `distortion` fwidth-isoline
shimmer, recoloured cyan/magenta) glowing across it. CRT/VHS scanlines on top.
Files: `pool-party.glsl`, `crt-bloom.glsl`.

### `deoxys`
The DNA Pokémon as a **deep-space scene**: a black void dusted with a
multi-coloured twinkling starfield over a slow psychic nebula (jirachi's
domain-warped cloud, recoloured to Deoxys violet/teal). Its signature move is a
rare **DNA / PCB differential-pair particle** — on a random 30–60s cadence a tiny
ephemeral particle streaks across in a random direction, drawing a pair of flat,
fixed-width solid ribbons (orange + blue) that snake like a PCB differential pair
and weave around one another like a double helix, with an aggressively tapering
exponential tail. Around its core a **gravitational lens** bends the field and
text; behind it trails a **PROJECT-style glitch wake** — intense multichannel
chromatic aberration, digital block-tearing, neon RGB ghosts, and glitch
scanlines. CRT on top. (A 3D raymarched spinning core-crystal is kept disabled in
an `#if 0` block for later.) Files: `deoxys.glsl`, `crt-bloom.glsl`.

### `rayquaza`
The ozone-layer sky serpent as **calm, not spectacle**: a slow emerald aurora
over a near-black void, the dragon's undulating body rendered as serpentine
vertical curtains (via **anisotropic sampling** — y compressed so the flow
elongates into ribbons), with only a whisper of ring-gold at the crest. Built on
Noah's architecture + radiantmatter-readable's ergonomic tuning (density→opacity,
saturation, dim, luminance ceiling, text-only bloom). Designed for long,
comfortable sessions — mostly black, low peaks, slow drift, nothing that flashes.
Files: `rayquaza.glsl`, `crt-bloom.glsl`.

### `jirachi`
The Wish Pokémon (Psychic/Steel) — the Millennium star from space that sleeps a
thousand years and wakes only to grant wishes. Read as **calm dreaming sleep,
punctuated by a granted wish**: a slow psychic **nebula** (deep indigo → teal,
the colours of its wish-tags) drifts over a near-black cosmic void, dusted with a
sparse twinkling **gold/white starfield**. Riding the brightest filaments are
tiny **gold metallic flecks** — the Steel-type sheen / economic gold. Then,
rarely, the signature move: the **Millennium Comet** streaks across with a sharp
**5-point star head** (Jirachi itself) and a gold tail — a single granted wish,
crisp as a machinist's cut, not a strobe. Built on Noah's architecture +
radiantmatter-readable's ergonomic tuning; calm enough for long sessions, with
one rare delight. Made for Brennan (0xjirachi), the economic wishmaster.
Files: `jirachi.glsl`, `crt-bloom.glsl`.

### `groudon`
Primal Groudon (Ground/Fire) as **tectonic plates of glowing rock**: near-black
basalt broken into plates by a network of molten **Voronoi cracks** that flow
orange → yellow → **white-hot** where the magma surges, with a slow magma
"breathe," a heat-haze shimmer on the seams, **rising embers**, and a low
drought-sun warmth under it all. Ergonomic (luminance ceiling + warm text bloom)
so the hot seams never wash out light text. CRT on top.
Files: `groudon.glsl`, `crt-bloom.glsl`.

### `kyogre`
Primal Kyogre (Water) as a **deep-sea abyss** — the oceanic counterpart to
`groudon`: a dark-blue depth gradient (abyss below, teal near the surface),
shimmering **water caustics** (`fwidth` isolines of a drifting current), swaying
**god-ray** light shafts descending from the surface, and drifting
**bioluminescent plankton** (mostly cyan, with rare warm-red motes echoing
Kyogre's markings). Ergonomic ceiling + cool-blue text bloom for legibility.
CRT on top. Files: `kyogre.glsl`, `crt-bloom.glsl`.

### `radiantmatter-default`
A faithful port of the [radiantmatter.io](https://radiantmatter.io) background
gradient (by Noah): a Three.js WebGL mesh gradient — Ashima 3D simplex noise, a
2-octave fBm, a two-iteration domain warp, and two color layers (cool
blue→cyan→green, warm purple→magenta→pink) over a pure-black base. Brand palette
lifted from the site's CSS variables. Adapted to composite behind terminal text.
Files: `radiantmatter.glsl`.

### `radiantmatter-readable`
The same gradient, tuned for terminal legibility: identical noise/warp/layers,
but the field is dimmed and a luminance ceiling pulls down only the brightest
cyan/pink/green peaks (hue preserved) so light text isn't washed out. The two
knobs — overall dim and brightness `ceiling` — live in the shader's "readability
tuning" block. Files: `radiantmatter-readable.glsl`.

## Install a theme

Copy the theme's shaders into Ghostty's shader directory, then point your config
at it:

```sh
THEME=radiantmatter            # or: default
mkdir -p ~/.config/ghostty/shaders
cp themes/$THEME/shaders/*.glsl ~/.config/ghostty/shaders/
```

Then add the theme's `ghostty.conf` lines to `~/.config/ghostty/config`. For
`radiantmatter`:

```ini
background-opacity = 0.0
background-blur = 24
custom-shader = shaders/radiantmatter.glsl
custom-shader-animation = true
```

Reload with **Ctrl+Shift+,** (or restart Ghostty).

> **Note:** these shaders need `background-opacity < 1` so background cells are
> transparent (alpha ≈ 0) and the field shows through. At `1.0` the text mask is
> opaque everywhere and you'll only see your normal background.

## How it works

All shaders are standard [Shadertoy](https://www.shadertoy.com)-style GLSL
(`void mainImage(out vec4 fragColor, in vec2 fragCoord)`), driven by Ghostty's
`iChannel0` (the terminal), `iResolution`, and `iTime` uniforms. The closing
composite is always:

```glsl
vec4 term = texture(iChannel0, uv);
vec3 rgb  = mix(field, term.rgb, term.a);  // field where bg, text where glyph
float a   = mix(0.92, 1.0, term.a);        // frosted panel; glyphs opaque
fragColor = vec4(rgb, a);
```

Multiple `custom-shader` lines chain in order — later shaders post-process the
output of earlier ones (that's how `default` layers CRT over the cloud).

## Freezing (static render)

Every animated theme shader carries a **freeze toggle** near its `mainImage`:

```glsl
const float FREEZE_FRAME = -1.0;
float sceneTime() { return FREEZE_FRAME >= 0.0 ? FREEZE_FRAME : iTime; }
```

`mainImage` shadows the live `iTime` uniform with `float iTime = sceneTime();`,
so the whole shader reads its clock through the toggle without any other change:

- **`FREEZE_FRAME = -1.0`** (default) — live `iTime`, animated as before.
- **`FREEZE_FRAME = 200.0`** (any value `>= 0`) — the clock is pinned to that one
  frame and the field stops moving. The number *is* the frame: change it to land
  on a different still.

Freezing the image is only half of it — pair it with Ghostty's animation flag to
stop the work:

```ini
custom-shader-animation = false
```

With `false`, Ghostty stops its continuous redraw loop (the part that actually
burns the GPU) and only re-runs the shader when the terminal contents change.
On its own, `false` doesn't fully freeze the picture — Ghostty still feeds
wall-clock time into `iTime` on each incidental redraw — so for a truly fixed
still you want **both**: `FREEZE_FRAME >= 0` (pins the frame) *and*
`custom-shader-animation = false` (stops the loop). `crt-bloom.glsl` uses no
`iTime`, so it's static either way and carries no toggle.

> **Freezing edits the file.** If you symlink the live shader at the repo copy
> (see *Development* below), flipping `FREEZE_FRAME` there freezes the repo's
> canonical copy too. To freeze just one terminal, copy the shader into
> `~/.config/ghostty/shaders/` and flip the constant on the copy, leaving the
> repo default live.

## Examples

[`examples/ghostty.conf`](examples/ghostty.conf) is a full working Ghostty
config using the `radiantmatter-readable` theme (transparency, blur, the gradient
+ CRT chain) — handy as a reference for the whole setup, not just the shader
lines.

## Development (single source of truth)

To iterate without copying files into `~/.config/ghostty/shaders/` after every
edit, symlink the live shaders at the repo copies — then editing a shader here
updates the running terminal on the next reload (**Ctrl+Shift+,**):

```sh
S=~/.config/ghostty/shaders; R=~/smokescreen/themes
ln -sf "$R/radiantmatter-readable/shaders/radiantmatter-readable.glsl" "$S/radiantmatter-readable.glsl"
ln -sf "$R/radiantmatter-readable/shaders/crt-bloom.glsl"              "$S/crt-bloom.glsl"
ln -sf "$R/default/shaders/gradient-cloud.glsl"                        "$S/gradient-cloud.glsl"
ln -sf "$R/radiantmatter-default/shaders/radiantmatter.glsl"          "$S/radiantmatter.glsl"
ln -sf "$R/jirachi/shaders/jirachi.glsl"                              "$S/jirachi.glsl"
```

Note: `crt-bloom.glsl` is duplicated per-theme so each theme stays a
self-contained installable bundle; the live symlink points at the active theme's
copy.

## License

MIT — see [LICENSE](LICENSE).

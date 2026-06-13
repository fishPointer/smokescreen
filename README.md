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

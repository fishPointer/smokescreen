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
```

Note: `crt-bloom.glsl` is duplicated per-theme so each theme stays a
self-contained installable bundle; the live symlink points at the active theme's
copy.

## License

MIT — see [LICENSE](LICENSE).

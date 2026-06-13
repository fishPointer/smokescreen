# smokescreen

Animated background shaders for [Ghostty](https://ghostty.org) — a flowing,
chthonic color cloud that diffuses behind your terminal text, with optional CRT
scanlines and bloom layered on top.

The headline effect is **`gradient-cloud`**: a domain-warped fBm mesh-gradient
(think Stripe-banner gradients, but dark and alive) rendered *behind* your text.
The terminal arrives to the shader as a texture, and its alpha is used as a text
mask — so the cloud fills the background while your glyphs stay crisp on top.

Ships with a deep "chthonic" palette out of the box: obsidian indigo with
oxblood, plum, and verdigris strata, and rare molten-ember veins rising from the
brightest filaments.

## Shaders

| File | Effect |
|------|--------|
| `shaders/gradient-cloud.glsl` | Animated fBm mesh-gradient color cloud, composited behind text via the terminal alpha mask. The star of the show. |
| `shaders/crt-bloom.glsl` | CRT scanlines + soft text bloom + vignette. Layers on top of anything before it. |

Both are standard [Shadertoy](https://www.shadertoy.com)-style GLSL
(`void mainImage(out vec4 fragColor, in vec2 fragCoord)`), driven by Ghostty's
`iChannel0` (the terminal), `iResolution`, and `iTime` uniforms.

## Install

Copy the shaders into Ghostty's config directory:

```sh
mkdir -p ~/.config/ghostty/shaders
cp shaders/*.glsl ~/.config/ghostty/shaders/
```

Then add to `~/.config/ghostty/config`:

```ini
# Low opacity so the animated cloud shows through; blur frosts the desktop
# behind the panel. Set opacity to 0.0 for the cloud to fully replace the
# background (the shader's alpha mask keeps text readable).
background-opacity = 0.0
background-blur = 24

# Order matters: the cloud runs first (paints behind text), CRT layers over it.
custom-shader = shaders/gradient-cloud.glsl
custom-shader = shaders/crt-bloom.glsl
custom-shader-animation = true
```

Reload with **Ctrl+Shift+,** (or restart Ghostty).

> **Note:** `gradient-cloud` needs `background-opacity < 1` so background cells
> are transparent (alpha ≈ 0) and the cloud shows through. At `1.0` the mask is
> opaque everywhere and you'll only see your normal background.

Want only the cloud, no CRT? Drop the `crt-bloom.glsl` line.

## Tuning `gradient-cloud`

All knobs live near the top of `mainImage`:

| Want | Edit |
|------|------|
| Faster / slower drift | `float t = iTime * 0.04;` — raise for livelier, lower for calmer |
| Different colors | the `c1`..`c4` palette `vec3`s |
| More / less ember | the `ember * vec3(0.55, 0.20, 0.04)` magnitude, or widen the gate `smoothstep(0.72, 1.0, f)` |
| Colder magma glow | swap ember color toward `vec3(0.5, 0.05, 0.25)` |
| Darker overall | raise the `pow(col, vec3(1.15))` exponent toward `1.4` |
| Let more desktop through | lower the `mix(0.92, 1.0, term.a)` floor (e.g. `0.8`) |

## Compatibility

Built and tested on Ghostty (Wayland / KDE Plasma). The cloud's transparency
relies on a compositor that honors `background-opacity` + `background-blur`.

## License

MIT — see [LICENSE](LICENSE).

// CRT scanlines + vignette for Ghostty
// (bloom removed: it sampled the whole frame, so it glowed the gradient too)

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    vec4 col = texture(iChannel0, uv);

    // --- CRT scanlines ---
    float scanline = sin(fragCoord.y * 2.0) * 0.5 + 0.5;
    scanline = mix(1.0, scanline, 0.50);
    col.rgb *= scanline;

    // --- Slight vignette ---
    vec2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 0.35;
    col.rgb *= vignette;

    fragColor = col;
}

// CRT scanlines + subtle text bloom for Ghostty

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    vec4 col = texture(iChannel0, uv);

    // --- Text bloom (wider radius, visible glow) ---
    float bloom = 0.0;
    float bloomRadius = 0.75;
    int samples = 5;
    for (int x = -samples; x <= samples; x++) {
        for (int y = -samples; y <= samples; y++) {
            vec2 offset = vec2(float(x), float(y)) * bloomRadius / iResolution.xy;
            bloom += length(texture(iChannel0, uv + offset).rgb);
        }
    }
    bloom /= float((2 * samples + 1) * (2 * samples + 1));

    vec3 glowColor = vec3(0.45, 0.55, 0.95);
    col.rgb += bloom * glowColor * 0.38;

    // --- CRT scanlines ---
    float scanline = sin(fragCoord.y * 2.0) * 0.5 + 0.5;
    scanline = mix(1.0, scanline, 0.40);
    col.rgb *= scanline;

    // --- Slight vignette ---
    vec2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 0.35;
    col.rgb *= vignette;

    fragColor = col;
}

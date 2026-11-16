shader_type canvas_item;
// The handheld look (ArtStyle.handheld): applied to the low-resolution 3D image as it
// is scaled to the screen. One texture read per pixel, nothing else.
//   1. Colour grade toward the settlement palette: shadows pushed toward indigo and
//      violet, highlights toward warm amber and rose, blacks slightly lifted and faded
//      with a violet cast, a little extra saturation in the mid-tones.
//   2. 15-bit colour (32 levels per channel, as on the DS) with a 4x4 ordered dither,
//      applied per source pixel so the dither pattern is as chunky as the pixels.
//   3. A soft vignette.

// indigo-violet shadows, warm amber-rose light: the settlement palette
uniform vec3 shadow_tint : source_color = vec3(0.4, 0.38, 0.66);
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.82, 0.7);
uniform float split = 0.22;
uniform float lift = 0.035;
uniform float fade = 0.06;
uniform float saturation = 1.12;
uniform float contrast = 1.06;
uniform float levels = 32.0;
uniform float dither = 1.0;
uniform float vignette = 0.28;

float bayer(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(m[y * 4 + x]) / 16.0 - 0.5;
}

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	// split toning by luminance
	vec3 tone = mix(shadow_tint, highlight_tint, smoothstep(0.08, 0.7, l));
	c = mix(c, c * tone * 1.25, split);
	// saturation and contrast around mid-grey
	c = mix(vec3(l), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	// lifted, faded blacks with a violet cast
	c = c * (1.0 - fade) + vec3(lift * 1.0, lift * 0.85, lift * 1.25);
	// 15-bit colour with ordered dither, in source pixels
	vec2 src = floor(UV / TEXTURE_PIXEL_SIZE);
	c += bayer(src) * dither / levels;
	c = floor(clamp(c, 0.0, 1.0) * (levels - 1.0) + 0.5) / (levels - 1.0);
	// vignette
	vec2 q = UV - 0.5;
	c *= 1.0 - dot(q, q) * vignette * 1.6;
	COLOR = vec4(c, 1.0);
}

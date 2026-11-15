shader_type canvas_item;
// Title screen backdrop: a planet seen from high orbit. One pass, three or four noise
// samples per pixel, no screen reads: fine on phones and in the Compatibility (web)
// renderer. Everything scrolls along the planet's limb at different speeds (ground,
// low cloud, high cloud), which is the parallax; noise repeats, so it loops forever.

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
// width / height of the rect
uniform float aspect = 1.7778;
// 1 on web and low-end devices: one cloud layer fewer and no light shafts
uniform float lite = 0.0;
uniform float speed = 1.0;
uniform vec3 amber : source_color = vec3(1.0, 0.62, 0.3);
uniform vec3 violet : source_color = vec3(0.36, 0.26, 0.52);
uniform vec3 indigo : source_color = vec3(0.045, 0.045, 0.11);

float nz(vec2 uv) {
	return texture(noise_tex, uv).r;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = vec2(UV.x * aspect, UV.y);
	// the limb: a very large circle whose edge crosses the screen from upper left to mid right
	vec2 c = vec2(-0.15, 6.17);
	float r = 6.0;
	vec2 d = p - c;
	float h = length(d) - r;            // > 0 in space, < 0 over the planet
	float breathe = 0.93 + 0.07 * sin(TIME * 0.21) + 0.03 * sin(TIME * 0.057 + 1.3);
	vec3 col;
	if (h > 0.0) {
		// space: indigo to deep violet, stars, the atmosphere's glow
		col = mix(indigo * 1.6, indigo * 0.5, clamp(h * 2.2, 0.0, 1.0));
		vec2 g = p * 90.0;
		vec2 cell = floor(g);
		float s = hash(cell);
		vec2 f = fract(g) - 0.5 - (vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5) * 0.6;
		float star = smoothstep(0.985, 1.0, s) * smoothstep(0.12, 0.0, length(f));
		star *= 0.55 + 0.45 * sin(TIME * (0.6 + s * 2.0) + s * 40.0);
		col += vec3(0.85, 0.88, 1.0) * star * smoothstep(0.02, 0.2, h);
		col += amber * exp(-h * 38.0) * 1.15 * breathe;
		col += mix(amber, violet, 0.55) * exp(-h * 9.0) * 0.5 * breathe;
		col += violet * exp(-h * 2.6) * 0.32;
		if (lite < 0.5) {
			// faint shafts of light rising off the limb
			float ang = atan(d.x, -d.y);
			float shaft = smoothstep(0.55, 0.9, nz(vec2(ang * 9.0 + TIME * 0.004 * speed, 0.37)));
			col += amber * shaft * exp(-h * 3.2) * 0.1 * smoothstep(0.0, 0.08, h);
		}
	} else {
		float t = -h;
		// surface coordinates: arc length along the limb, and depth foreshortened near it
		float u = atan(d.x, -d.y) * r;
		float v = sqrt(t) * 1.9;
		vec2 sv = vec2(u, v);
		float spin = TIME * 0.0035 * speed;
		// ground: dark forest and settlements that glow orange
		vec2 gv = sv * vec2(0.55, 0.8) + vec2(spin, 0.0);
		float land = nz(gv * 0.9);
		float fine = nz(gv * 6.0 + 0.31);
		vec3 ground = mix(vec3(0.012, 0.016, 0.03), vec3(0.05, 0.05, 0.085), fine * land);
		float town = smoothstep(0.56, 0.74, land);
		float lights = smoothstep(0.62, 0.8, nz(gv * 15.0 + 0.5)) * smoothstep(0.35, 0.7, fine);
		float flick = 0.8 + 0.2 * sin(TIME * 1.7 + fine * 60.0);
		ground += vec3(1.0, 0.33, 0.1) * lights * town * 1.5 * flick;
		ground += vec3(1.0, 0.45, 0.2) * town * town * 0.05;
		// low cloud deck, then a higher, faster one
		float sun = exp(-t * 4.5);          // how much of the low sun reaches this far in
		vec2 c1 = sv * vec2(0.4, 0.75) + vec2(spin * 1.8, 0.0);
		float low = smoothstep(0.42, 0.72, nz(c1) * 0.72 + nz(c1 * 2.7 + 0.2) * 0.28);
		vec3 low_col = mix(vec3(0.1, 0.09, 0.2), vec3(0.42, 0.36, 0.55), nz(c1 * 2.7 + 0.2));
		low_col = mix(low_col, amber * 1.05, sun * 0.8);
		col = mix(ground, low_col, low * 0.92);
		if (lite < 0.5) {
			vec2 c2 = sv * vec2(0.22, 0.5) + vec2(spin * 3.4 + 0.5, 0.13);
			float high = smoothstep(0.55, 0.85, nz(c2) * 0.8 + nz(c2 * 3.3) * 0.2);
			vec3 high_col = mix(vec3(0.2, 0.18, 0.34), vec3(0.62, 0.55, 0.72), sun + 0.25);
			col = mix(col, mix(high_col, amber, sun * 0.6), high * 0.55);
		}
		// the night side deepens away from the limb; haze gathers at the edge
		col *= mix(0.42, 1.0, exp(-t * 1.6));
		col += amber * exp(-t * 26.0) * 0.95 * breathe;
		col += mix(amber, violet, 0.6) * exp(-t * 5.0) * 0.22 * breathe;
	}
	// soft vignette
	vec2 q = UV - 0.5;
	col *= 1.0 - dot(q, q) * 0.55;
	COLOR = vec4(col, 1.0);
}

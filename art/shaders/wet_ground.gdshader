shader_type spatial;
// Rain-soaked ground for Anjabi. World-space, so any slab or terrain mesh tiles
// seamlessly with no UVs. Up-facing surfaces get cobblestones (staggered rows,
// per-stone tint, mortar joints, rounded bump), a wet sheen and puddles that pool in
// the joints; side faces get plain wet stone. Mobile-friendly: one noise texture,
// no screen reads.

render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.36, 0.35, 0.34, 1.0);
uniform vec4 mortar_color : source_color = vec4(0.10, 0.10, 0.11, 1.0);
// 1 = cobbles, 0 = plain wet ground (gravel, mud, moss).
uniform float cobble : hint_range(0.0, 1.0) = 1.0;
uniform float stone_size = 0.3;
uniform float wetness : hint_range(0.0, 1.0) = 0.8;
uniform float puddles : hint_range(0.0, 1.0) = 0.55;
uniform float bump_strength = 1.6;
// Terrain meshes carry their colour in COLOR.rgb (sRGB) and cobble amount in COLOR.a.
uniform bool use_vertex_color = false;
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// x: distance to the stone's edge (cells), y: per-stone random.
vec2 cobbles(vec2 p, float warp) {
	p += (warp - 0.5) * vec2(0.22, 0.16);
	p /= stone_size;
	float row = floor(p.y);
	p.x += mod(row, 2.0) * 0.5 + hash(vec2(row, 7.3)) * 0.35;
	p.x *= 0.72;
	// stones of varying width within a row
	p.x += hash(vec2(floor(p.x), row)) * 0.25;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 d = min(f, 1.0 - f);
	// rounded corners
	float e = min(d.x, d.y);
	float corner = length(max(vec2(0.18) - d, vec2(0.0)));
	e = min(e, 0.18 - corner);
	return vec2(e, hash(cell));
}

void fragment() {
	float up = smoothstep(0.55, 0.85, wnrm.y);
	vec3 col = base_color.rgb;
	float amount = cobble;
	float planks = 0.0;
	if (use_vertex_color) {
		col = pow(COLOR.rgb, vec3(2.2));
		// alpha: 1 = cobbles, ~0.5 = timber boardwalk, 0 = plain
		planks = step(0.3, COLOR.a) * step(COLOR.a, 0.7);
		amount = COLOR.a * (1.0 - planks);
	}
	amount *= up;
	float n = texture(noise_tex, wpos.xz * 0.06).r;
	float n2 = texture(noise_tex, wpos.xz * 0.5 + vec2(wpos.y * 0.3)).r;

	float warp = texture(noise_tex, wpos.xz * 0.9).r;
	vec2 c = cobbles(wpos.xz, warp);
	float stone = smoothstep(0.015, 0.07, c.x);
	float dome = smoothstep(0.0, 0.32, c.x);
	vec3 stone_col = col * (0.72 + 0.5 * c.y) * (0.8 + 0.4 * n2);
	stone_col = mix(stone_col, stone_col * vec3(1.08, 0.98, 0.9), step(0.8, c.y));
	vec3 joint_col = mortar_color.rgb * (0.7 + 0.6 * n2);
	vec3 paved = mix(joint_col, stone_col, stone);
	vec3 plain = col * (0.7 + 0.5 * n2) * (0.85 + 0.3 * n);
	// steep faces: layered rock with dark crevices and a little lichen
	float steep = 1.0 - up;
	float strata = texture(noise_tex, vec2((wpos.x + wpos.z) * 0.12, wpos.y * 0.9)).r;
	float crack = smoothstep(0.42, 0.5, texture(noise_tex, vec2((wpos.x - wpos.z) * 0.35, wpos.y * 1.6)).r);
	vec3 rock = col * vec3(1.0, 0.94, 0.86) * (0.35 + 0.95 * strata) * mix(0.35, 1.0, crack);
	rock = mix(rock, vec3(0.16, 0.22, 0.12), smoothstep(0.62, 0.75, n2) * 0.5);
	plain = mix(plain, rock, steep);
	col = mix(plain, paved, amount);
	// boardwalk: 0.28 m boards running east-west, staggered butt joints, dark gaps
	float bw = wpos.z / 0.28;
	float board = floor(bw);
	float fb = fract(bw);
	float along = fract((wpos.x + hash(vec2(board, 1.7)) * 5.0) / 2.6);
	float gap = smoothstep(0.0, 0.07, min(fb, 1.0 - fb)) * smoothstep(0.0, 0.012, min(along, 1.0 - along));
	vec3 wood = col * (0.7 + 0.5 * hash(vec2(board, 9.1))) * (0.85 + 0.3 * texture(noise_tex, vec2(wpos.x * 0.8, wpos.z * 6.0)).r);
	col = mix(col, mix(wood * 0.25, wood, gap), planks * up);
	stone = mix(stone, gap, planks * up);
	amount = max(amount, planks * up * 0.6);

	// puddles: low-frequency noise, pooling first in the joints
	float pool = n + (1.0 - stone) * 0.1 * amount - (1.0 - up) * 2.0;
	float puddle = smoothstep(0.6, 0.66, pool) * puddles;
	float wet = clamp(wetness * (0.65 + 0.35 * n2) + (1.0 - stone) * amount * 0.3, 0.0, 1.0);

	ALBEDO = col * mix(1.0, 0.5, wet);
	ALBEDO = mix(ALBEDO, ALBEDO * 0.3 + vec3(0.01, 0.015, 0.02), puddle);
	float rough = mix(0.82, 0.3, wet);
	rough = mix(rough, 0.92, steep);
	rough = mix(rough, 0.95, (1.0 - stone) * amount * (1.0 - wet * 0.6));
	ROUGHNESS = mix(rough, 0.03, puddle);
	SPECULAR = mix(0.55, 0.25, steep);

	// bump: rounded stones, flattened under puddles
	float h = dome * amount * (1.0 - puddle) * 0.03;
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	float dhdx = dFdx(h);
	float dhdy = dFdy(h);
	vec3 r1 = cross(dpdy, NORMAL);
	vec3 r2 = cross(NORMAL, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhdx * r1 + dhdy * r2);
	NORMAL = normalize(abs(det) * NORMAL - grad * bump_strength);
}

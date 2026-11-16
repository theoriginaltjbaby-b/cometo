shader_type spatial;
// Weathered ashlar for architecture: world-space courses of dressed stone blocks on
// walls (staggered, per-block tint, recessed mortar, chipped edges, damp at the foot),
// plain worn stone on tops. No UVs needed, so every box built in code tiles cleanly.

render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.52, 0.46, 0.44, 1.0);
uniform vec4 mortar_color : source_color = vec4(0.2, 0.17, 0.17, 1.0);
uniform float course = 0.42;
uniform float block = 0.9;
uniform float tint_var = 0.22;
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
global uniform float weather_wet;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float nz(vec2 uv) {
	return clamp((texture(noise_tex, uv).r - 0.6) / 0.45, 0.0, 1.0);
}

void fragment() {
	vec3 an = abs(wnrm);
	float wall = 1.0 - smoothstep(0.55, 0.8, an.y);
	// along-wall coordinate: x on walls facing z, z on walls facing x
	float u = an.z > an.x ? wpos.x : wpos.z;
	vec2 p = vec2(u, wpos.y);
	float row = floor(p.y / course);
	float w = block * (0.8 + 0.5 * hash(vec2(row, 3.1)));
	float x = p.x / w + mod(row, 2.0) * 0.5 + hash(vec2(row, 7.7));
	vec2 cell = vec2(floor(x), row);
	vec2 f = vec2(fract(x), fract(p.y / course));
	float edge = min(min(f.x, 1.0 - f.x) * w, min(f.y, 1.0 - f.y) * course);
	float n = nz(wpos.xz * 0.21 + vec2(wpos.y * 0.13));
	float chip = nz(p * 1.7 + cell * 0.37);
	float joint = smoothstep(0.012, 0.035 + chip * 0.02, edge);
	float r = hash(cell);
	vec3 stone = base_color.rgb * (1.0 - tint_var * 0.5 + tint_var * r) * (0.85 + 0.3 * n);
	// a few warmer and a few cooler blocks
	stone = mix(stone, stone * vec3(1.1, 0.98, 0.92), step(0.82, r));
	stone = mix(stone, stone * vec3(0.9, 0.95, 1.04), step(r, 0.12));
	vec3 col = mix(mortar_color.rgb * (0.8 + 0.4 * n), stone, joint);
	// tops: worn flat stone, no courses
	vec3 top = base_color.rgb * (0.9 + 0.25 * n) * (0.9 + 0.2 * nz(wpos.xz * 1.3));
	col = mix(top, col, wall);
	// damp, dark foot of every wall and grime under ledges
	float damp = (1.0 - smoothstep(0.0, 0.7, fract(wpos.y / 3.0) * 3.0)) * 0.25 * wall;
	col *= 1.0 - damp;
	float wet = weather_wet * 0.6;
	ALBEDO = col * mix(1.0, 0.7, wet);
	ROUGHNESS = mix(0.88, 0.45, wet) * mix(1.0, 1.08, 1.0 - joint);
	SPECULAR = 0.35;
	// bump: blocks proud of the mortar
	float h = joint * 0.02 * wall + chip * 0.004;
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	vec3 r1 = cross(dpdy, NORMAL);
	vec3 r2 = cross(NORMAL, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dFdx(h) * r1 + dFdy(h) * r2);
	NORMAL = normalize(abs(det) * NORMAL - grad * 1.4);
}

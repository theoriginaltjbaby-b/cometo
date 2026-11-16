shader_type spatial;
// The plaza's landmark inlay: a compass rose of aged brass set into the paving, with
// concentric bands and star points. Drawn on a flat disc in object space (XZ).

render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 stone : source_color = vec4(0.36, 0.32, 0.34, 1.0);
uniform vec4 brass : source_color = vec4(0.72, 0.52, 0.26, 1.0);
uniform vec4 dark : source_color = vec4(0.18, 0.15, 0.17, 1.0);
uniform float radius = 4.0;
global uniform float weather_wet;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

float ring(float r, float at, float w) {
	return smoothstep(w, w * 0.4, abs(r - at));
}

void fragment() {
	vec2 p = lp.xz / radius;
	float r = length(p);
	float a = atan(p.y, p.x);
	vec3 col = stone.rgb;
	float metal = 0.0;
	// dark band with ticks
	float band = smoothstep(0.78, 0.8, r) * smoothstep(0.93, 0.91, r);
	col = mix(col, dark.rgb, band);
	float ticks = band * step(0.82, r) * step(r, 0.9) * smoothstep(0.08, 0.03, abs(fract(a / (6.2831853 / 32.0)) - 0.5));
	metal = max(metal, ticks);
	metal = max(metal, ring(r, 0.78, 0.012) + ring(r, 0.93, 0.012) + ring(r, 0.99, 0.01) + ring(r, 0.36, 0.01));
	// eight-point star: long cardinal points, short diagonals
	float k = 6.2831853 / 8.0;
	float sa = mod(a + k * 0.5, k) - k * 0.5;
	float idx = floor((a + k * 0.5) / k);
	float len = mod(idx, 2.0) < 0.5 ? 0.76 : 0.46;
	float width = (1.0 - r / len) * 0.2;
	float point = step(r, len) * smoothstep(width, width * 0.7, abs(sa) * r * 2.6);
	// two-tone points: one half brass, the other dark
	float half = step(0.0, sa);
	col = mix(col, mix(dark.rgb * 1.3, brass.rgb * 0.85, half), point);
	metal = max(metal, point * half);
	metal = clamp(metal, 0.0, 1.0);
	col = mix(col, brass.rgb, metal);
	// centre boss
	float boss = smoothstep(0.075, 0.065, r);
	col = mix(col, brass.rgb * 1.1, boss);
	metal = max(metal, boss);
	ALBEDO = col;
	METALLIC = metal * 0.85;
	ROUGHNESS = mix(mix(0.85, 0.35, metal), 0.15, weather_wet * 0.7);
	SPECULAR = 0.5;
}

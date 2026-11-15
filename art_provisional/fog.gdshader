shader_type canvas_item;
// PROVISIONAL. Drifting sea mist plus a soft vignette. One layer, no screen read.

uniform vec4 fog_color : source_color = vec4(0.6, 0.69, 0.75, 1.0);
uniform float fog_amount = 0.11;
uniform float vignette = 0.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float n = noise(UV * vec2(3.0, 2.0) + vec2(TIME * 0.02, 0.0)) * 0.6
			+ noise(UV * vec2(7.0, 4.0) - vec2(TIME * 0.035, 0.0)) * 0.4;
	float fog = fog_amount * n * 1.6;
	float v = smoothstep(0.35, 0.85, distance(UV, vec2(0.5))) * vignette;
	vec3 col = mix(fog_color.rgb, vec3(0.01, 0.02, 0.04), v / (v + fog + 0.0001));
	COLOR = vec4(col, clamp(fog + v, 0.0, 0.9));
}

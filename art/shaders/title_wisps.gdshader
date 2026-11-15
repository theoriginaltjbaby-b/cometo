shader_type canvas_item;
// Thin cloud passing close to the camera, in front of the ship: the fastest parallax layer.

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float aspect = 1.7778;
uniform float speed = 1.0;

void fragment() {
	vec2 p = vec2(UV.x * aspect, UV.y);
	float t = TIME * 0.006 * speed;
	float n = texture(noise_tex, p * vec2(0.22, 0.5) + vec2(t, t * 0.15)).r * 0.7
		+ texture(noise_tex, p * vec2(0.6, 1.3) + vec2(t * 1.7, 0.4)).r * 0.3;
	float a = smoothstep(0.52, 0.85, n) * smoothstep(0.25, 0.95, UV.y) * 0.34;
	COLOR = vec4(mix(vec3(0.2, 0.18, 0.36), vec3(0.5, 0.44, 0.62), n), a);
}

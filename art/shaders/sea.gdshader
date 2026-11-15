shader_type spatial;
// Storm sea for Anjabi: two drifting noise layers make swell, glossy highlights catch
// the lamps and the afterglow, whitecaps form where the layers peak. World-space, so
// one big plane tiles anywhere. Mobile-friendly: one texture, no screen reads.

render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 deep : source_color = vec4(0.02, 0.06, 0.08, 1.0);
uniform vec4 shallow : source_color = vec4(0.06, 0.17, 0.19, 1.0);
uniform vec4 foam_color : source_color = vec4(0.62, 0.68, 0.7, 1.0);
uniform float speed = 0.02;
uniform float bump_strength = 2.2;
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = wpos.xz * 0.035;
	float t = TIME * speed;
	float a = texture(noise_tex, uv + vec2(t, t * 0.6)).r;
	float b = texture(noise_tex, uv * 2.7 - vec2(t * 1.4, -t * 0.8)).r;
	float c = texture(noise_tex, uv * 7.0 + vec2(-t * 2.0, t * 1.7)).r;
	float h = a * 0.55 + b * 0.3 + c * 0.15;
	vec3 col = mix(deep.rgb, shallow.rgb, smoothstep(0.3, 0.75, h));
	float foam = smoothstep(0.7, 0.82, a * 0.5 + b * 0.5) * smoothstep(0.45, 0.7, c);
	ALBEDO = mix(col, foam_color.rgb, foam * 0.6);
	ROUGHNESS = mix(0.05, 0.6, foam);
	SPECULAR = 0.7;
	float hh = h * 0.12;
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	vec3 r1 = cross(dpdy, NORMAL);
	vec3 r2 = cross(NORMAL, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dFdx(hh) * r1 + dFdy(hh) * r2);
	NORMAL = normalize(abs(det) * NORMAL - grad * bump_strength);
}

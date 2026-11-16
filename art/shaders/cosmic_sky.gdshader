shader_type sky;
// Cometographia's sky: a colossal ringed planet low in the north, a comet, stars and a
// faint nebula over a twilight gradient. No TIME, so the radiance map (reflections in
// the sea, puddles and glass) is only rebuilt when EnvironmentController changes the
// colours. Seen directly only in the arrival shot; everywhere else through reflections.

uniform vec3 zenith : source_color = vec3(0.09, 0.07, 0.2);
uniform vec3 horizon : source_color = vec3(0.55, 0.38, 0.55);
uniform vec3 glow : source_color = vec3(1.0, 0.62, 0.42);
// 0 at night, 1 by day: stars and nebula fade as it rises
uniform float day = 0.0;
// planet: direction (unit), angular radius (radians), colours
uniform vec3 planet_dir = vec3(0.34, 0.2, -0.92);
uniform float planet_r = 0.26;
uniform vec3 planet_a : source_color = vec3(0.95, 0.62, 0.62);
uniform vec3 planet_b : source_color = vec3(0.62, 0.4, 0.55);
uniform vec3 ring_col : source_color = vec3(0.98, 0.8, 0.74);
uniform vec3 sun_dir = vec3(-0.75, 0.3, 0.2);

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void sky() {
	vec3 d = EYEDIR;
	float up = d.y;
	// gradient: warm glow band at the horizon, deep violet-indigo overhead
	vec3 col = mix(horizon, zenith, smoothstep(-0.05, 0.6, up));
	col += glow * exp(-abs(up) * 9.0) * 0.55;
	col = mix(col, horizon * 0.35, smoothstep(0.0, -0.4, up));
	float night = 1.0 - day;
	// nebula and stars
	float neb = noise(d * 3.0) * 0.6 + noise(d * 7.0) * 0.4;
	col += mix(vec3(0.35, 0.18, 0.5), vec3(0.12, 0.35, 0.45), noise(d * 2.0 + 4.0)) * smoothstep(0.45, 0.85, neb) * 0.22 * night * smoothstep(0.0, 0.3, up);
	vec3 g = d * 220.0;
	float s = hash(floor(g));
	float star = smoothstep(0.992, 1.0, s) * smoothstep(0.35, 0.0, length(fract(g) - 0.5));
	col += vec3(0.9, 0.92, 1.0) * star * night * 1.4 * smoothstep(0.02, 0.2, up);
	// comet: a soft streak with a bright head, upper right
	vec3 ch = normalize(vec3(0.62, 0.62, -0.48));
	vec3 tail = normalize(vec3(0.9, 0.35, -0.25)) - ch;
	vec3 rel = d - ch;
	float along = dot(rel, normalize(tail));
	float across = length(rel - normalize(tail) * along);
	float comet = smoothstep(0.0, 0.02, along) * smoothstep(0.32, 0.0, along) * smoothstep(0.012 + along * 0.05, 0.0, across);
	col += vec3(0.75, 0.88, 1.0) * (comet * 0.7 + smoothstep(0.012, 0.0, length(rel)) * 1.5) * (0.35 + 0.65 * night);
	// the planet: a sphere at distance 1 with radius sin(planet_r), and its rings
	vec3 P = planet_dir;
	float R = sin(planet_r);
	float b = dot(d, P);
	float disc = b * b - (dot(P, P) - R * R);
	float t_sphere = disc > 0.0 ? b - sqrt(disc) : 1e9;
	vec3 n_ring = normalize(vec3(0.25, 0.94, 0.22));
	float denom = dot(d, n_ring);
	float t_ring = abs(denom) > 1e-4 ? dot(P, n_ring) / denom : 1e9;
	float ring_r = t_ring > 0.0 && t_ring < 1e8 ? length(d * t_ring - P) / R : 0.0;
	float ring = smoothstep(1.45, 1.5, ring_r) * smoothstep(2.35, 2.25, ring_r);
	ring *= 0.55 + 0.45 * sin(ring_r * 38.0) * sin(ring_r * 13.0 + 1.0);
	ring *= 1.0 - smoothstep(1.86, 1.9, ring_r) * smoothstep(1.98, 1.94, ring_r) * 0.85;
	if (t_sphere < 1e8) {
		vec3 hit = d * t_sphere;
		vec3 nrm = normalize(hit - P);
		// latitude bands in the planet's frame (tilted with the rings)
		float lat = dot(nrm, n_ring);
		float bands = noise(vec3(lat * 14.0, lat * 3.0, 0.0)) * 0.7 + noise(vec3(lat * 40.0, nrm.x * 2.0, nrm.z * 2.0)) * 0.3;
		vec3 pc = mix(planet_b, planet_a, bands);
		float lit = clamp(dot(nrm, normalize(sun_dir)) * 0.9 + 0.25, 0.0, 1.0);
		pc *= mix(0.12, 1.15, lit);
		// limb glow
		pc += planet_a * pow(1.0 - clamp(dot(nrm, -d), 0.0, 1.0), 3.0) * 0.35;
		float edge = smoothstep(0.0, 0.0006, disc);
		col = mix(col, pc, edge * (0.82 + 0.18 * day));
		// the ring passes in front of the near half
		if (t_ring > 0.0 && t_ring < t_sphere) {
			col = mix(col, ring_col * (0.7 + 0.3 * lit), ring * 0.8);
		} else if (t_ring > t_sphere) {
			// the planet's shadow side darkens the ring behind it: nothing to draw
		}
	} else if (t_ring > 0.0 && t_ring < 1e8) {
		col = mix(col, ring_col, ring * 0.75);
	}
	COLOR = col;
}

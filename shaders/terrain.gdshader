shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform float wind_strength = 0.3;
uniform float wind_speed = 1.5;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Add bumpy ground displacement
	float bump1 = sin(world_position.x * 0.3) * cos(world_position.z * 0.2);
	float bump2 = sin(world_position.x * 0.8) * cos(world_position.z * 0.6) * 0.5;
	float bump3 = sin(world_position.x * 1.5) * cos(world_position.z * 1.2) * 0.3;
	float bumps = (bump1 + bump2 + bump3) * 0.15; // Small bumps (0.15m variation)

	// Apply bumps to ground
	VERTEX.y += bumps;

	// Simple wind animation on grass texture
	float time = TIME * wind_speed;
	float wind_wave = sin(world_position.x * 0.5 + time) * cos(world_position.z * 0.3 + time * 0.7);
	VERTEX.x += wind_wave * wind_strength * 0.05;
	VERTEX.z += wind_wave * wind_strength * 0.03;
}

// Simple hash function for noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D noise function
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for(int i = 0; i < 5; i++) {
		value += amplitude * noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 pos = world_position.xz;

	// Grass texture pattern
	float blade_pattern = abs(sin(pos.x * 35.0) * sin(pos.y * 25.0));
	blade_pattern = pow(blade_pattern, 0.25);

	float blade_variation = fbm(pos * 2.5);
	float blades = mix(blade_pattern, blade_variation, 0.4);

	// Noise for color variation
	float noise1 = fbm(pos * 0.15);
	float noise2 = fbm(pos * 0.8);
	float noise3 = fbm(pos * 3.5);

	// Green grass colors (brighter, more visible)
	vec3 grass_dark = vec3(0.15, 0.35, 0.1);      // Dark green
	vec3 grass_base = vec3(0.25, 0.55, 0.2);      // Medium green (base ground)
	vec3 grass_light = vec3(0.35, 0.65, 0.25);    // Lighter green

	vec3 color = mix(grass_dark, grass_base, noise1 * 0.9);
	color = mix(color, grass_light, blades * 0.6);
	color *= 0.7 + blades * 0.2;  // Natural brightness

	ALBEDO = color;
	ROUGHNESS = 0.9;
	SPECULAR = 0.05;
}
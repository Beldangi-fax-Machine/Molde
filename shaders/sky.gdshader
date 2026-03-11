shader_type sky;

// Hash function for noise
float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// 3D noise function
float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y),
		f.z
	);
}

// Fractal Brownian Motion for clouds
float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for(int i = 0; i < 6; i++) {
		value += amplitude * noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void sky() {
	vec3 ray_dir = EYEDIR;
	float height = ray_dir.y;

	// Sky gradient colors
	vec3 horizon_color = vec3(0.6, 0.75, 0.95);  // Light blue at horizon
	vec3 zenith_color = vec3(0.2, 0.5, 0.95);    // Deeper blue at top

	// Create gradient based on viewing angle
	float gradient = smoothstep(-0.1, 0.4, height);
	vec3 sky_color = mix(horizon_color, zenith_color, gradient);

	// Only add clouds if looking above horizon
	if (height > 0.0) {
		// Sample clouds with time-based movement
		vec3 cloud_pos = ray_dir * (20.0 / max(height, 0.1));
		cloud_pos.x += TIME * 0.03;  // Slower wind
		cloud_pos.z += TIME * 0.01;

		// Multi-layer clouds for depth - much larger scale for spread out clouds
		float cloud_noise = fbm(cloud_pos * 0.15);  // Reduced from 0.8
		float cloud_detail = fbm(cloud_pos * 0.4);  // Reduced from 2.0

		// Combine noise layers
		float clouds = cloud_noise * 0.6 + cloud_detail * 0.4;

		// Make clouds more sparse and wispy
		clouds = smoothstep(0.55, 0.75, clouds);  // Higher threshold for less coverage

		// Fade clouds near horizon
		clouds *= smoothstep(0.0, 0.3, height);

		// Cloud color (white with slight blue tint)
		vec3 cloud_color = vec3(0.95, 0.97, 1.0);

		// Add soft shadows to clouds for depth
		float cloud_shadow = fbm(cloud_pos * 0.3 + vec3(0.1, 0.1, 0.1)) * 0.25;
		cloud_color -= vec3(cloud_shadow * clouds);

		// Blend clouds with sky - reduced opacity
		sky_color = mix(sky_color, cloud_color, clouds * 0.7);
	}

	// Add atmospheric haze near horizon
	float haze = exp(-abs(height) * 2.0) * 0.15;
	sky_color = mix(sky_color, horizon_color, haze);

	COLOR = sky_color;
}

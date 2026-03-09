shader_type spatial;

void fragment() {
	// Use world position from camera view to create stationary pattern
	vec3 world_pos = (inverse(VIEW) * vec4(VERTEX, 1.0)).xyz;
	
	// Large checkerboard squares so movement is obvious
	float checker_size = 20.0;
	float checker_x = mod(floor(world_pos.x / checker_size), 2.0);
	float checker_z = mod(floor(world_pos.z / checker_size), 2.0);
	float pattern = mod(checker_x + checker_z, 2.0);
	
	// Dark grass base color
	vec3 grass_dark = vec3(0.08, 0.3, 0.08);
	vec3 grass_light = vec3(0.15, 0.45, 0.12);
	
	vec3 color = mix(grass_dark, grass_light, pattern);
	
	// Apply lighting for depth
	vec3 normal = normalize(NORMAL);
	float light = dot(normal, normalize(vec3(0.7, 1.0, 0.5)));
	light = light * 0.6 + 0.4;
	
	ALBEDO = color * light;
	ROUGHNESS = 0.85;
	METALLIC = 0.0;
}
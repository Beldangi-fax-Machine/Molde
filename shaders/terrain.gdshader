shader_type spatial;
render_mode cull_back;

void fragment() {
	// Get world position 
	vec3 world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Checkerboard pattern
	float checker_size = 10.0;
	float checker_x = mod(floor(world_pos.x / checker_size), 2.0);
	float checker_z = mod(floor(world_pos.z / checker_size), 2.0);
	float pattern = mod(checker_x + checker_z, 2.0);
	
	// Green colors for grass
	vec3 dark_green = vec3(0.1, 0.35, 0.1);
	vec3 light_green = vec3(0.2, 0.5, 0.15);
	
	// Mix between dark and light green
	vec3 color = mix(dark_green, light_green, pattern);
	
	ALBEDO = color;
	ROUGHNESS = 0.8;
}
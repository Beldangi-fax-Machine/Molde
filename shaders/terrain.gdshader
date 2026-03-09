shader_type spatial;
render_mode cull_back;

void fragment() {
	// Get world position 
	vec3 world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Checkerboard pattern
	float checker_size = 15.0;
	float checker_x = mod(floor(world_pos.x / checker_size), 2.0);
	float checker_z = mod(floor(world_pos.z / checker_size), 2.0);
	float pattern = mod(checker_x + checker_z, 2.0);
	
	// Vibrant green colors for grass
	vec3 dark_green = vec3(0.0, 0.6, 0.0);
	vec3 bright_green = vec3(0.2, 0.8, 0.0);
	
	// Mix between dark and bright green
	vec3 color = mix(dark_green, bright_green, pattern);
	
	ALBEDO = color;
	ROUGHNESS = 0.7;
}
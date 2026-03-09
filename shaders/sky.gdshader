shader_type sky;

void sky() {
	// Create a sky gradient from blue to lighter blue
	vec3 up = normalize(LIGHT0_DIRECTION);
	float height = max(NORMAL.y, 0.0);
	
	// Sky blue to light blue gradient
	vec3 sky_color = mix(vec3(0.5, 0.8, 1.0), vec3(0.3, 0.6, 1.0), height);
	
	COLOR = sky_color;
}

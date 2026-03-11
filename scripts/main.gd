extends Node3D

# Day/night cycle variables
var sun_light: DirectionalLight3D
var world_environment: WorldEnvironment
var sky_material: ShaderMaterial
var day_length: float = 1440.0  # 24 minutes in seconds (24 * 60)
var time_of_day: float = 360.0  # Start at 6 AM (quarter day)

func _ready():
	print("Main scene ready")

	# Set up environment with sky shader (includes clouds)
	world_environment = WorldEnvironment.new()
	var env = Environment.new()

	# Sky with shader-based clouds
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	sky_material = ShaderMaterial.new()
	sky_material.shader = load("res://shaders/sky.gdshader")
	sky.sky_material = sky_material
	env.sky = sky

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8

	# Add some atmospheric effects
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.05
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.15

	world_environment.environment = env
	add_child(world_environment)

	# Add a directional light (sun) with shadows
	sun_light = DirectionalLight3D.new()
	sun_light.light_color = Color.WHITE
	sun_light.light_energy = 1.0
	sun_light.shadow_enabled = true
	sun_light.shadow_blur = 1.0
	add_child(sun_light)
	
	# Instantiate the terrain FIRST
	var terrain_scene = preload("res://scenes/Terrain.tscn")
	var terrain = terrain_scene.instantiate()
	add_child(terrain)
	
	# Instantiate the player AFTER terrain
	var player_scene = preload("res://scenes/Player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector3(0, 2, 0)  # Spawn just above ground
	player.name = "Player"  # Ensure name matches for time block detection
	add_child(player)

	# Add colored blocks around the world
	_add_colored_blocks()

	# Add camera to player
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	player.add_child(camera)
	camera.position.y = 1.5

func _add_colored_blocks() -> void:
	# Red block - MORNING (6 AM)
	_create_time_block(Vector3(40, 4, 40), Color.RED, 360.0, "Morning")

	# Blue block - MIDDAY (12 PM / Noon)
	_create_time_block(Vector3(-40, 4, 40), Color.BLUE, 720.0, "Midday")

	# Green block - EVENING (6 PM)
	_create_time_block(Vector3(40, 4, -40), Color(0.2, 0.8, 0.2), 1080.0, "Evening")

	# Yellow block - NIGHT (12 AM / Midnight)
	_create_time_block(Vector3(-40, 4, -40), Color.YELLOW, 0.0, "Night")

func _create_time_block(pos: Vector3, color: Color, time_value: float, time_name: String) -> void:
	# Create visual block
	var block = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(8, 8, 8)
	block.mesh = mesh
	block.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy = 0.3  # Slight glow
	block.set_surface_override_material(0, mat)
	add_child(block)

	# Create trigger area
	var area = Area3D.new()
	area.position = pos
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(12, 12, 12)  # Larger than visual block
	collision_shape.shape = box_shape
	area.add_child(collision_shape)
	add_child(area)

	# Connect signal for when player enters
	area.body_entered.connect(func(body):
		if body.name == "Player":
			time_of_day = time_value
			print("Time changed to: ", time_name, " (", time_value, " seconds)")
	)

func _process(delta: float) -> void:
	# Update day/night cycle
	time_of_day += delta
	if time_of_day >= day_length:
		time_of_day = 0.0  # Reset to midnight after 24 minutes

	# Calculate time as percentage of day (0.0 = midnight, 0.5 = noon)
	var day_progress = time_of_day / day_length

	# Calculate sun angle (rotates around X axis)
	# 0.0 (midnight) = sun below horizon
	# 0.25 (6 AM) = sunrise
	# 0.5 (noon) = sun overhead
	# 0.75 (6 PM) = sunset
	# 1.0 (midnight) = sun below horizon
	var sun_angle = day_progress * TAU  # Full rotation over 24 minutes
	sun_light.rotation.x = sun_angle - PI/2  # Offset so noon is overhead
	sun_light.rotation.y = 0.3  # Slight angle for visual interest

	# Calculate sun intensity based on height
	var sun_height = -cos(sun_angle)  # -1 (midnight) to 1 (noon)
	var is_day = sun_height > 0.0

	if is_day:
		# Daytime: full brightness
		var day_brightness = sun_height  # 0 to 1
		sun_light.light_energy = 0.5 + day_brightness * 0.5  # 0.5 to 1.0
		sun_light.light_color = Color(1.0, 0.95, 0.9)  # Warm white
		# Ambient light
		world_environment.environment.ambient_light_energy = 0.5 + day_brightness * 0.3
	else:
		# Nighttime: low light
		sun_light.light_energy = 0.1  # Moonlight
		sun_light.light_color = Color(0.6, 0.7, 1.0)  # Cool blue moonlight
		# Dim ambient light at night
		world_environment.environment.ambient_light_energy = 0.15

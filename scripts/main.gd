extends Node3D

func _ready():
	print("Main scene ready")
	
	# Set up environment with simple sky
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.8, 1.0)  # Light blue sky
	
	world_env.environment = env
	add_child(world_env)
	
	# Add a directional light for visibility with shadows
	var sun = DirectionalLight3D.new()
	sun.rotation.x = -0.3  # Higher angle
	sun.rotation.y = 0.3
	sun.shadow_enabled = true
	sun.shadow_blur = 1.0
	add_child(sun)
	
	# Create a visual sun in the sky (much higher)
	var sun_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 5.0
	sphere.height = 10.0
	sun_mesh.mesh = sphere
	
	# Position the sun much higher in the sky
	sun_mesh.position = Vector3(80, 150, -80)
	
	# Create sun material
	var sun_mat = StandardMaterial3D.new()
	sun_mat.albedo_color = Color.YELLOW
	sun_mat.emission_enabled = true
	sun_mat.emission = Color.YELLOW
	sun_mat.emission_energy = 3.0
	sun_mesh.set_surface_override_material(0, sun_mat)
	
	add_child(sun_mesh)
	
	# Instantiate the terrain FIRST
	var terrain = Node3D.new()
	terrain.script = load("res://scripts/terrain.gd")
	add_child(terrain)
	
	# Instantiate the player AFTER terrain
	var player_scene = preload("res://scenes/Player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector3(0, 5, 0)
	add_child(player)
	
	# Add colored blocks around the world
	_add_colored_blocks()
	
	# Add camera to player
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	player.add_child(camera)
	camera.position.y = 1.5

func _add_colored_blocks() -> void:
	# Red block
	var red_block = MeshInstance3D.new()
	var red_mesh = BoxMesh.new()
	red_mesh.size = Vector3(8, 8, 8)
	red_block.mesh = red_mesh
	red_block.position = Vector3(40, 7, 40)
	
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color.RED
	red_mat.roughness = 0.6
	red_block.set_surface_override_material(0, red_mat)
	add_child(red_block)
	
	# Blue block
	var blue_block = MeshInstance3D.new()
	var blue_mesh = BoxMesh.new()
	blue_mesh.size = Vector3(8, 8, 8)
	blue_block.mesh = blue_mesh
	blue_block.position = Vector3(-40, 7, 40)
	
	var blue_mat = StandardMaterial3D.new()
	blue_mat.albedo_color = Color.BLUE
	blue_mat.roughness = 0.6
	blue_block.set_surface_override_material(0, blue_mat)
	add_child(blue_block)
	
	# Green block
	var green_block = MeshInstance3D.new()
	var green_mesh = BoxMesh.new()
	green_mesh.size = Vector3(8, 8, 8)
	green_block.mesh = green_mesh
	green_block.position = Vector3(40, 7, -40)
	
	var green_mat = StandardMaterial3D.new()
	green_mat.albedo_color = Color(0.2, 0.8, 0.2)
	green_mat.roughness = 0.6
	green_block.set_surface_override_material(0, green_mat)
	add_child(green_block)
	
	# Yellow block
	var yellow_block = MeshInstance3D.new()
	var yellow_mesh = BoxMesh.new()
	yellow_mesh.size = Vector3(8, 8, 8)
	yellow_block.mesh = yellow_mesh
	yellow_block.position = Vector3(-40, 7, -40)
	
	var yellow_mat = StandardMaterial3D.new()
	yellow_mat.albedo_color = Color.YELLOW
	yellow_mat.roughness = 0.6
	yellow_block.set_surface_override_material(0, yellow_mat)
	add_child(yellow_block)

extends Node3D

func _ready():
	print("Main scene ready")
	
	# Set up environment with gradient sky
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	
	# Create sky gradient
	var sky = Sky.new()
	var sky_material = StandardMaterial3D.new()
	sky_material.albedo_color = Color(0.5, 0.8, 1.0)
	sky.material = sky_material
	env.sky = sky
	
	world_env.environment = env
	add_child(world_env)
	
	# Add a directional light for visibility with shadows
	var sun = DirectionalLight3D.new()
	sun.rotation.x = -0.3  # Higher angle
	sun.rotation.y = 0.3
	sun.shadow_enabled = true
	sun.shadow_blur = 1.0
	sun.omni_range = 500.0
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
	
	# Add camera to player
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	player.add_child(camera)
	camera.position.y = 1.5

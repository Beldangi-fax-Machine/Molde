extends Node3D

func _ready():
	print("Main scene ready")
	
	# Set up environment with simple gradient sky
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.8, 1.0)  # Light blue sky
	
	world_env.environment = env
	add_child(world_env)
	
	# Add a directional light for visibility
	var sun = DirectionalLight3D.new()
	sun.rotation.x = -0.5
	sun.rotation.y = 0.3
	add_child(sun)
	
	# Create a visual sun in the sky
	var sun_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 3.0
	sphere.height = 6.0
	sun_mesh.mesh = sphere
	
	# Position the sun in the sky
	sun_mesh.position = Vector3(50, 40, -50)
	
	# Create sun material
	var sun_mat = StandardMaterial3D.new()
	sun_mat.albedo_color = Color.YELLOW
	sun_mat.emission_enabled = true
	sun_mat.emission = Color.YELLOW
	sun_mat.emission_energy = 2.0
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

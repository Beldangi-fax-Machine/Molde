extends Node3D

var _viewer_node: Node3D

func _ready() -> void:
	_viewer_node = get_parent().get_node_or_null("Player")
	if _viewer_node == null:
		_viewer_node = self
	
	# Create a simple flat base ground instead of procedural terrain
	_create_flat_ground()

func _create_flat_ground() -> void:
	# Create checkerboard ground with alternating green squares
	var square_size = 30.0
	var ground_size = 500.0
	var half_size = ground_size / 2.0
	
	# Create a grid of alternating colored squares
	var x = -half_size
	while x < half_size:
		var z = -half_size
		while z < half_size:
			# Determine if this square should be dark or bright green
			var grid_x = int(x / square_size)
			var grid_z = int(z / square_size)
			var is_dark = (grid_x + grid_z) % 2 == 0
			
			# Create a plane for this square
			var mesh = PlaneMesh.new()
			mesh.size = Vector2(square_size, square_size)
			
			var mesh_inst = MeshInstance3D.new()
			mesh_inst.mesh = mesh
			mesh_inst.position = Vector3(x + square_size / 2.0, 3.5, z + square_size / 2.0)
			
			# Create material with appropriate green color
			var mat = StandardMaterial3D.new()
			if is_dark:
				mat.albedo_color = Color(0.0, 0.5, 0.0)  # Dark green
			else:
				mat.albedo_color = Color(0.2, 0.8, 0.1)  # Bright green
			mat.roughness = 0.8
			
			mesh_inst.set_surface_override_material(0, mat)
			add_child(mesh_inst)
			
			z += square_size
		x += square_size
	
	# Add single collision box for the entire ground
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(ground_size, 2, ground_size)
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	static_body.position = Vector3(0, 2.5, 0)
	add_child(static_body)

func _process(_delta: float) -> void:
	pass

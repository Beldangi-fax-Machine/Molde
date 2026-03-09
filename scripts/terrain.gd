extends Node3D

var _viewer_node: Node3D

func _ready() -> void:
	_viewer_node = get_parent().get_node_or_null("Player")
	if _viewer_node == null:
		_viewer_node = self
	
	# Create a simple flat base ground instead of procedural terrain
	_create_flat_ground()

func _create_flat_ground() -> void:
	# Create a simple flat plane for walking on
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(500, 500)
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.position.y = 3.5
	
	# Load and apply shader material
	var shader = load("res://shaders/terrain.gdshader") as Shader
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mesh_inst.set_surface_override_material(0, mat)
	else:
		# Fallback to standard material if shader not found
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.35, 0.1)
		mat.roughness = 0.9
		mesh_inst.set_surface_override_material(0, mat)
	
	add_child(mesh_inst)
	
	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(500, 2, 500)
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	static_body.position = Vector3(0, 2.5, 0)
	add_child(static_body)

func _process(_delta: float) -> void:
	pass

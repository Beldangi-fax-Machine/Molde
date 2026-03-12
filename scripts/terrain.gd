extends Node3D

# Terrain with actual deformable mesh and grass
var _viewer_node: Node3D
var _terrain_chunks: Dictionary = {}
var _chunk_size: float = 50.0
var _subdivisions: int = 25  # Lower for low-poly look
var _render_distance: int = 2
var _last_player_chunk: Vector2i = Vector2i(9999, 9999)

# Grass script reference
var GrassScript = preload("res://addons/simplegrasstextured/grass.gd")

func _ready() -> void:
	_viewer_node = get_parent().get_node_or_null("Player")
	if _viewer_node == null:
		_viewer_node = self
	_update_terrain_chunks()

func _generate_terrain_mesh(chunk_x: int, chunk_z: int) -> ArrayMesh:
	# Create actual vertex mesh with bumps baked in
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertex_count = _subdivisions + 1
	var step = _chunk_size / float(_subdivisions)
	var half_size = _chunk_size / 2.0

	# Generate vertices with actual height displacement
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var uvs: Array[Vector2] = []

	for z in range(vertex_count):
		for x in range(vertex_count):
			var local_x = x * step - half_size
			var local_z = z * step - half_size

			# World position for noise sampling
			var world_x = chunk_x * _chunk_size + local_x
			var world_z = chunk_z * _chunk_size + local_z

			# Generate bumpy height using multiple frequencies
			var height = _get_terrain_height(world_x, world_z)

			vertices.append(Vector3(local_x, height, local_z))
			uvs.append(Vector2(float(x) / _subdivisions, float(z) / _subdivisions))

	# Calculate normals and build triangles
	for z in range(_subdivisions):
		for x in range(_subdivisions):
			var idx = z * vertex_count + x
			var idx_right = idx + 1
			var idx_down = idx + vertex_count
			var idx_down_right = idx + vertex_count + 1

			# Get vertices for this quad
			var v0 = vertices[idx]
			var v1 = vertices[idx_right]
			var v2 = vertices[idx_down]
			var v3 = vertices[idx_down_right]

			# Triangle 1
			var normal1 = (v1 - v0).cross(v2 - v0).normalized()
			st.set_normal(normal1)
			st.set_uv(uvs[idx])
			st.add_vertex(v0)
			st.set_uv(uvs[idx_right])
			st.add_vertex(v1)
			st.set_uv(uvs[idx_down])
			st.add_vertex(v2)

			# Triangle 2
			var normal2 = (v2 - v1).cross(v3 - v1).normalized()
			st.set_normal(normal2)
			st.set_uv(uvs[idx_right])
			st.add_vertex(v1)
			st.set_uv(uvs[idx_down_right])
			st.add_vertex(v3)
			st.set_uv(uvs[idx_down])
			st.add_vertex(v2)

	st.generate_tangents()
	return st.commit()

func _get_terrain_height(world_x: float, world_z: float) -> float:
	# Multi-frequency noise for natural bumpy terrain
	var height = 0.0

	# Large rolling hills
	height += sin(world_x * 0.02) * cos(world_z * 0.015) * 1.5

	# Medium bumps
	height += sin(world_x * 0.08) * cos(world_z * 0.06) * 0.6
	height += cos(world_x * 0.12) * sin(world_z * 0.1) * 0.4

	# Small detail bumps (low-poly feel)
	height += sin(world_x * 0.25) * cos(world_z * 0.2) * 0.2
	height += sin(world_x * 0.4 + world_z * 0.3) * 0.15

	return height

func _create_terrain_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.45, 0.18)  # Earthy green
	mat.roughness = 0.85
	mat.metallic = 0.0
	return mat

func _create_dirt_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.25, 0.15)  # Brown dirt
	mat.roughness = 0.95
	mat.metallic = 0.0
	return mat

func _create_terrain_chunk(chunk_x: int, chunk_z: int) -> Node3D:
	var chunk_root = Node3D.new()
	chunk_root.name = "Chunk_" + str(chunk_x) + "_" + str(chunk_z)

	# Position chunk in world
	var chunk_world_x = chunk_x * _chunk_size
	var chunk_world_z = chunk_z * _chunk_size
	chunk_root.position = Vector3(chunk_world_x, 0.0, chunk_world_z)

	# Create the terrain mesh
	var terrain_mesh = _generate_terrain_mesh(chunk_x, chunk_z)

	# Top surface (grass layer)
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "TerrainMesh"
	mesh_inst.mesh = terrain_mesh
	mesh_inst.set_surface_override_material(0, _create_terrain_material())
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	chunk_root.add_child(mesh_inst)

	# Create collision from mesh
	var static_body = StaticBody3D.new()
	static_body.name = "TerrainCollision"
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = terrain_mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)
	chunk_root.add_child(static_body)

	# Add dirt layer underneath (visible when digging)
	var dirt_mesh_inst = MeshInstance3D.new()
	dirt_mesh_inst.name = "DirtLayer"
	dirt_mesh_inst.mesh = _generate_dirt_layer_mesh(chunk_x, chunk_z)
	dirt_mesh_inst.set_surface_override_material(0, _create_dirt_material())
	dirt_mesh_inst.position.y = -0.5  # Below the grass layer
	chunk_root.add_child(dirt_mesh_inst)

	# Spawn grass on top using SimpleGrassTextured
	_spawn_grass_on_chunk(chunk_root, chunk_x, chunk_z)

	return chunk_root

func _generate_dirt_layer_mesh(chunk_x: int, chunk_z: int) -> ArrayMesh:
	# Create a simpler mesh for the dirt layer below
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertex_count = 10  # Lower resolution for dirt
	var step = _chunk_size / float(vertex_count - 1)
	var half_size = _chunk_size / 2.0

	for z in range(vertex_count - 1):
		for x in range(vertex_count - 1):
			var x0 = x * step - half_size
			var z0 = z * step - half_size
			var x1 = (x + 1) * step - half_size
			var z1 = (z + 1) * step - half_size

			# World coords for height sampling
			var wx0 = chunk_x * _chunk_size + x0
			var wz0 = chunk_z * _chunk_size + z0
			var wx1 = chunk_x * _chunk_size + x1
			var wz1 = chunk_z * _chunk_size + z1

			# Get heights matching terrain surface
			var h00 = _get_terrain_height(wx0, wz0)
			var h10 = _get_terrain_height(wx1, wz0)
			var h01 = _get_terrain_height(wx0, wz1)
			var h11 = _get_terrain_height(wx1, wz1)

			var v0 = Vector3(x0, h00, z0)
			var v1 = Vector3(x1, h10, z0)
			var v2 = Vector3(x0, h01, z1)
			var v3 = Vector3(x1, h11, z1)

			# Build triangles
			var normal = Vector3.UP
			st.set_normal(normal)

			st.set_uv(Vector2(0, 0))
			st.add_vertex(v0)
			st.set_uv(Vector2(1, 0))
			st.add_vertex(v1)
			st.set_uv(Vector2(0, 1))
			st.add_vertex(v2)

			st.set_uv(Vector2(1, 0))
			st.add_vertex(v1)
			st.set_uv(Vector2(1, 1))
			st.add_vertex(v3)
			st.set_uv(Vector2(0, 1))
			st.add_vertex(v2)

	return st.commit()

func _spawn_grass_on_chunk(chunk_root: Node3D, chunk_x: int, chunk_z: int) -> void:
	# Create grass using SimpleGrassTextured
	var grass = GrassScript.new()
	grass.name = "Grass"

	# Grass settings
	grass.scale_h = 0.8
	grass.scale_w = 0.6
	grass.scale_var = -0.3
	grass.grass_strength = 0.5
	grass.interactive = true
	grass.albedo = Color(0.4, 0.7, 0.3)  # Bright grass green

	chunk_root.add_child(grass)

	# Wait for grass to be ready, then populate
	grass.ready.connect(func():
		_populate_grass(grass, chunk_x, chunk_z)
	)

func _populate_grass(grass_node, chunk_x: int, chunk_z: int) -> void:
	var half_size = _chunk_size / 2.0
	var grass_density = 0.8  # Distance between grass blades
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(Vector2(chunk_x, chunk_z))

	var transforms: Array[Transform3D] = []

	var x = -half_size
	while x < half_size:
		var z = -half_size
		while z < half_size:
			# Add some randomization to position
			var offset_x = rng.randf_range(-0.3, 0.3)
			var offset_z = rng.randf_range(-0.3, 0.3)
			var local_x = x + offset_x
			var local_z = z + offset_z

			# World position for height
			var world_x = chunk_x * _chunk_size + local_x
			var world_z = chunk_z * _chunk_size + local_z
			var height = _get_terrain_height(world_x, world_z)

			# Skip some grass randomly for natural look
			if rng.randf() > 0.7:
				z += grass_density
				continue

			var pos = Vector3(local_x, height, local_z)
			var normal = _get_terrain_normal(world_x, world_z)
			var scale = Vector3.ONE * rng.randf_range(0.6, 1.2)
			var rotation = rng.randf() * TAU

			var trans = grass_node.eval_grass_transform(pos, normal, scale, rotation)
			transforms.append(trans)

			z += grass_density
		x += grass_density

	# Add all grass at once
	if transforms.size() > 0:
		grass_node.add_grass_batch(transforms)

func _get_terrain_normal(world_x: float, world_z: float) -> Vector3:
	# Calculate normal from height differences
	var delta = 0.5
	var h_center = _get_terrain_height(world_x, world_z)
	var h_right = _get_terrain_height(world_x + delta, world_z)
	var h_forward = _get_terrain_height(world_x, world_z + delta)

	var dx = h_right - h_center
	var dz = h_forward - h_center

	return Vector3(-dx, delta, -dz).normalized()

func _update_terrain_chunks() -> void:
	if not _viewer_node or not is_instance_valid(_viewer_node):
		return

	var player_pos = _viewer_node.global_position
	var player_chunk_x = int(floor(player_pos.x / _chunk_size))
	var player_chunk_z = int(floor(player_pos.z / _chunk_size))
	var player_chunk = Vector2i(player_chunk_x, player_chunk_z)

	if player_chunk == _last_player_chunk:
		return

	_last_player_chunk = player_chunk

	var chunks_to_keep: Dictionary = {}

	for x in range(-_render_distance, _render_distance + 1):
		for z in range(-_render_distance, _render_distance + 1):
			var chunk_x = player_chunk_x + x
			var chunk_z = player_chunk_z + z
			var chunk_key = Vector2i(chunk_x, chunk_z)

			chunks_to_keep[chunk_key] = true

			if not _terrain_chunks.has(chunk_key):
				var chunk = _create_terrain_chunk(chunk_x, chunk_z)
				add_child(chunk)
				_terrain_chunks[chunk_key] = chunk

	var chunks_to_remove: Array = []
	for chunk_key in _terrain_chunks.keys():
		if not chunks_to_keep.has(chunk_key):
			chunks_to_remove.append(chunk_key)

	for chunk_key in chunks_to_remove:
		var chunk = _terrain_chunks[chunk_key]
		chunk.queue_free()
		_terrain_chunks.erase(chunk_key)

# Called when terrain needs to be deformed (digging)
func dig_at_position(world_pos: Vector3, radius: float, depth: float) -> void:
	# Find affected chunks
	for chunk_key in _terrain_chunks.keys():
		var chunk = _terrain_chunks[chunk_key]
		var chunk_pos = chunk.global_position

		# Check if dig position is within or near this chunk
		var chunk_bounds = _chunk_size / 2.0 + radius
		if abs(world_pos.x - chunk_pos.x) <= chunk_bounds and abs(world_pos.z - chunk_pos.z) <= chunk_bounds:
			_deform_chunk_mesh(chunk, world_pos, radius, depth)
			_remove_grass_in_area(chunk, world_pos, radius)

func _deform_chunk_mesh(chunk: Node3D, world_pos: Vector3, radius: float, depth: float) -> void:
	var mesh_inst = chunk.get_node_or_null("TerrainMesh")
	if not mesh_inst or not mesh_inst.mesh:
		return

	var old_mesh = mesh_inst.mesh as ArrayMesh
	if not old_mesh:
		return

	# Get mesh data
	var arrays = old_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]

	# Convert world position to local
	var local_dig_pos = chunk.to_local(world_pos)

	# Deform vertices within radius
	var modified = false
	for i in range(vertices.size()):
		var vert = vertices[i]
		var dist_2d = Vector2(vert.x - local_dig_pos.x, vert.z - local_dig_pos.z).length()

		if dist_2d < radius:
			# Smooth falloff from center
			var falloff = 1.0 - (dist_2d / radius)
			falloff = falloff * falloff  # Quadratic falloff for smoother hole
			var dig_amount = depth * falloff

			vertices[i].y -= dig_amount
			modified = true

	if not modified:
		return

	# Rebuild mesh with new vertices
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Rebuild triangles (vertices come in groups of 3)
	for i in range(0, vertices.size(), 3):
		var v0 = vertices[i]
		var v1 = vertices[i + 1]
		var v2 = vertices[i + 2]

		# Recalculate normal for deformed triangle
		var normal = (v1 - v0).cross(v2 - v0).normalized()

		st.set_normal(normal)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v0)

		st.set_normal(normal)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v1)

		st.set_normal(normal)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(v2)

	st.generate_tangents()
	var new_mesh = st.commit()

	# Update mesh instance
	mesh_inst.mesh = new_mesh
	mesh_inst.set_surface_override_material(0, _create_terrain_material())

	# Update collision
	var collision_body = chunk.get_node_or_null("TerrainCollision")
	if collision_body:
		var collision_shape = collision_body.get_child(0) as CollisionShape3D
		if collision_shape:
			collision_shape.shape = new_mesh.create_trimesh_shape()

func _remove_grass_in_area(chunk: Node3D, world_pos: Vector3, radius: float) -> void:
	var grass = chunk.get_node_or_null("Grass")
	if grass and grass.has_method("erase"):
		var local_pos = chunk.to_local(world_pos)
		grass.erase(local_pos, radius)

func _process(_delta: float) -> void:
	_update_terrain_chunks()

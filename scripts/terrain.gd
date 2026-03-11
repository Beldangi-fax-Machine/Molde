extends Node3D

var _viewer_node: Node3D
var _terrain_chunks: Dictionary = {}
var _chunk_size: float = 100.0
var _render_distance: int = 3  # Render chunks 3 chunks away from player
var _last_player_chunk: Vector2i = Vector2i(9999, 9999)

func _ready() -> void:
	_viewer_node = get_parent().get_node_or_null("Player")
	if _viewer_node == null:
		_viewer_node = self

	# Create initial terrain chunks around spawn
	_update_terrain_chunks()

func _create_terrain_chunk(chunk_x: int, chunk_z: int) -> MeshInstance3D:
	# Create a single chunk of terrain
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(_chunk_size, _chunk_size)
	mesh.subdivide_width = 30  # Reduced subdivisions for performance
	mesh.subdivide_depth = 30

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh

	# Position chunk in world (ground level at Y=0)
	var chunk_world_x = chunk_x * _chunk_size
	var chunk_world_z = chunk_z * _chunk_size
	mesh_inst.position = Vector3(chunk_world_x, 0.0, chunk_world_z)
	mesh_inst.name = "Chunk_" + str(chunk_x) + "_" + str(chunk_z)

	# Make chunk cast shadows and receive them
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	# Load and apply the grass shader
	var shader = load("res://shaders/terrain.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader

	# Set wind parameters
	mat.set_shader_parameter("wind_strength", 0.3)
	mat.set_shader_parameter("wind_speed", 1.5)

	mesh_inst.set_surface_override_material(0, mat)

	return mesh_inst

func _update_terrain_chunks() -> void:
	if not _viewer_node or not is_instance_valid(_viewer_node):
		return

	# Get player's current chunk position
	var player_pos = _viewer_node.global_position
	var player_chunk_x = int(floor(player_pos.x / _chunk_size))
	var player_chunk_z = int(floor(player_pos.z / _chunk_size))
	var player_chunk = Vector2i(player_chunk_x, player_chunk_z)

	# Only update if player moved to a new chunk
	if player_chunk == _last_player_chunk:
		return

	_last_player_chunk = player_chunk

	# Track which chunks should exist
	var chunks_to_keep: Dictionary = {}

	# Create/show chunks around player
	for x in range(-_render_distance, _render_distance + 1):
		for z in range(-_render_distance, _render_distance + 1):
			var chunk_x = player_chunk_x + x
			var chunk_z = player_chunk_z + z
			var chunk_key = Vector2i(chunk_x, chunk_z)

			chunks_to_keep[chunk_key] = true

			# Create chunk if it doesn't exist
			if not _terrain_chunks.has(chunk_key):
				var chunk = _create_terrain_chunk(chunk_x, chunk_z)
				add_child(chunk)
				_terrain_chunks[chunk_key] = chunk

	# Remove chunks that are too far away
	var chunks_to_remove: Array = []
	for chunk_key in _terrain_chunks.keys():
		if not chunks_to_keep.has(chunk_key):
			chunks_to_remove.append(chunk_key)

	for chunk_key in chunks_to_remove:
		var chunk = _terrain_chunks[chunk_key]
		chunk.queue_free()
		_terrain_chunks.erase(chunk_key)

func _process(_delta: float) -> void:
	# Update terrain chunks based on player position
	_update_terrain_chunks()

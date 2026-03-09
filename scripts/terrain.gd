extends Node3D

const CHUNK_SIZE := 32
const RESOLUTION := 32
const VIEW_RADIUS_CHUNKS := 2
const HEIGHT_SCALE := 12.0
const NOISE_FREQ := 0.04
const NOISE_OCTAVES := 4
const PLATEAU_NOISE_SCALE := 0.06
const PLATEAU_THRESHOLD := 0.6
const PLATEAU_RADIUS := 6.0
const PLATEAU_HEIGHT := 2.0
const MIN_HEIGHT := -4.0

var _noise: FastNoiseLite
var _chunks: Dictionary = {}
var _viewer_node: Node3D
var _terrain_material: ShaderMaterial

func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = NOISE_FREQ
	_noise.fractal_octaves = NOISE_OCTAVES
	_noise.fractal_lacunarity = 2.0
	_noise.fractal_gain = 0.5

	var shader := load("res://shaders/terrain.gdshader") as Shader
	if shader:
		_terrain_material = ShaderMaterial.new()
		_terrain_material.shader = shader

	_viewer_node = get_parent().get_node_or_null("Player")
	if _viewer_node == null:
		_viewer_node = self

func _process(_delta: float) -> void:
	if _viewer_node == null:
		return
	var origin := _viewer_node.global_position
	var cam_chunk_x := int(floor(origin.x / CHUNK_SIZE))
	var cam_chunk_z := int(floor(origin.z / CHUNK_SIZE))

	var to_remove: Array[String] = []
	for key in _chunks:
		var parts: PackedStringArray = key.split("_")
		if parts.size() != 2:
			continue
		var cx := int(parts[0])
		var cz := int(parts[1])
		if abs(cx - cam_chunk_x) > VIEW_RADIUS_CHUNKS or abs(cz - cam_chunk_z) > VIEW_RADIUS_CHUNKS:
			to_remove.append(key)
	for key in to_remove:
		var chunk: Node = _chunks[key]
		_chunks.erase(key)
		chunk.queue_free()

	for cx in range(cam_chunk_x - VIEW_RADIUS_CHUNKS, cam_chunk_x + VIEW_RADIUS_CHUNKS + 1):
		for cz in range(cam_chunk_z - VIEW_RADIUS_CHUNKS, cam_chunk_z + VIEW_RADIUS_CHUNKS + 1):
			var key := str(cx) + "_" + str(cz)
			if _chunks.has(key):
				continue
			_chunks[key] = _make_chunk(cx, cz)
			add_child(_chunks[key])

func _make_chunk(cx: int, cz: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Chunk_%d_%d" % [cx, cz]
	root.position = Vector3(cx * CHUNK_SIZE, 0, cz * CHUNK_SIZE)

	var res := RESOLUTION
	var step := CHUNK_SIZE / float(res)
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize((res + 1) * (res + 1))
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var idx: int = 0
	var chunk_center_x := cx * CHUNK_SIZE + CHUNK_SIZE * 0.5
	var chunk_center_z := cz * CHUNK_SIZE + CHUNK_SIZE * 0.5
	
	# Generate heightmap and vertices
	for j in range(res + 1):
		for i in range(res + 1):
			var wx := cx * CHUNK_SIZE + i * step
			var wz := cz * CHUNK_SIZE + j * step
			var h: float = _noise.get_noise_2d(wx, wz) * HEIGHT_SCALE
			h += _noise.get_noise_2d(wx * 2.0 + 100, wz * 2.0) * 3.0

			# Create occasional flat plateaus to give walkable flat areas
			var plateau_noise := _noise.get_noise_2d(wx * PLATEAU_NOISE_SCALE + 500, wz * PLATEAU_NOISE_SCALE + 500)
			if plateau_noise > PLATEAU_THRESHOLD:
				var dist := sqrt(pow(wx - chunk_center_x, 2) + pow(wz - chunk_center_z, 2))
				if dist < PLATEAU_RADIUS:
					h = PLATEAU_HEIGHT

			# Avoid extremely low values that might let player clip under the terrain
			if h < MIN_HEIGHT:
				h = MIN_HEIGHT

			heights[idx] = h
			verts.append(Vector3(i * step, h, j * step))
			idx += 1

	# Calculate normals
	for j in range(res + 1):
		for i in range(res + 1):
			var i0 := clampf(i - 1, 0, res)
			var i1 := clampf(i + 1, 0, res)
			var j0 := clampf(j - 1, 0, res)
			var j1 := clampf(j + 1, 0, res)
			var idx_cur := j * (res + 1) + i
			var v_cur := verts[idx_cur]
			var v_x0 := verts[j * (res + 1) + i0]
			var v_x1 := verts[j * (res + 1) + i1]
			var v_z0 := verts[j0 * (res + 1) + i]
			var v_z1 := verts[j1 * (res + 1) + i]
			var dx := (v_x1 - v_x0).normalized()
			var dz := (v_z1 - v_z0).normalized()
			var n := dx.cross(dz).normalized()
			if n.y < 0:
				n = -n
			normals.append(n)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(res):
		for i in range(res):
			var a := j * (res + 1) + i
			var b := j * (res + 1) + i + 1
			var c := (j + 1) * (res + 1) + i
			var d := (j + 1) * (res + 1) + i + 1
			st.set_normal(normals[a])
			st.add_vertex(verts[a])
			st.set_normal(normals[c])
			st.add_vertex(verts[c])
			st.set_normal(normals[b])
			st.add_vertex(verts[b])
			st.set_normal(normals[b])
			st.add_vertex(verts[b])
			st.set_normal(normals[c])
			st.add_vertex(verts[c])
			st.set_normal(normals[d])
			st.add_vertex(verts[d])
	var mesh := st.commit()
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	if _terrain_material:
		mesh_inst.material_override = _terrain_material.duplicate()
	root.add_child(mesh_inst)

	var body := StaticBody3D.new()
	var shape := HeightMapShape3D.new()
	shape.map_width = res + 1
	shape.map_depth = res + 1
	shape.map_data = heights
	body.position = Vector3.ZERO
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	root.add_child(body)

	return root

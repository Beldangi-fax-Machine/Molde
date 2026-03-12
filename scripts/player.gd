extends CharacterBody3D

const SPEED = 8.0
const RUN_SPEED = 14.0
const JUMP_VELOCITY = 6.0
const ACCELERATION = 20.0
const MOUSE_SENSITIVITY = 0.003
const DIG_RANGE = 50.0
const DIG_RADIUS = 2.0
const DIG_DEPTH = 0.8
const ROTATION_SPEED = 10.0

var gravity = 25.0
var camera_pivot: Node3D
var camera: Camera3D
var raycast: RayCast3D
var character_model: Node3D
var skeleton: Skeleton3D
var move_input = Vector3.ZERO
var camera_rot = Vector3.ZERO
var terrain_node: Node3D
var target_rotation = 0.0
var armature: Node3D  # The armature node inside the model

# Animation variables
var anim_time = 0.0
var is_moving = false
var is_running = false
var is_jumping = false
var jump_start_y = 0.0

# Bone indices (will be set in _ready)
var bone_hips = -1
var bone_spine = -1
var bone_left_up_leg = -1
var bone_right_up_leg = -1
var bone_left_leg = -1
var bone_right_leg = -1
var bone_left_arm = -1
var bone_right_arm = -1
var bone_left_forearm = -1
var bone_right_forearm = -1

func _ready():
	print("Player ready")

	# Get camera pivot
	camera_pivot = get_node_or_null("CameraPivot")
	if camera_pivot:
		camera = camera_pivot.get_node_or_null("Camera3D")
		if camera:
			raycast = camera.get_node_or_null("RayCast3D")

	# Get character model and skeleton
	character_model = get_node_or_null("CharacterModel")
	if character_model:
		print("CharacterModel found: ", character_model)
		_print_node_tree(character_model, 0)

		# Find the Armature node (this is what we rotate for facing direction)
		armature = character_model.get_node_or_null("Armature")
		if armature:
			print("Armature found")
			# Model faces +X by default, rotate to face -Z (forward)
			armature.rotation.y = PI/2

		skeleton = _find_skeleton(character_model)
		if skeleton:
			# Print all bone names for debugging
			print("=== SKELETON BONES ===")
			for i in range(skeleton.get_bone_count()):
				print("Bone ", i, ": ", skeleton.get_bone_name(i))
			print("======================")
			_setup_bone_indices()
			print("Skeleton found with ", skeleton.get_bone_count(), " bones")
			_print_bone_setup()
		else:
			print("WARNING: No Skeleton3D found in CharacterModel!")
	else:
		print("WARNING: No CharacterModel node found!")

	terrain_node = get_parent().get_node_or_null("Terrain")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_create_crosshair()

func _print_bone_setup():
	print("Bone indices setup:")
	print("  hips: ", bone_hips)
	print("  spine: ", bone_spine)
	print("  left_up_leg: ", bone_left_up_leg)
	print("  right_up_leg: ", bone_right_up_leg)
	print("  left_leg: ", bone_left_leg)
	print("  right_leg: ", bone_right_leg)
	print("  left_arm: ", bone_left_arm)
	print("  right_arm: ", bone_right_arm)

func _print_node_tree(node: Node, indent: int):
	var prefix = ""
	for i in range(indent):
		prefix += "  "
	print(prefix, node.name, " [", node.get_class(), "]")
	for child in node.get_children():
		_print_node_tree(child, indent + 1)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	return null

func _setup_bone_indices():
	# Try different naming conventions (Mixamo with underscore, Mixamo with colon, standard)
	var bone_names = {
		"hips": ["mixamorig_Hips", "mixamorig:Hips", "Hips", "hips", "pelvis", "Pelvis"],
		"spine": ["mixamorig_Spine", "mixamorig:Spine", "Spine", "spine", "Spine1"],
		"left_up_leg": ["mixamorig_LeftUpLeg", "mixamorig:LeftUpLeg", "LeftUpLeg", "left_thigh", "LeftThigh"],
		"right_up_leg": ["mixamorig_RightUpLeg", "mixamorig:RightUpLeg", "RightUpLeg", "right_thigh", "RightThigh"],
		"left_leg": ["mixamorig_LeftLeg", "mixamorig:LeftLeg", "LeftLeg", "left_shin", "LeftShin"],
		"right_leg": ["mixamorig_RightLeg", "mixamorig:RightLeg", "RightLeg", "right_shin", "RightShin"],
		"left_arm": ["mixamorig_LeftArm", "mixamorig:LeftArm", "LeftArm", "left_upper_arm", "LeftUpperArm"],
		"right_arm": ["mixamorig_RightArm", "mixamorig:RightArm", "RightArm", "right_upper_arm", "RightUpperArm"],
		"left_forearm": ["mixamorig_LeftForeArm", "mixamorig:LeftForeArm", "LeftForeArm", "left_lower_arm"],
		"right_forearm": ["mixamorig_RightForeArm", "mixamorig:RightForeArm", "RightForeArm", "right_lower_arm"],
	}

	for key in bone_names:
		for bone_name in bone_names[key]:
			var idx = skeleton.find_bone(bone_name)
			if idx >= 0:
				match key:
					"hips": bone_hips = idx
					"spine": bone_spine = idx
					"left_up_leg": bone_left_up_leg = idx
					"right_up_leg": bone_right_up_leg = idx
					"left_leg": bone_left_leg = idx
					"right_leg": bone_right_leg = idx
					"left_arm": bone_left_arm = idx
					"right_arm": bone_right_arm = idx
					"left_forearm": bone_left_forearm = idx
					"right_forearm": bone_right_forearm = idx
				print("Found bone '", key, "': ", bone_name, " at index ", idx)
				break

func _create_crosshair() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -4
	panel.offset_top = -4
	panel.offset_right = 4
	panel.offset_bottom = 4

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.WHITE
	style_box.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style_box)
	canvas.add_child(panel)

func _input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			var mouse_event = event as InputEventMouseMotion
			camera_rot.y -= mouse_event.relative.x * MOUSE_SENSITIVITY
			if camera_rot.y > PI:
				camera_rot.y -= TAU
			elif camera_rot.y < -PI:
				camera_rot.y += TAU

			camera_rot.x -= mouse_event.relative.y * MOUSE_SENSITIVITY
			camera_rot.x = clamp(camera_rot.x, -PI/3, PI/4)

			if camera_pivot:
				camera_pivot.rotation.y = camera_rot.y
				camera_pivot.rotation.x = camera_rot.x

		if event is InputEventMouseButton:
			var mouse_btn = event as InputEventMouseButton
			if mouse_btn.button_index == MOUSE_BUTTON_LEFT and mouse_btn.pressed:
				_try_dig()

	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _try_dig() -> void:
	if not raycast:
		return
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		_dig_terrain(hit_point)

func _dig_terrain(pos: Vector3) -> void:
	if not terrain_node or not is_instance_valid(terrain_node):
		terrain_node = get_parent().get_node_or_null("Terrain")
	if terrain_node and terrain_node.has_method("dig_at_position"):
		terrain_node.dig_at_position(pos, DIG_RADIUS, DIG_DEPTH)

func _physics_process(delta: float) -> void:
	var input_x = 0.0
	var input_z = 0.0

	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_x = 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_x = -1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_z = -1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_z = 1.0

	# Check if running (Shift key)
	is_running = Input.is_key_pressed(KEY_SHIFT)
	var current_speed = RUN_SPEED if is_running else SPEED

	# Calculate movement direction relative to camera
	if input_x != 0.0 or input_z != 0.0:
		# Get camera's forward and right vectors (horizontal only)
		var cam_forward = -camera_pivot.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()

		var cam_right = camera_pivot.global_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()

		# W/S = forward/back along camera direction, A/D = strafe
		move_input = (cam_forward * input_z + cam_right * input_x).normalized()

		# Character faces movement direction
		# atan2(x, z) gives angle from +Z axis to the movement direction
		target_rotation = atan2(move_input.x, move_input.z)
		is_moving = true
	else:
		move_input = Vector3.ZERO
		is_moving = false

	# Rotate the armature (or model) to face movement direction
	var rotate_node = armature if armature else character_model
	if rotate_node and move_input != Vector3.ZERO:
		var current_rot = rotate_node.rotation.y
		rotate_node.rotation.y = lerp_angle(current_rot, target_rotation, ROTATION_SPEED * delta)

	# Gravity and jumping
	if not is_on_floor():
		velocity.y -= gravity * delta
		if velocity.y > 0:
			is_jumping = true
	else:
		is_jumping = false
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			jump_start_y = global_position.y

	# Horizontal movement
	var target_velocity = Vector3.ZERO
	if move_input != Vector3.ZERO:
		target_velocity = move_input * current_speed

	velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)

	move_and_slide()

	# Animate skeleton
	_animate_skeleton(delta)

func _animate_skeleton(delta: float) -> void:
	var anim_speed = 8.0 if is_moving else 2.0
	if is_running:
		anim_speed = 12.0

	anim_time += delta * anim_speed

	# Use procedural bone animation
	if skeleton and bone_hips >= 0:
		_animate_procedural()
	else:
		_animate_model_simple()

func _animate_model_simple() -> void:
	# Simple animation that moves the whole model slightly
	if not character_model:
		return

	if is_moving:
		var bob = sin(anim_time * 2) * 0.05
		character_model.position.y = bob
	else:
		character_model.position.y = 0

func _animate_procedural() -> void:
	# Always reset all bones first
	for i in range(skeleton.get_bone_count()):
		skeleton.reset_bone_pose(i)

	if not is_moving:
		return

	# Walking/running animation
	var speed_mult = 1.5 if is_running else 1.0
	var leg_amplitude = 0.4 if is_running else 0.3
	var arm_amplitude = 0.3 if is_running else 0.2

	var phase = anim_time * speed_mult
	var leg_swing = sin(phase) * leg_amplitude
	var arm_swing = sin(phase) * arm_amplitude

	# Upper legs swing forward/back - use Z axis rotation
	_rotate_bone(bone_left_up_leg, Vector3(0, 0, leg_swing))
	_rotate_bone(bone_right_up_leg, Vector3(0, 0, -leg_swing))

	# Lower legs (knees) bend
	var left_knee = max(0, -leg_swing) * 0.7
	var right_knee = max(0, leg_swing) * 0.7
	_rotate_bone(bone_left_leg, Vector3(0, 0, left_knee))
	_rotate_bone(bone_right_leg, Vector3(0, 0, right_knee))

	# Arms swing opposite to legs - use Z axis
	_rotate_bone(bone_left_arm, Vector3(0, 0, -arm_swing))
	_rotate_bone(bone_right_arm, Vector3(0, 0, arm_swing))

	# Forearms bent
	_rotate_bone(bone_left_forearm, Vector3(0, 0, 0.3))
	_rotate_bone(bone_right_forearm, Vector3(0, 0, 0.3))

func _rotate_bone(bone_idx: int, euler: Vector3) -> void:
	if bone_idx < 0 or not skeleton:
		return
	skeleton.set_bone_pose_rotation(bone_idx, Quaternion.from_euler(euler))

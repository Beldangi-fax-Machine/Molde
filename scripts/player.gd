extends CharacterBody3D

const SPEED = 15.0
const JUMP_VELOCITY = 8.0
const ACCELERATION = 30.0
const MOUSE_SENSITIVITY = 0.003

var gravity = 25.0
var camera: Camera3D
var move_input = Vector3.ZERO
var camera_rot = Vector3.ZERO

func _ready():
	print("Player ready")
	camera = get_node_or_null("Camera3D")
	if camera:
		camera.position.y = 2.0
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_create_crosshair()

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
	panel.size = Vector2(8, 8)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.WHITE
	style_box.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style_box)
	
	canvas.add_child(panel)

func _input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			var mouse_event = event as InputEventMouseMotion
			# Rotate on Y axis (horizontal) - full 360 degrees
			camera_rot.y -= mouse_event.relative.x * MOUSE_SENSITIVITY
			# Keep Y rotation in 0 to 2PI range for consistency
			if camera_rot.y > PI:
				camera_rot.y -= TAU
			elif camera_rot.y < -PI:
				camera_rot.y += TAU
			
			# Rotate on X axis (vertical) - limited up/down
			camera_rot.x -= mouse_event.relative.y * MOUSE_SENSITIVITY
			camera_rot.x = clamp(camera_rot.x, -PI/2.2, PI/2.2)
			
			if camera:
				camera.rotation = camera_rot
	
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		# Arrow keys for camera rotation
		if event.pressed:
			var arrow_sensitivity = 0.05
			if event.keycode == KEY_RIGHT:
				camera_rot.y -= arrow_sensitivity
				if camera_rot.y < -PI:
					camera_rot.y += TAU
			elif event.keycode == KEY_LEFT:
				camera_rot.y += arrow_sensitivity
				if camera_rot.y > PI:
					camera_rot.y -= TAU
			elif event.keycode == KEY_UP:
				camera_rot.x -= arrow_sensitivity
				camera_rot.x = clamp(camera_rot.x, -PI/2.2, PI/2.2)
			elif event.keycode == KEY_DOWN:
				camera_rot.x += arrow_sensitivity
				camera_rot.x = clamp(camera_rot.x, -PI/2.2, PI/2.2)
			
			if camera:
				camera.rotation = camera_rot

func _physics_process(delta: float) -> void:
	var input_x = 0.0
	var input_z = 0.0
	
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_x = 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_x = -1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_z = 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_z = -1.0
	
	move_input = Vector3(input_x, 0, input_z).normalized()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
	
	var target_velocity = Vector3.ZERO
	if move_input != Vector3.ZERO:
		target_velocity = move_input * SPEED
	
	velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)
	
	move_and_slide()

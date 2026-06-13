extends CharacterBody3D

#region Variables
@export_group("Movement")
@export var move_speed: float = 3.5
@export var sprint_speed: float = 7.0
@export var jump_force: float = 8.5
@export var mouse_sensitivity: float = 0.005

@export var fall_multiplier: float = 2.5
@export var ascend_multiplier: float = 2.0

@export_group("Crouch")
@export var crouch_speed_multiplier := 0.45
@export var crouch_stamina_regen_multiplier := 2.0
@export var standing_height := 0.6
@export var crouching_height := -0.5

var is_crouching := false

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 25.0
@export var stamina_regen_rate: float = 10.0
@export var stamina_delay: float = 1.0

var stamina: float
var stamina_timer: float = 0.0

@export_group("Health")
@export var max_health: float = 100.0

var health: float

@export_category("Camera Feel Good")
@export_group("FOV")
@export var base_fov: float = 75.0
@export var fov_change: float = 1.5

@export_group("Bob")
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.15
@export var bob_fade_speed: float = 8.0

var t_bob: float = 0.0
var bob_intensity: float = 0.0
var original_cam_pos: Vector3

@export_group("Sway")
@export var sway_amount := 0.0
@export var sway_target := 0.0
@export var sway_strength := 0.0015
@export var sway_max := 0.05
@export var sway_return_speed := 8.0
@export var camera_lag_speed := 12.0

@export var camera_move_speed := 1.0
@export var camera_sensitivity_divider := 2.0

var target_yaw: float = 0.0
var current_yaw: float = 0.0

var target_pitch: float = 0.0
var current_pitch: float = 0.0

var target_fov: float

var camera_zoom_fov: float = 0.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

@export_category("UI Stuff")
@export var stamina_label: Label
@export var health_label: Label
@export var max_stamina_label: Label
@export var max_health_label: Label
@export var scout_ui: Control
@export var camera_ui: Control
@export var gear_texture: Sprite2D

@export_group("UI Elements")
@export var gear_rotation_speed: float = .1
@export var min_fov := 30.0
@export var max_fov := 75.0

var gear_rotation_current := 0.0
var gear_rotation_target := 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var vertical_rotation: float = 0.0


enum player_mode {SCOUT, CAMERA}
var current_mode: player_mode = player_mode.SCOUT
#endregion

func _ready() -> void:
	scout_ui.modulate = Color("ffb347")
	camera_ui.modulate = Color("6aaae6")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_cam_pos = camera.position
	camera.fov = base_fov
	update_player_ui()
	
	target_yaw = rotation.y
	current_yaw = rotation.y
	
	target_pitch = 0.0
	current_pitch = 0.0
	
	target_fov = base_fov
	
	camera_zoom_fov = base_fov
	
	stamina = max_stamina
	health = max_health


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var sensitivity := mouse_sensitivity
		
		if current_mode == player_mode.CAMERA:
			sensitivity /= camera_sensitivity_divider
		
		target_yaw -= event.relative.x * sensitivity
		
		target_pitch -= event.relative.y * sensitivity
		target_pitch = clampf(target_pitch, -PI / 2.0, PI / 2.0)
		
		sway_target = clamp(
			-event.relative.x * sway_strength,
			-sway_max,
			sway_max
		)
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("mode_change"):
		if current_mode == player_mode.SCOUT:
			current_mode = player_mode.CAMERA
			target_fov = camera_zoom_fov
			gear_rotation_current = 0.0
			gear_rotation_target = 0.0
		else:
			current_mode = player_mode.SCOUT
			target_fov = base_fov
			camera_zoom_fov = base_fov
			gear_rotation_current = 0.0
			gear_rotation_target = 0.0
		update_player_ui()
	
	if event is InputEventMouseButton and current_mode == player_mode.CAMERA:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_zoom_fov  = clampf(camera_zoom_fov - 5.0, 30.0, base_fov)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_zoom_fov  = clampf(camera_zoom_fov + 5.0, 30.0, base_fov)
	
	if event.is_action_pressed("crouch"):
		is_crouching = true
	
	if event.is_action_released("crouch"):
		is_crouching = false
	
	if event.is_action_pressed("test_damage"):
		take_damage(10)
	
	if event.is_action_pressed("test_heal"):
		add_health(10)

func _process(delta: float) -> void:
	current_yaw = lerp_angle(
		current_yaw,
		target_yaw,
		delta * camera_lag_speed
	)
	
	current_pitch = lerp(
		current_pitch,
		target_pitch,
		delta * camera_lag_speed
	)
	
	rotation.y = current_yaw
	camera_pivot.rotation.x = current_pitch
	
	sway_amount = lerp(sway_amount, sway_target, delta * 15.0)
	sway_target = lerp(sway_target, 0.0, delta * sway_return_speed)
	camera.rotation.z = sway_amount
	
	var target_height := standing_height
	
	if is_crouching:
		target_height = crouching_height
	
	camera_pivot.position.y = lerp(
		camera_pivot.position.y,
		target_height,
		delta * 10
	)
	
	if current_mode == player_mode.CAMERA:
		target_fov = camera_zoom_fov
		
		var zoom_t := inverse_lerp(max_fov, min_fov, camera_zoom_fov)
		gear_rotation_target = zoom_t * TAU * 0.5
		
		gear_rotation_current = lerp(
			gear_rotation_current,
			gear_rotation_target,
			delta * 10.0
		)
		
		gear_texture.rotation = gear_rotation_current
	

func _physics_process(delta: float) -> void:
	if max_health > 999: #MIGHT NEED TO CHANGE IN THE FUTURE FOR PERFORMANCE
		max_health = 999
	if health > 999:
		health = 999
	
	if max_stamina > 999:
		max_stamina = 999
	if stamina > 999:
		stamina = 999
	
	var can_sprint := (
		current_mode == player_mode.SCOUT
		and Input.is_action_pressed("sprint")
		and stamina > 0.0
	)
	
	var speed: float
	if current_mode == player_mode.CAMERA:
		speed = camera_move_speed
	else:
		speed = sprint_speed if can_sprint else move_speed
	
	if is_crouching and current_mode == player_mode.SCOUT:
		speed *= crouch_speed_multiplier
	
	# Gravity with better feeling fall curve
	if not is_on_floor():
		var multiplier := fall_multiplier if velocity.y < 0.0 else ascend_multiplier
		velocity.y -= gravity * multiplier * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	
	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis.x * input_dir.x + transform.basis.z * input_dir.y).normalized()
	
	if is_on_floor():
		velocity.x = direction.x * speed if direction else move_toward(velocity.x, 0.0, speed)
		velocity.z = direction.z * speed if direction else move_toward(velocity.z, 0.0, speed)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 4.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 4.0)
	
	if can_sprint and direction != Vector3.ZERO:
		stamina -= stamina_drain_rate * delta
		stamina = max(stamina, 0.0)
		stamina_timer = stamina_delay
	else:
		if stamina_timer > 0.0:
			stamina_timer -= delta
		else:
			if current_mode != player_mode.CAMERA:
				var regen_rate := stamina_regen_rate
				
				if is_crouching:
					regen_rate *= crouch_stamina_regen_multiplier
				
				stamina += regen_rate * delta
				stamina = min(stamina, max_stamina)
	
	if stamina <= 0.0:
		can_sprint = false
	
	move_and_slide()
	_apply_headbob(delta)
	_apply_fov(delta, speed)
	
	stamina_label.text = str(int(stamina))
	health_label.text = str(int(health))
	max_stamina_label.text = "/" + str(int(max_stamina))
	max_health_label.text = "/" + str(int(max_health))

func _apply_headbob(delta: float) -> void:
	var flat_speed := Vector3(velocity.x, 0.0, velocity.z).length()
	var target_intensity: float = 1.0 if (is_on_floor() and flat_speed > 0.05) else 0.0
	bob_intensity = lerp(bob_intensity, target_intensity, delta * bob_fade_speed)
	
	t_bob += delta * flat_speed
	camera.position = original_cam_pos + Vector3(
		cos(t_bob * bob_frequency * 0.5) * bob_amplitude * bob_intensity,
		sin(t_bob * bob_frequency) * bob_amplitude * bob_intensity,
		0.0
	)
	

func _apply_fov(delta: float, current_speed: float) -> void:
	var flat_speed := Vector3(velocity.x, 0.0, velocity.z).length()
	var speed_fov := base_fov + fov_change * clampf(flat_speed, 0.0, current_speed)
	if current_mode != player_mode.CAMERA:
		target_fov = lerp(target_fov, speed_fov, delta * 2.0)
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

func update_player_ui():
	scout_ui.visible = current_mode == player_mode.SCOUT
	camera_ui.visible = current_mode == player_mode.CAMERA

func take_damage(damage: int) -> void:
	health -= damage
	health = max(health, 0)
	
	var health_percent := health / max_health
	
	if health_percent <= 0.1:
		scout_ui.modulate = Color("c93830ff")
		camera_ui.modulate = Color("6544a7ff")
	elif health_percent <= 0.3:
		scout_ui.modulate = Color("ff8748ff")
		camera_ui.modulate = Color("5d76cfff")
	else:
		scout_ui.modulate = Color("ffb347ff")
		camera_ui.modulate = Color("6aaae6")
	
	if health <= 0:
		die()

func add_health(heal: int) -> void:
	health += heal
	
	if health >= max_health:
		health = max_health
	
	var health_percent := health / max_health
	
	if health_percent <= 0.1:
		scout_ui.modulate = Color("c93830ff")
		camera_ui.modulate = Color("6544a7ff")
	elif health_percent <= 0.3:
		scout_ui.modulate = Color("ff8748ff")
		camera_ui.modulate = Color("5d76cfff")
	else:
		scout_ui.modulate = Color("ffb347")
		camera_ui.modulate = Color("6aaae6")

func die():
	print("The player will die here frfr")

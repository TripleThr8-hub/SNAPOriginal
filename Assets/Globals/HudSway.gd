extends Control

@export var sway_strength := 20.0
@export var scale_strength := 0.03

var target_pos := Vector2.ZERO

func _process(delta):
	var mouse = Input.get_last_mouse_velocity()
	
	target_pos.x = clamp(mouse.x * -0.02, -sway_strength, sway_strength)
	target_pos.y = clamp(mouse.y * -0.02, -sway_strength, sway_strength)
	
	position = position.lerp(target_pos, delta * 8.0)
	
	var speed = mouse.length()
	
	var target_scale = Vector2.ONE - Vector2.ONE * min(speed * 0.0001, scale_strength)
	
	scale = scale.lerp(target_scale, delta * 8.0)

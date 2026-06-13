extends Control

@export var glitch_strength := 2.0
@export var glitch_speed := 0.05

var base_pos: Vector2
var glitch_timer := 0.0

func _ready():
	base_pos = position

func _process(delta):
	glitch_timer -= delta

	if glitch_timer <= 0.0:
		# random glitch burst chance
		if randf() < 0.05:
			glitch_timer = randf_range(0.05, 0.15)

	if glitch_timer > 0.0:
		position = base_pos + Vector2(
			randf_range(-glitch_strength, glitch_strength),
			randf_range(-glitch_strength, glitch_strength)
		)
	else:
		position = base_pos

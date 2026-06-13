extends Control
@export var player: Node3D
@export var tick_spacing: float = 30.0
@export var compass_width: float = 300.0
@export var compass_height: float = 30.0
@export var compass_offset_y: float = 30.0
@export var custom_font: Font
@export var font_size: int = 14
@export var cardinal_tick_height: float = 8.0
@export var degree_tick_height: float = 5.0
@export var small_tick_height: float = 3.0
var font: Font
const CARDINALS = {
	0: "N", 45: "NE", 90: "E", 135: "SE",
	180: "S", 225: "SW", 270: "W", 315: "NW"
}
func _ready():
	if custom_font:
		font = custom_font
	else:
		font = ThemeDB.fallback_font
func _process(_delta):
	queue_redraw()
func _draw():
	if not player:
		return
	var heading = fmod(rad_to_deg(-player.global_rotation.y) + 360.0, 360.0)
	var center_x = size.x / 2.0
	var pixels_per_degree = tick_spacing / 10.0
	var bar_x = center_x - compass_width / 2.0
	var bar_y = compass_offset_y
	for deg in range(-180, 181):
		var world_angle = fmod(heading + deg + 360.0, 360.0)
		var x = center_x + deg * pixels_per_degree
		if x < bar_x or x > bar_x + compass_width:
			continue
		var angle_int = int(round(world_angle)) % 360
		if CARDINALS.has(angle_int):
			draw_line(Vector2(x, bar_y), Vector2(x, bar_y + cardinal_tick_height), Color(1.0, 1.0, 1.0, 1.0), 2.0)
			draw_string(font, Vector2(x - 20, bar_y + compass_height - 6),
				CARDINALS[angle_int], HORIZONTAL_ALIGNMENT_CENTER, 40, font_size, Color(1.0, 1.0, 1.0, 1.0))
		elif angle_int % 10 == 0:
			draw_line(Vector2(x, bar_y), Vector2(x, bar_y + degree_tick_height), Color(1, 1, 1, 0.6), 1.0)
		elif angle_int % 5 == 0:
			draw_line(Vector2(x, bar_y), Vector2(x, bar_y + small_tick_height), Color(1, 1, 1, 0.3), 1.0)

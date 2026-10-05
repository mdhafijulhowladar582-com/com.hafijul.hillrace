extends Control
# স্পিডোমিটার: গোল গেজ + কাঁটা + km/h

var speed := 0.0
var max_speed := 140.0

func _ready() -> void:
	custom_minimum_size = Vector2(190, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var c := Vector2(95, 100)
	var r := 78.0
	var a0 := deg_to_rad(150.0)
	var a1 := deg_to_rad(390.0)
	draw_circle(c, 88.0, Color(0, 0, 0, 0.45))
	draw_arc(c, r, a0, a1, 48, Color(1, 1, 1, 0.18), 12.0)
	var f: float = clampf(speed / max_speed, 0.0, 1.0)
	var col: Color = Color("51cf66").lerp(Color("fa5252"), f)
	if f > 0.01:
		draw_arc(c, r, a0, a0 + (a1 - a0) * f, 48, col, 12.0)
	for i in range(9):
		var ta: float = a0 + (a1 - a0) * float(i) / 8.0
		var d := Vector2(cos(ta), sin(ta))
		draw_line(c + d * (r - 16.0), c + d * (r - 8.0), Color(1, 1, 1, 0.6), 2.0)
	var ang: float = a0 + (a1 - a0) * f
	draw_line(c, c + Vector2(cos(ang), sin(ang)) * (r - 18.0), Color.WHITE, 4.0)
	draw_circle(c, 7.0, Color.WHITE)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(0, 152), str(int(speed)), HORIZONTAL_ALIGNMENT_CENTER, 190.0, 38, Color.WHITE)
	draw_string(font, Vector2(0, 176), "km/h", HORIZONTAL_ALIGNMENT_CENTER, 190.0, 20, Color(1, 1, 1, 0.8))

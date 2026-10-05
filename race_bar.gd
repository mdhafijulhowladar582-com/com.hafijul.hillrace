extends Control
# Ghost Race: ওপরের রেস-বার (নীল = আপনি, সাদা = ভূত)

var gap := 0.0
var text := ""
var col := Color.WHITE

func _ready() -> void:
	custom_minimum_size = Vector2(440, 70)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_rect(Rect2(0, 0, 440, 70), Color(0, 0, 0, 0.45))
	var y := 22.0
	draw_line(Vector2(30, y), Vector2(410, y), Color(1, 1, 1, 0.35), 6.0)
	var cx := 220.0
	var off: float = clampf(-gap, -60.0, 60.0) / 60.0 * 180.0
	draw_circle(Vector2(cx + off, y), 10.0, Color.WHITE)
	draw_circle(Vector2(cx, y), 12.0, Color("4dabf7"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(0, 58), text, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 28, col)

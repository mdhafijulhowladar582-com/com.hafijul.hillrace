extends RefCounted
# UI helper functions (static) - সব স্ক্রিনে এগুলো ব্যবহার হয়।

const ORANGE := Color(0.97, 0.40, 0.03)
const GREEN := Color(0.18, 0.69, 0.30)
const BLUE := Color(0.13, 0.52, 0.90)
const RED := Color(0.87, 0.22, 0.22)
const GOLD := Color(1.0, 0.77, 0.10)
const GRAY := Color(0.35, 0.38, 0.45)
const PANEL := Color(0.08, 0.10, 0.18, 0.88)

const CarBody = preload("res://car_body.gd")
const WheelVis = preload("res://wheel_vis.gd")

static func money(n: int) -> String:
	var s := str(n)
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "," + out
	return out

static func style(bg: Color, radius: int, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.set_content_margin_all(14)
	return s

static func btn_style(color: Color, pressed: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(22)
	s.border_color = color.darkened(0.4)
	s.border_width_bottom = 2 if pressed else 7
	s.set_content_margin_all(12)
	return s

static func button(text: String, color: Color, size: int, min_size: Vector2) -> Button:
	var b := pedal(text, color, size, min_size)
	b.pressed.connect(func(): Sfx.play("click"))
	return b

static func pedal(text: String, color: Color, size: int, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.5))
	b.add_theme_stylebox_override("normal", btn_style(color, false))
	b.add_theme_stylebox_override("hover", btn_style(color.lightened(0.08), false))
	b.add_theme_stylebox_override("pressed", btn_style(color.darkened(0.15), true))
	b.add_theme_stylebox_override("disabled", btn_style(color.darkened(0.5), false))
	return b

static func label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(2, int(size / 12.0)))
	return l

static func panel_box(color: Color, radius: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(color, radius, Color(1, 1, 1, 0.12), 2))
	return p

static func circle_pts(r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

static func coin_badge() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(Color(0, 0, 0, 0.5), 26, GOLD, 3))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(34, 34)
	var poly := Polygon2D.new()
	poly.polygon = circle_pts(15.0, 20)
	poly.color = GOLD
	poly.position = Vector2(17, 17)
	icon.add_child(poly)
	h.add_child(icon)
	var l := label(money(Game.coins), 34, GOLD)
	h.add_child(l)
	Game.coins_changed.connect(func():
		if is_instance_valid(l):
			l.text = money(Game.coins))
	return p

static func star_icon(r: float, on: bool) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(r * 2.0 + 6.0, r * 2.0 + 6.0)
	c.pivot_offset = Vector2(r + 3.0, r + 3.0)
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(10):
		var a: float = -PI / 2.0 + float(i) * PI / 5.0
		var rr: float = r if i % 2 == 0 else r * 0.45
		pts.append(Vector2(cos(a), sin(a)) * rr)
	p.polygon = pts
	p.color = GOLD if on else Color(1, 1, 1, 0.2)
	p.position = Vector2(r + 3.0, r + 3.0)
	c.add_child(p)
	return c

static func toast(parent: Control, text: String) -> void:
	var l := label(text, 32, Color.WHITE)
	parent.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 90)
	var t := l.create_tween()
	t.tween_interval(1.0)
	t.tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(l.queue_free)

static func rim_of(c: Dictionary) -> Color:
	var s: String = c["style"]
	if s == "monster" or s == "tractor":
		return c["c2"]
	if s == "super":
		return Color("ffd43b")
	return Color("c9c9c9")

static func car_preview(i: int) -> Node2D:
	var c: Dictionary = Game.cars[i]
	var root := Node2D.new()
	var body := CarBody.new()
	body.setup(c)
	root.add_child(body)
	var ws: Array = []
	var s: String = c["style"]
	var knob: bool = s == "monster" or s == "tractor" or s == "army"
	for sx in [-1.0, 1.0]:
		var w := WheelVis.new()
		w.r = c["wr"]
		w.rim = rim_of(c)
		w.knobby = knob
		w.position = Vector2(float(sx) * float(c["wx"]), float(c["wy"]))
		root.add_child(w)
		ws.append(w)
	root.set_meta("wheels", ws)
	return root

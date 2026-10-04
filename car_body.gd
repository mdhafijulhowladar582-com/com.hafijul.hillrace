extends Node2D
# গাড়ির ছবি (কোডে আঁকা)। 10টা স্টাইল।

var style := "jeep"
var cw := 130.0
var ch := 34.0
var c1 := Color("e8590c")
var c2 := Color("f08c00")
var top := -80.0   # ক্যাবিনের উপরের y
var hx := 0.0      # মাথার x
var _body := PackedVector2Array()
var _cab := PackedVector2Array()

func setup(c: Dictionary) -> void:
	style = c["style"]
	cw = c["cw"]
	ch = c["ch"]
	c1 = c["c1"]
	c2 = c["c2"]
	build()

func P(a: Array, sx: float, sy: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var i := 0
	while i < a.size():
		out.append(Vector2(float(a[i]) * sx, float(a[i + 1]) * sy))
		i += 2
	return out

func shrink(p: PackedVector2Array, k: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for v in p:
		c += v
	c /= float(p.size())
	var out := PackedVector2Array()
	for v in p:
		out.append(c + (v - c) * k)
	return out

func build() -> void:
	var hw := cw * 0.5
	var hh := ch * 0.5
	match style:
		"buggy":
			_body = P([-1, 0.1, -0.8, -0.6, 0.8, -0.6, 1, 0.1, 1, 1, -1, 1], hw, hh)
			_cab = P([-0.45, -0.6, -0.35, -2.4, 0.3, -2.4, 0.45, -0.6], hw, hh)
		"pickup":
			_body = P([-1, -0.9, 0.85, -0.9, 1, -0.3, 1, 1, -1, 1], hw, hh)
			_cab = P([0.0, -0.9, 0.12, -2.3, 0.6, -2.3, 0.85, -0.9], hw, hh)
		"rally":
			_body = P([-1, -0.2, -0.95, -0.9, 0.7, -1, 1, -0.1, 1, 1, -1, 1], hw, hh)
			_cab = P([-0.3, -1, -0.1, -2.2, 0.35, -2.2, 0.65, -1], hw, hh)
		"monster":
			_body = P([-1, -0.5, -0.9, -1, 0.9, -1, 1, -0.4, 1, 1, -1, 1], hw, hh)
			_cab = P([-0.3, -1, -0.2, -2.3, 0.4, -2.3, 0.6, -1], hw, hh)
		"tractor":
			_body = P([-1, -0.2, -1, 1, 1, 1, 1, -0.5, 0.1, -0.5, 0.1, -0.2], hw, hh)
			_cab = P([-0.8, -0.2, -0.75, -2.6, -0.1, -2.6, -0.05, -0.2], hw, hh)
		"sports":
			_body = P([-1, 0.2, -0.95, -0.5, -0.2, -0.8, 0.5, -0.9, 1, 0, 1, 1, -1, 1], hw, hh)
			_cab = P([-0.25, -0.8, 0.0, -1.9, 0.35, -1.9, 0.6, -0.9], hw, hh)
		"rover":
			_body = P([-1, -0.5, -1, 1, 1, 1, 1, -0.5], hw, hh)
			_cab = P([-0.5, -0.5, -0.5, -1.9, 0.5, -1.9, 0.5, -0.5], hw, hh)
		"army":
			_body = P([-1, -0.5, -0.95, -1, 0.9, -1, 1, -0.4, 1, 1, -1, 1], hw, hh)
			_cab = P([-0.4, -1, -0.35, -2.2, 0.3, -2.2, 0.45, -1], hw, hh)
		"super":
			_body = P([-1, 0.3, -0.9, -0.4, 0.2, -0.9, 0.9, -0.4, 1, 0.2, 1, 1, -1, 1], hw, hh)
			_cab = P([-0.1, -0.8, 0.15, -1.9, 0.4, -1.9, 0.7, -0.7], hw, hh)
		_:
			_body = P([-1, -0.4, -0.9, -1, 0.85, -1, 1, -0.3, 1, 1, -1, 1], hw, hh)
			_cab = P([-0.35, -1, -0.2, -2.4, 0.25, -2.4, 0.5, -1], hw, hh)
	var mn := 0.0
	var sx := 0.0
	for p in _cab:
		mn = minf(mn, p.y)
		sx += p.x
	top = mn
	hx = sx / float(_cab.size())
	queue_redraw()

func _ready() -> void:
	if _body.size() == 0:
		build()

func _draw() -> void:
	if _body.size() == 0:
		return
	var hw := cw * 0.5
	var hh := ch * 0.5
	draw_colored_polygon(_body, c1)
	if style == "buggy":
		draw_polyline(_cab, c2, 5.0)
	else:
		draw_colored_polygon(_cab, c2)
		draw_colored_polygon(shrink(_cab, 0.68), Color("cde8ff"))
	match style:
		"jeep":
			draw_circle(Vector2(-hw - 5.0, -hh * 0.1), hh * 0.85, Color("2b2b2b"))
		"pickup":
			draw_rect(Rect2(-hw, -hh * 1.05, hw * 1.0, hh * 0.18), c1.darkened(0.35))
		"rally":
			draw_rect(Rect2(-hw - 2.0, -hh * 1.9, hw * 0.35, hh * 0.22), c2)
			draw_rect(Rect2(-hw * 0.9, -hh * 1.7, hw * 0.06, hh * 0.75), c2)
		"monster":
			draw_rect(Rect2(-hw, -hh * 0.2, cw, hh * 0.28), c2)
		"tractor":
			draw_rect(Rect2(hw * 0.55, -hh * 1.9, hw * 0.1, hh * 1.4), Color("343a40"))
		"sports", "super":
			draw_rect(Rect2(-hw, -hh * 0.45, cw, hh * 0.18), c2)
		"rover":
			draw_line(Vector2(hw * 0.45, top), Vector2(hw * 0.45, top - 26.0), Color("dee2e6"), 3.0)
			draw_circle(Vector2(hw * 0.45, top - 28.0), 9.0, Color("f1f3f5"))
		"army":
			draw_circle(Vector2(hw * 0.2, hh * 0.2), hh * 0.5, Color("e9ecef"))
			draw_line(Vector2(hw * 0.2, -hh * 1.9), Vector2(hw * 1.1, -hh * 2.3), Color("212529"), 6.0)
	var ol := PackedVector2Array(_body)
	ol.append(_body[0])
	draw_polyline(ol, c1.darkened(0.45), 2.5)
	draw_rect(Rect2(hw - 6.0, -hh * 0.35, 8.0, hh * 0.6), Color("fff3bf"))
	draw_rect(Rect2(-hw - 2.0, -hh * 0.35, 5.0, hh * 0.6), Color("e03131"))
	var hp := Vector2(hx, top - 7.0)
	draw_circle(hp, 10.0, Color("ffd8a8"))
	draw_arc(hp, 10.0, PI, TAU, 12, Color("1c7ed6"), 5.0)

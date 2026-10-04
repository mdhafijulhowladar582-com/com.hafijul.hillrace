extends Node2D
# প্যারালাক্স ব্যাকগ্রাউন্ড: আকাশ, তারা, মেঘ, পাহাড়/শহর।

var map: Dictionary = {}
var cam_x := 0.0
var time := 0.0
var show_ground := false
var auto_scroll := 0.0

func _process(delta: float) -> void:
	time += delta
	cam_x += auto_scroll * delta
	queue_redraw()

func _draw() -> void:
	if map.is_empty():
		return
	var sz: Vector2 = get_viewport_rect().size
	var top: Color = map["sky1"]
	var bot: Color = map["sky2"]
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x, sz.y), Vector2(0, sz.y)]), PackedColorArray([top, top, bot, bot]))
	if map["stars"]:
		for i in range(70):
			var sx: float = fposmod(float(i) * 137.5 * 3.0 - cam_x * 0.02, sz.x)
			var sy: float = fposmod(float(i) * 61.8 * 7.0, sz.y * 0.65)
			var a: float = 0.35 + 0.55 * absf(sin(time * 1.5 + float(i)))
			draw_circle(Vector2(sx, sy), 1.0 + float(i % 3) * 0.7, Color(1, 1, 1, a))
	var orb: Color = map["orb"]
	var orb_r: float = map["orb_r"]
	var op := Vector2(sz.x * 0.78, sz.y * 0.2)
	draw_circle(op, orb_r * 1.5, Color(orb.r, orb.g, orb.b, 0.12))
	draw_circle(op, orb_r, orb)
	if map["clouds"]:
		for i in range(6):
			var cx: float = fposmod(float(i) * 330.0 + time * 10.0 - cam_x * 0.06, sz.x + 400.0) - 200.0
			var cy: float = sz.y * (0.1 + 0.07 * float(i % 3))
			var cc := Color(1, 1, 1, 0.75)
			draw_circle(Vector2(cx, cy), 28.0, cc)
			draw_circle(Vector2(cx + 30.0, cy + 6.0), 22.0, cc)
			draw_circle(Vector2(cx - 30.0, cy + 8.0), 20.0, cc)
	var layers: Array = map["bg"]
	var facs := [0.08, 0.16, 0.3]
	var bases := [0.62, 0.72, 0.82]
	var amps := [90.0, 70.0, 50.0]
	var freqs := [0.004, 0.006, 0.009]
	for li in range(3):
		var col: Color = layers[li]
		var cxo: float = cam_x * float(facs[li])
		if map["bgstyle"] == "city":
			draw_city(sz, li, cxo, col, float(bases[li]))
		else:
			var pts := PackedVector2Array()
			var x := 0.0
			var fr: float = float(freqs[li])
			var am: float = float(amps[li])
			while x <= sz.x + 40.0:
				var wx: float = x + cxo
				var y: float = sz.y * float(bases[li]) + sin(wx * fr + float(li) * 1.7) * am + sin(wx * fr * 2.3 + float(li)) * am * 0.4
				pts.append(Vector2(x, y))
				x += 40.0
			pts.append(Vector2(sz.x + 40.0, sz.y))
			pts.append(Vector2(0, sz.y))
			draw_colored_polygon(pts, col)
	if show_ground:
		var gy: float = sz.y * 0.8
		var gc: Color = map["ground"]
		var gg: Color = map["grass"]
		draw_rect(Rect2(0, gy, sz.x, sz.y - gy), gc)
		draw_rect(Rect2(0, gy - 6.0, sz.x, 12.0), gg)

func draw_city(sz: Vector2, li: int, cxo: float, col: Color, base: float) -> void:
	var bw := 70.0
	var first: int = int(floor(cxo / bw))
	var n: int = int(sz.x / bw) + 3
	for k in range(first, first + n):
		var h: float = 60.0 + float(posmod(k * 7919 + li * 131, 97)) * (2.2 - float(li) * 0.4)
		var x: float = float(k) * bw - cxo
		var y: float = sz.y * base + 40.0 - h
		draw_rect(Rect2(x, y, bw - 6.0, sz.y - y), col)
		if li >= 1:
			for r in range(int(h / 26.0)):
				for c in range(2):
					if posmod(k * 31 + r * 7 + c * 13, 3) != 0:
						draw_rect(Rect2(x + 12.0 + float(c) * 28.0, y + 10.0 + float(r) * 24.0, 10.0, 12.0), Color(1.0, 0.85, 0.4, 0.6))

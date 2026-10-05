extends Area2D

var kind := "coin"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 4
	var cs := CollisionShape2D.new()
	if kind == "pad":
		var r := RectangleShape2D.new()
		r.size = Vector2(150.0, 50.0)
		cs.shape = r
		cs.position = Vector2(0, -20)
	else:
		var c := CircleShape2D.new()
		c.radius = 28.0
		cs.shape = c
	add_child(cs)

func _draw() -> void:
	if kind == "pad":
		draw_rect(Rect2(-72, -7, 144, 14), Color("212529"))
		draw_rect(Rect2(-72, -9, 144, 4), Color("ffd43b"))
		for i in range(4):
			var x: float = -54.0 + float(i) * 34.0
			draw_colored_polygon(PackedVector2Array([Vector2(x, -4), Vector2(x + 16, 0), Vector2(x, 4), Vector2(x + 7, 0)]), Color("ffd43b"))
		return
	if kind == "coin":
		draw_circle(Vector2.ZERO, 16.0, Color("ffd43b"))
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color("e67700"), 3.0)
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 20, Color("e67700"), 2.0)
	elif kind == "fuel":
		draw_rect(Rect2(-14, -18, 28, 36), Color("e03131"))
		draw_rect(Rect2(-6, -25, 12, 7), Color("c92a2a"))
		draw_rect(Rect2(-8, -4, 16, 4), Color.WHITE)
		draw_rect(Rect2(-2, -10, 4, 16), Color.WHITE)
	elif kind == "nitro":
		draw_circle(Vector2.ZERO, 24.0, Color(0.2, 0.6, 1.0, 0.25))
		draw_circle(Vector2.ZERO, 19.0, Color("1c7ed6"))
		draw_colored_polygon(PackedVector2Array([Vector2(4, -16), Vector2(-9, 3), Vector2(-1, 3), Vector2(-5, 16), Vector2(9, -4), Vector2(1, -4)]), Color("ffe066"))
	elif kind == "magnet":
		draw_circle(Vector2.ZERO, 24.0, Color(0.7, 0.3, 1.0, 0.25))
		draw_circle(Vector2.ZERO, 19.0, Color("7048e8"))
		draw_arc(Vector2(0, 2), 9.0, PI, TAU, 14, Color("f8f9fa"), 6.0)
		draw_rect(Rect2(-12, 2, 7, 11), Color("e03131"))
		draw_rect(Rect2(5, 2, 7, 11), Color("e03131"))
	elif kind == "x2":
		draw_circle(Vector2.ZERO, 24.0, Color(1.0, 0.8, 0.1, 0.25))
		draw_circle(Vector2.ZERO, 19.0, Color("f08c00"))
		draw_line(Vector2(-11, -8), Vector2(-3, 8), Color.WHITE, 4.0)
		draw_line(Vector2(-3, -8), Vector2(-11, 8), Color.WHITE, 4.0)
		draw_polyline(PackedVector2Array([Vector2(2, -6), Vector2(8, -9), Vector2(13, -5), Vector2(3, 8), Vector2(13, 8)]), Color.WHITE, 3.5)

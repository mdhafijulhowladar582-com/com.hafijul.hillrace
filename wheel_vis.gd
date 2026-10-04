extends Node2D

var r := 30.0
var rim := Color("c9c9c9")
var knobby := false

func _draw() -> void:
	draw_circle(Vector2.ZERO, r, Color("1b1b1b"))
	if knobby:
		for i in range(16):
			var a: float = TAU * float(i) / 16.0
			draw_circle(Vector2(cos(a), sin(a)) * (r - 2.0), r * 0.1, Color("2f2f2f"))
	draw_circle(Vector2.ZERO, r * 0.62, rim)
	draw_circle(Vector2.ZERO, r * 0.46, Color("3a3a3a"))
	for i in range(5):
		var a2: float = TAU * float(i) / 5.0
		draw_line(Vector2.ZERO, Vector2(cos(a2), sin(a2)) * r * 0.58, rim.darkened(0.25), 3.0)
	draw_circle(Vector2.ZERO, r * 0.14, rim.darkened(0.35))

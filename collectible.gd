extends Area2D

var kind := "coin"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 4
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 26.0
	cs.shape = c
	add_child(cs)

func _draw() -> void:
	if kind == "coin":
		draw_circle(Vector2.ZERO, 16.0, Color("ffd43b"))
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color("e67700"), 3.0)
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 20, Color("e67700"), 2.0)
	else:
		draw_rect(Rect2(-14, -18, 28, 36), Color("e03131"))
		draw_rect(Rect2(-6, -25, 12, 7), Color("c92a2a"))
		draw_rect(Rect2(-8, -4, 16, 4), Color.WHITE)
		draw_rect(Rect2(-2, -10, 4, 16), Color.WHITE)

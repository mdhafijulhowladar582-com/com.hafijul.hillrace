extends Control

const UI = preload("res://ui.gd")
const BgScript = preload("res://background.gd")

var main
var bg
var car_node: Node2D

func on_back() -> void:
	get_tree().quit()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sz: Vector2 = get_viewport_rect().size
	bg = BgScript.new()
	bg.map = Game.maps[Game.sel_map]
	bg.show_ground = true
	bg.auto_scroll = 120.0
	add_child(bg)

	# animated car on the ground
	var cdata: Dictionary = Game.cars[Game.sel_car]
	car_node = UI.car_preview(Game.sel_car)
	var sc := 1.4
	car_node.scale = Vector2(sc, sc)
	var y0: float = sz.y * 0.8 - (float(cdata["wy"]) + float(cdata["wr"])) * sc
	car_node.position = Vector2(sz.x * 0.17, y0)
	add_child(car_node)
	var tw := create_tween()
	tw.set_loops()
	tw.set_parallel(true)
	for w in car_node.get_meta("wheels"):
		tw.tween_property(w, "rotation", TAU, 0.8).from(0.0)
	var tw2 := create_tween()
	tw2.set_loops()
	tw2.tween_property(car_node, "position:y", y0 - 5.0, 0.35).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(car_node, "position:y", y0, 0.35).set_trans(Tween.TRANS_SINE)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	add_child(vb)
	var title := UI.label("HILL RACE", 120, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := UI.label("Climb. Collect. Conquer.", 34, Color(1, 1, 1, 0.9))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var play := UI.button("PLAY", UI.GREEN, 60, Vector2(460, 120))
	play.pressed.connect(func(): main.go("maps"))
	vb.add_child(play)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var garage := UI.button("GARAGE", UI.BLUE, 38, Vector2(222, 90))
	garage.pressed.connect(func(): main.go("garage"))
	row.add_child(garage)
	var settings := UI.button("SETTINGS", UI.GRAY, 38, Vector2(222, 90))
	settings.pressed.connect(func(): main.go("settings"))
	row.add_child(settings)
	vb.add_child(row)
	vb.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.position.y -= 40.0

	var badge := UI.coin_badge()
	add_child(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	var stl := UI.label("Stars: %d / 30" % Game.total_stars(), 32, UI.GOLD)
	add_child(stl)
	stl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	var ver := UI.label("v1.0", 22, Color(1, 1, 1, 0.7))
	add_child(ver)
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)

	vb.modulate.a = 0.0
	var tw3 := create_tween()
	tw3.tween_property(vb, "modulate:a", 1.0, 0.4)

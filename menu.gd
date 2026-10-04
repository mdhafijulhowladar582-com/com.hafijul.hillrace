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
	vb.add_theme_constant_override("separation", 12)
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
	var trophies := UI.button("TROPHIES", UI.ORANGE, 38, Vector2(460, 80))
	trophies.pressed.connect(func(): main.go("ach"))
	vb.add_child(trophies)
	vb.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.position.y -= 50.0

	var badge := UI.coin_badge()
	add_child(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	var stl := UI.label("Stars: %d / 30" % Game.total_stars(), 32, UI.GOLD)
	add_child(stl)
	stl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	var ver := UI.label("v1.2", 22, Color(1, 1, 1, 0.7))
	add_child(ver)
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)

	vb.modulate.a = 0.0
	var tw3 := create_tween()
	tw3.tween_property(vb, "modulate:a", 1.0, 0.4)

	if Game.pending_ach.size() > 0:
		UI.toast(self, "Achievement unlocked: " + ", ".join(PackedStringArray(Game.pending_ach)))
		Sfx.play("ach")
		Game.pending_ach.clear()
	if Game.daily_available():
		call_deferred("show_daily")

func show_daily() -> void:
	var s: int = Game.next_streak()
	var cur_day: int = mini(s, 7)
	var ov := Control.new()
	add_child(ov)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	ov.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := UI.panel_box(Color(0.06, 0.08, 0.16, 0.97), 28)
	ov.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	card.add_child(v)
	var t := UI.label("DAILY REWARD", 56, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var days := HBoxContainer.new()
	days.alignment = BoxContainer.ALIGNMENT_CENTER
	days.add_theme_constant_override("separation", 8)
	for d in range(1, 8):
		var pc := PanelContainer.new()
		var col := Color(1, 1, 1, 0.12)
		if d < cur_day:
			col = Color(0.18, 0.69, 0.30, 0.6)
		elif d == cur_day:
			col = UI.GOLD
		pc.add_theme_stylebox_override("panel", UI.style(col, 14, Color(0, 0, 0, 0), 0))
		var dv := VBoxContainer.new()
		dv.add_child(UI.label("Day %d" % d, 20, Color.WHITE))
		dv.add_child(UI.label("%d" % Game.daily_reward_for(d), 26, Color.WHITE))
		pc.add_child(dv)
		days.add_child(pc)
	v.add_child(days)
	var amount := UI.label("+%s coins" % UI.money(Game.daily_reward_for(s)), 52, UI.GOLD)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(amount)
	var note := UI.label("Come back every day for bigger rewards!", 26, Color(1, 1, 1, 0.85))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(note)
	var claim := UI.button("CLAIM", UI.GREEN, 48, Vector2(0, 100))
	claim.pressed.connect(func():
		Game.claim_daily()
		Sfx.play("daily")
		ov.queue_free())
	v.add_child(claim)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH

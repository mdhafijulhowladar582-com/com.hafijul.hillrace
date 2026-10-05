extends Control
# ডেইলি মিশন: রোজ ৩টা, শেষ করে CLAIM চাপলে কয়েন।

const UI = preload("res://ui.gd")
const BgScript = preload("res://background.gd")

var main

func on_back() -> void:
	main.go("menu")

func _ready() -> void:
	Game.refresh_missions()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg = BgScript.new()
	bg.map = Game.maps[Game.sel_map]
	bg.auto_scroll = 40.0
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 24)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var top := HBoxContainer.new()
	var back := UI.button("BACK", UI.GRAY, 30, Vector2(170, 70))
	back.pressed.connect(func(): main.go("menu"))
	top.add_child(back)
	var title := UI.label("DAILY MISSIONS", 54, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	top.add_child(UI.coin_badge())
	root.add_child(top)

	var sub := UI.label("New missions every day", 28, Color(1, 1, 1, 0.85))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)

	for i in range(Game.missions.size()):
		root.add_child(make_row(i))

func make_row(i: int) -> Control:
	var m: Dictionary = Game.missions[i]
	var target: float = m["target"]
	var prog: float = minf(float(m["prog"]), target)
	var done: bool = prog >= target
	var claimed: bool = m["claimed"]
	var p := UI.panel_box(UI.PANEL, 22)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	p.add_child(h)
	h.add_child(UI.star_icon(24.0, claimed))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label(Game.mission_text(m), 34, Color.WHITE))
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, 20)
	b.max_value = 100.0
	b.value = prog / target * 100.0
	b.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = UI.GREEN if done else UI.GOLD
	fill.set_corner_radius_all(8)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.15)
	back.set_corner_radius_all(8)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", back)
	v.add_child(b)
	v.add_child(UI.label("%d / %d" % [int(prog), int(target)], 24, Color(1, 1, 1, 0.8)))
	h.add_child(v)
	var btn: Button
	if claimed:
		btn = UI.button("DONE", UI.GRAY, 32, Vector2(220, 86))
		btn.disabled = true
	elif done:
		btn = UI.button("CLAIM +%d" % int(m["reward"]), UI.GREEN, 30, Vector2(220, 86))
		btn.pressed.connect(func():
			var r: int = Game.claim_mission(i)
			if r > 0:
				Sfx.play("daily")
				Game.vibrate(50)
				main.go("missions"))
	else:
		btn = UI.button("+%d" % int(m["reward"]), UI.ORANGE, 32, Vector2(220, 86))
		btn.disabled = true
	h.add_child(btn)
	return p

extends Control

const UI = preload("res://ui.gd")
const BgScript = preload("res://background.gd")

var main
var reset_armed := false

func on_back() -> void:
	main.go("menu")

func make_toggle(title: String, value: bool, setter: Callable) -> Button:
	var b := UI.button("", UI.GREEN, 36, Vector2(560, 90))
	var state := [value]
	var refresh := func():
		b.text = "%s: %s" % [title, "ON" if state[0] else "OFF"]
		b.add_theme_stylebox_override("normal", UI.btn_style(UI.GREEN if state[0] else UI.GRAY, false))
	refresh.call()
	b.pressed.connect(func():
		state[0] = not state[0]
		setter.call(state[0])
		refresh.call())
	return b

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg = BgScript.new()
	bg.map = Game.maps[Game.sel_map]
	bg.auto_scroll = 40.0
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var back := UI.button("BACK", UI.GRAY, 30, Vector2(170, 70))
	back.pressed.connect(func(): main.go("menu"))
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	add_child(vb)
	var title := UI.label("SETTINGS", 64, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	vb.add_child(make_toggle("Sound Effects", Game.sound_on, func(v):
		Game.sound_on = v
		Game.save_game()))
	vb.add_child(make_toggle("Music", Game.music_on, func(v):
		Game.music_on = v
		Sfx.apply_music()
		Game.save_game()))
	vb.add_child(make_toggle("Vibration", Game.vibrate_on, func(v):
		Game.vibrate_on = v
		Game.save_game()
		if v:
			Game.vibrate(60)))
	vb.add_child(make_toggle("Swap Pedals", Game.swap_pedals, func(v):
		Game.swap_pedals = v
		Game.save_game()))
	vb.add_child(make_toggle("Debug Info", Game.debug_on, func(v):
		Game.debug_on = v
		Game.save_game()))
	var reset := UI.button("RESET PROGRESS", UI.RED, 34, Vector2(560, 80))
	reset.pressed.connect(func():
		if not reset_armed:
			reset_armed = true
			reset.text = "TAP AGAIN TO CONFIRM"
		else:
			Game.reset_progress()
			main.go("settings"))
	vb.add_child(reset)
	var about := UI.label("Hill Race v1.5   com.navalabs.hillrace", 24, Color(1, 1, 1, 0.8))
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(about)
	vb.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH

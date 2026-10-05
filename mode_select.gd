extends Control
# PLAY চাপলে মুড বাছাই: Adventure বা Ghost Race

const UI = preload("res://ui.gd")
const BgScript = preload("res://background.gd")

var main
var level_buttons: Array = []

func on_back() -> void:
	main.go("menu")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg = BgScript.new()
	bg.map = Game.maps[Game.sel_map]
	bg.auto_scroll = 50.0
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
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
	var title := UI.label("SELECT MODE", 54, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	top.add_child(UI.coin_badge())
	root.add_child(top)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	root.add_child(row)
	row.add_child(adventure_panel())
	row.add_child(ghost_panel())

func panel_base(title: String, desc: String, tcol: Color) -> VBoxContainer:
	var p := UI.panel_box(UI.PANEL, 28)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var t := UI.label(title, 46, tcol)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var d := UI.label(desc, 26, Color(0.9, 0.94, 1.0))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.custom_minimum_size = Vector2(420, 0)
	v.add_child(d)
	set_meta("last_panel", p)
	return v

func adventure_panel() -> Control:
	var v := panel_base("ADVENTURE", "Drive through the maps, collect coins, earn stars and unlock new cars and maps.", UI.GREEN)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var b := UI.button("PLAY ADVENTURE", UI.GREEN, 38, Vector2(0, 100))
	b.pressed.connect(func():
		Game.mode = "adventure"
		main.go("maps"))
	v.add_child(b)
	return get_meta("last_panel")

func ghost_panel() -> Control:
	var v := panel_base("GHOST RACE", "Race a ghost of your own best run. Beat its distance to win bonus coins!", UI.GOLD)
	v.add_child(UI.label("DIFFICULTY", 28, Color.WHITE))
	var lr := HBoxContainer.new()
	lr.add_theme_constant_override("separation", 10)
	var names := ["NORMAL", "HARD", "EXTREME"]
	for i in range(3):
		var lb := UI.button(names[i], UI.GRAY, 28, Vector2(0, 70))
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.pressed.connect(func():
			Game.ghost_level = i
			Game.save_game()
			refresh_levels())
		lr.add_child(lb)
		level_buttons.append(lb)
	v.add_child(lr)
	var info := UI.label("Normal = your best  |  Hard +5%  |  Extreme +10%\nWin bonus: 150 / 225 / 300 coins", 22, Color(1, 1, 1, 0.85))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var b := UI.button("PLAY GHOST RACE", UI.ORANGE, 38, Vector2(0, 100))
	b.pressed.connect(func():
		Game.mode = "ghost"
		main.go("maps"))
	v.add_child(b)
	refresh_levels()
	return get_meta("last_panel")

func refresh_levels() -> void:
	for i in range(level_buttons.size()):
		var col: Color = UI.GOLD if i == Game.ghost_level else UI.GRAY
		level_buttons[i].add_theme_stylebox_override("normal", UI.btn_style(col, false))

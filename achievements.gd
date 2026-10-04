extends Control
# Trophies: সব অ্যাচিভমেন্ট ও অগ্রগতি।

const UI = preload("res://ui.gd")
const BgScript = preload("res://background.gd")

var main
var scroll: ScrollContainer
var spos := 0.0

func on_back() -> void:
	main.go("menu")

func _ready() -> void:
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
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var top := HBoxContainer.new()
	var back := UI.button("BACK", UI.GRAY, 30, Vector2(170, 70))
	back.pressed.connect(func(): main.go("menu"))
	top.add_child(back)
	var title := UI.label("TROPHIES", 54, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	top.add_child(UI.coin_badge())
	root.add_child(top)

	var done: int = Game.count_true(Game.ach)
	var sub := UI.label("%d / %d unlocked" % [done, Game.achievements.size()], 30, UI.GOLD)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for i in range(Game.achievements.size()):
		list.add_child(make_row(i))

func make_row(i: int) -> Control:
	var a: Dictionary = Game.achievements[i]
	var unlocked: bool = Game.ach[i]
	var kind: String = a["kind"]
	var target: float = a["target"]
	var cur: float = minf(Game.ach_value(kind), target)
	var p := UI.panel_box(UI.PANEL, 22)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	p.add_child(h)
	h.add_child(UI.star_icon(24.0, unlocked))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label(a["name"], 32, Color.WHITE))
	v.add_child(UI.label(a["desc"], 24, Color(0.85, 0.9, 1.0)))
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, 18)
	b.max_value = 100.0
	b.value = cur / target * 100.0
	b.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = UI.GREEN if unlocked else UI.GOLD
	fill.set_corner_radius_all(8)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.15)
	back.set_corner_radius_all(8)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", back)
	v.add_child(b)
	h.add_child(v)
	var prog := "%d / %d" % [int(cur), int(target)]
	if kind == "air":
		prog = "%.1f / %d s" % [cur, int(target)]
	var rv := VBoxContainer.new()
	var rl := UI.label("+%d" % int(a["reward"]), 32, UI.GOLD)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv.add_child(rl)
	var pl := UI.label("DONE" if unlocked else prog, 24, UI.GREEN if unlocked else Color(1, 1, 1, 0.8))
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv.add_child(pl)
	h.add_child(rv)
	return p

# টেনে উপর-নিচ স্ক্রল (টাচ ড্র্যাগ)
func _input(event: InputEvent) -> void:
	if scroll == null:
		return
	var touch_dev: bool = DisplayServer.is_touchscreen_available()
	if event is InputEventScreenTouch and event.pressed:
		spos = float(scroll.scroll_vertical)
	elif event is InputEventMouseButton and not touch_dev and event.pressed:
		spos = float(scroll.scroll_vertical)
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and not touch_dev and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0):
		if not scroll.get_global_rect().has_point(event.position):
			return
		var vb: VScrollBar = scroll.get_v_scroll_bar()
		spos = clampf(spos - event.relative.y, 0.0, maxf(0.0, vb.max_value - vb.page))
		scroll.scroll_vertical = int(spos)

extends Control

const UI = preload("res://ui.gd")
const BgScript = preload("res://background.gd")
const CARD_STEP := 360

var main
var scroll: ScrollContainer
var act_buttons: Array = []
var dragging := false
var drag_dx := 0.0
var spos := 0.0

func on_back() -> void:
	main.go("menu")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg = BgScript.new()
	bg.map = Game.maps[Game.sel_map]
	bg.auto_scroll = 60.0
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 20)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var top := HBoxContainer.new()
	var back := UI.button("BACK", UI.GRAY, 30, Vector2(170, 66))
	back.pressed.connect(func(): main.go("menu"))
	top.add_child(back)
	var title_txt := "SELECT MAP"
	if Game.mode == "ghost":
		title_txt = "GHOST RACE - SELECT MAP"
	if Game.mode == "survival":
		title_txt = "SURVIVAL - SELECT MAP"
	var title := UI.label(title_txt, 46, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	top.add_child(UI.coin_badge())
	root.add_child(top)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	root.add_child(scroll)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 20)
	scroll.add_child(cards)
	for i in range(Game.maps.size()):
		cards.add_child(make_card(i))

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	var cname: String = Game.cars[Game.sel_car]["name"]
	var cl := UI.label("Car: " + cname, 32, Color.WHITE)
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(cl)
	var lb := UI.button("<", UI.GRAY, 40, Vector2(90, 66))
	lb.pressed.connect(func(): nav(-1))
	bottom.add_child(lb)
	var rb := UI.button(">", UI.GRAY, 40, Vector2(90, 66))
	rb.pressed.connect(func(): nav(1))
	bottom.add_child(rb)
	var gb := UI.button("GARAGE", UI.BLUE, 32, Vector2(220, 66))
	gb.pressed.connect(func(): main.go("garage"))
	bottom.add_child(gb)
	root.add_child(bottom)

	var target_x: int = Game.sel_map * CARD_STEP
	scroll.call_deferred("set", "scroll_horizontal", target_x)

func max_scroll() -> float:
	var hb: HScrollBar = scroll.get_h_scroll_bar()
	return maxf(0.0, hb.max_value - hb.page)

func nav(dir: int) -> void:
	var cur: int = scroll.scroll_horizontal
	var target: float = clampf(float(cur + dir * CARD_STEP), 0.0, max_scroll())
	var tw := create_tween()
	tw.tween_property(scroll, "scroll_horizontal", int(target), 0.25).set_trans(Tween.TRANS_SINE)

# ---- ডানে-বামে টেনে স্ক্রল (টাচ ড্র্যাগ) ----
func enable_buttons() -> void:
	for b in act_buttons:
		if is_instance_valid(b):
			b.disabled = false

func end_drag() -> void:
	if dragging:
		dragging = false
		get_tree().create_timer(0.12).timeout.connect(enable_buttons)

func _input(event: InputEvent) -> void:
	if scroll == null:
		return
	var touch_dev: bool = DisplayServer.is_touchscreen_available()
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_dx = 0.0
			dragging = false
			spos = float(scroll.scroll_horizontal)
		else:
			end_drag()
	elif event is InputEventMouseButton and not touch_dev:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_dx = 0.0
				dragging = false
				spos = float(scroll.scroll_horizontal)
			else:
				end_drag()
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and not touch_dev and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0):
		if not scroll.get_global_rect().has_point(event.position):
			return
		drag_dx += event.relative.x
		if not dragging and absf(drag_dx) > 16.0:
			dragging = true
			for b in act_buttons:
				b.disabled = true
		if dragging:
			spos = clampf(spos - event.relative.x, 0.0, max_scroll())
			scroll.scroll_horizontal = int(spos)

func make_preview(m: Dictionary, unlocked: bool) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(300, 120)
	c.clip_contents = true
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	var g := Gradient.new()
	g.set_color(0, m["sky1"])
	g.set_color(1, m["sky2"])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 64
	gt.height = 64
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_PASS
	c.add_child(tr)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var amp: float = m["amp"]
	var wl: float = m["wl"]
	var pts := PackedVector2Array()
	var line := PackedVector2Array()
	for k in range(16):
		var x: float = float(k) * 20.0
		var y: float = 82.0 + sin(x * 0.03 * wl) * 14.0 * amp + sin(x * 0.09) * float(m["rough"]) * 0.6
		pts.append(Vector2(x, y))
		line.append(Vector2(x, y))
	pts.append(Vector2(300, 120))
	pts.append(Vector2(0, 120))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = m["ground"]
	c.add_child(poly)
	var ln := Line2D.new()
	ln.points = line
	ln.width = 7.0
	ln.default_color = m["grass"]
	c.add_child(ln)
	if not unlocked:
		var ov := ColorRect.new()
		ov.color = Color(0, 0, 0, 0.6)
		ov.mouse_filter = Control.MOUSE_FILTER_PASS
		c.add_child(ov)
		ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var lk := UI.label("LOCKED", 40, Color.WHITE)
		c.add_child(lk)
		lk.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
		lk.grow_horizontal = Control.GROW_DIRECTION_BOTH
		lk.grow_vertical = Control.GROW_DIRECTION_BOTH
	return c

func make_card(i: int) -> Control:
	var m: Dictionary = Game.maps[i]
	var unlocked: bool = Game.maps_unlocked[i]
	var card := UI.panel_box(UI.PANEL, 24)
	card.custom_minimum_size = Vector2(340, 0)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(v)
	v.add_child(make_preview(m, unlocked))
	v.add_child(UI.label("%d. %s" % [i + 1, m["name"]], 30, Color.WHITE))
	var ds := UI.label(m["desc"], 20, Color(0.85, 0.9, 1.0))
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.custom_minimum_size = Vector2(300, 50)
	v.add_child(ds)
	var targets: Array = Game.map_targets(i)
	v.add_child(UI.label("Goals: %d / %d / %d m" % [targets[0], targets[1], targets[2]], 20, Color(1, 1, 1, 0.85)))
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 2)
	var got: int = Game.stars[i]
	for k in range(3):
		sr.add_child(UI.star_icon(14.0, k < got))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sr.add_child(sp)
	var best_txt: String = "Best: %d m" % int(Game.best[i])
	if Game.mode == "ghost":
		var gdist: float = Game.ghost_dist(i, Game.sel_car)
		best_txt = "Ghost: %d m" % int(gdist) if gdist > 0.0 else "No ghost yet"
	sr.add_child(UI.label(best_txt, 22, UI.GOLD))
	v.add_child(sr)
	var act: Button
	if unlocked:
		act = UI.button("PLAY", UI.GREEN, 36, Vector2(300, 70))
		act.pressed.connect(func():
			Game.sel_map = i
			Game.save_game()
			main.go("game"))
	else:
		var price: int = m["price"]
		act = UI.button("BUY  " + UI.money(price), UI.ORANGE, 32, Vector2(300, 70))
		act.pressed.connect(func():
			if Game.buy_map(i):
				Sfx.play("unlock")
				Game.sel_map = i
				Game.save_game()
				main.go("maps")
			else:
				Sfx.play("error")
				UI.toast(self, "Not enough coins"))
	act_buttons.append(act)
	v.add_child(act)
	return card

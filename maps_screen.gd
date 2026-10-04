extends Control

const UI = preload("res://ui.gd")
const BgScript = preload("res://background.gd")

var main
var scroll: ScrollContainer

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
		margin.add_theme_constant_override("margin_" + s, 24)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var top := HBoxContainer.new()
	var back := UI.button("BACK", UI.GRAY, 30, Vector2(170, 70))
	back.pressed.connect(func(): main.go("menu"))
	top.add_child(back)
	var title := UI.label("SELECT MAP", 54, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	top.add_child(UI.coin_badge())
	root.add_child(top)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 20)
	scroll.add_child(cards)
	for i in range(Game.maps.size()):
		cards.add_child(make_card(i))

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	var cname: String = Game.cars[Game.sel_car]["name"]
	var cl := UI.label("Car: " + cname, 34, Color.WHITE)
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(cl)
	var gb := UI.button("GARAGE", UI.BLUE, 34, Vector2(240, 76))
	gb.pressed.connect(func(): main.go("garage"))
	bottom.add_child(gb)
	root.add_child(bottom)

	var target_x: int = Game.sel_map * 360
	scroll.call_deferred("set", "scroll_horizontal", target_x)

func make_preview(m: Dictionary, unlocked: bool) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(300, 170)
	c.clip_contents = true
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
	c.add_child(tr)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var amp: float = m["amp"]
	var wl: float = m["wl"]
	var pts := PackedVector2Array()
	var line := PackedVector2Array()
	for k in range(16):
		var x: float = float(k) * 20.0
		var y: float = 115.0 + sin(x * 0.03 * wl) * 18.0 * amp + sin(x * 0.09) * float(m["rough"]) * 0.8
		pts.append(Vector2(x, y))
		line.append(Vector2(x, y))
	pts.append(Vector2(300, 170))
	pts.append(Vector2(0, 170))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = m["ground"]
	c.add_child(poly)
	var ln := Line2D.new()
	ln.points = line
	ln.width = 8.0
	ln.default_color = m["grass"]
	c.add_child(ln)
	if not unlocked:
		var ov := ColorRect.new()
		ov.color = Color(0, 0, 0, 0.6)
		c.add_child(ov)
		ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var lk := UI.label("LOCKED", 44, Color.WHITE)
		c.add_child(lk)
		lk.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
		lk.grow_horizontal = Control.GROW_DIRECTION_BOTH
		lk.grow_vertical = Control.GROW_DIRECTION_BOTH
	return c

func make_card(i: int) -> Control:
	var m: Dictionary = Game.maps[i]
	var unlocked: bool = Game.maps_unlocked[i]
	var card := UI.panel_box(UI.PANEL, 26)
	card.custom_minimum_size = Vector2(340, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(make_preview(m, unlocked))
	v.add_child(UI.label("%d. %s" % [i + 1, m["name"]], 32, Color.WHITE))
	var ds := UI.label(m["desc"], 22, Color(0.85, 0.9, 1.0))
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.custom_minimum_size = Vector2(300, 60)
	v.add_child(ds)
	var targets: Array = Game.map_targets(i)
	v.add_child(UI.label("Goals: %d / %d / %d m" % [targets[0], targets[1], targets[2]], 22, Color(1, 1, 1, 0.85)))
	var sr := HBoxContainer.new()
	var got: int = Game.stars[i]
	for k in range(3):
		sr.add_child(UI.star_icon(18.0, k < got))
	v.add_child(sr)
	v.add_child(UI.label("Best: %d m" % int(Game.best[i]), 24, UI.GOLD))
	var act: Button
	if unlocked:
		act = UI.button("PLAY", UI.GREEN, 38, Vector2(300, 80))
		act.pressed.connect(func():
			Game.sel_map = i
			Game.save_game()
			main.go("game"))
	else:
		var price: int = m["price"]
		act = UI.button("BUY  " + UI.money(price), UI.ORANGE, 34, Vector2(300, 80))
		act.pressed.connect(func():
			if Game.buy_map(i):
				Sfx.play("unlock")
				Game.sel_map = i
				Game.save_game()
				main.go("maps")
			else:
				Sfx.play("error")
				UI.toast(self, "Not enough coins"))
	v.add_child(act)
	return card

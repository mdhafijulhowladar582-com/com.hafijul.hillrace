extends Control

const UI = preload("res://ui.gd")
const BgScript = preload("res://background.gd")

var main
var cur := 0

func on_back() -> void:
	main.go("menu")

func _ready() -> void:
	cur = Game.sel_car
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()

func build() -> void:
	for c in get_children():
		c.queue_free()
	var bg = BgScript.new()
	bg.map = Game.maps[Game.sel_map]
	bg.auto_scroll = 40.0
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
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
	var title := UI.label("GARAGE", 54, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	top.add_child(UI.coin_badge())
	root.add_child(top)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)
	body.add_child(left_panel())
	body.add_child(right_panel())

func bar_row(title: String, value: float) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := UI.label(title, 26, Color.WHITE)
	l.custom_minimum_size = Vector2(110, 0)
	h.add_child(l)
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(280, 22)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.max_value = 100.0
	b.value = clampf(value, 0.0, 1.0) * 100.0
	b.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = UI.GOLD
	fill.set_corner_radius_all(8)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.15)
	back.set_corner_radius_all(8)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", back)
	h.add_child(b)
	return h

func left_panel() -> Control:
	var unlocked: bool = Game.cars_unlocked[cur]
	var c: Dictionary = Game.cars[cur]
	var st: Dictionary = Game.effective(cur)
	var p := UI.panel_box(UI.PANEL, 26)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	var lb := UI.button("<", UI.GRAY, 50, Vector2(90, 120))
	lb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lb.pressed.connect(func():
		cur = (cur + 9) % 10
		build())
	nav.add_child(lb)
	var prev := Control.new()
	prev.custom_minimum_size = Vector2(300, 240)
	prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var holder := Control.new()
	prev.add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var car := UI.car_preview(cur)
	car.scale = Vector2(1.5, 1.5)
	car.position = Vector2(0, -25)
	if not unlocked:
		car.modulate = Color(0.2, 0.2, 0.25)
	holder.add_child(car)
	if not unlocked:
		var lk := UI.label("LOCKED", 44, Color.WHITE)
		prev.add_child(lk)
		lk.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
		lk.grow_horizontal = Control.GROW_DIRECTION_BOTH
		lk.grow_vertical = Control.GROW_DIRECTION_BOTH
	nav.add_child(prev)
	var rb := UI.button(">", UI.GRAY, 50, Vector2(90, 120))
	rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rb.pressed.connect(func():
		cur = (cur + 1) % 10
		build())
	nav.add_child(rb)
	v.add_child(nav)

	var nm := UI.label("%d. %s" % [cur + 1, c["name"]], 40, Color.WHITE)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var ds := UI.label(c["desc"], 24, Color(0.85, 0.9, 1.0))
	ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.custom_minimum_size = Vector2(420, 0)
	v.add_child(ds)
	var ab: String = c["ability"]
	if ab != "":
		var atxt := ""
		if ab == "nitro":
			atxt = "Ability: NITRO boost button"
		elif ab == "hop":
			atxt = "Ability: HOP jump button"
		elif ab == "smash":
			atxt = "Ability: smashes rocks"
		var al := UI.label(atxt, 26, UI.GOLD)
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(al)
	var wr: float = c["wr"]
	v.add_child(bar_row("Speed", float(st["vmax"]) * wr / 1700.0))
	v.add_child(bar_row("Power", float(st["power"]) / 150000.0))
	v.add_child(bar_row("Grip", float(st["grip"]) / 2.4))
	v.add_child(bar_row("Fuel", float(st["fuel"]) / 200.0))
	return p

func right_panel() -> Control:
	var unlocked: bool = Game.cars_unlocked[cur]
	var p := UI.panel_box(UI.PANEL, 26)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UI.label("UPGRADES", 40, UI.GOLD))
	for k in range(4):
		var lvl: int = Game.upgrades[cur][k]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UI.label(Game.UPGRADE_NAMES[k], 30, Color.WHITE))
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 6)
		for j in range(Game.MAX_LEVEL):
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(30, 12)
			pip.color = UI.GOLD if j < lvl else Color(1, 1, 1, 0.2)
			pips.add_child(pip)
		col.add_child(pips)
		row.add_child(col)
		var btn: Button
		if lvl >= Game.MAX_LEVEL:
			btn = UI.button("MAX", UI.GRAY, 30, Vector2(190, 76))
			btn.disabled = true
		else:
			var cost: int = Game.upgrade_cost(cur, k)
			btn = UI.button(UI.money(cost), UI.ORANGE, 30, Vector2(190, 76))
			btn.disabled = not unlocked
			btn.pressed.connect(func():
				if Game.buy_upgrade(cur, k):
					Sfx.play("star")
					build()
				else:
					Sfx.play("error")
					UI.toast(self, "Not enough coins"))
		row.add_child(btn)
		v.add_child(row)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var act: Button
	if not unlocked:
		var price: int = Game.cars[cur]["price"]
		act = UI.button("BUY  " + UI.money(price), UI.ORANGE, 40, Vector2(0, 96))
		act.pressed.connect(func():
			if Game.buy_car(cur):
				Sfx.play("unlock")
				build()
			else:
				Sfx.play("error")
				UI.toast(self, "Not enough coins"))
	elif Game.sel_car == cur:
		act = UI.button("SELECTED", UI.GREEN, 40, Vector2(0, 96))
		act.disabled = true
	else:
		act = UI.button("SELECT", UI.GREEN, 40, Vector2(0, 96))
		act.pressed.connect(func():
			Game.sel_car = cur
			Game.save_game()
			build())
	v.add_child(act)
	return p

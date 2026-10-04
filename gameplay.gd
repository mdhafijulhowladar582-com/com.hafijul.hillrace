extends Node2D
# গেমপ্লে: রাস্তা, গাড়ি, HUD, কাউন্টডাউন, ফ্লিপ বোনাস, ক্র্যাশ ইফেক্ট, পজ/টিউনিং, রেজাল্ট।

const CarScript = preload("res://car.gd")
const ItemScript = preload("res://collectible.gd")
const BgScript = preload("res://background.gd")
const UI = preload("res://ui.gd")

const CHUNK_W := 400.0
const STEP := 20.0
const START_X := 200.0
const FUEL_DRAIN := 1.6    # প্রতি সেকেন্ডে ফুয়েল কমার হার (গ্যাস চাপলে)
const FUEL_GAP0 := 30      # প্রথম ফুয়েল ক্যানের পরের দূরত্ব (চাংক)
const FUEL_GAP_STEP := 8   # প্রতিবার ফাঁক এতটা করে বাড়ে (তাই শেষে ফুয়েল ফুরায়)
const FUEL_GAIN := 0.25    # একটা ক্যানে ট্যাংকের কত অংশ ভরে
const FLIP_BONUS := 50     # প্রতি ফ্লিপে বোনাস কয়েন
const AIR_BONUS := 15.0    # প্রতি সেকেন্ড বাতাসে থাকার বোনাস

var main
var map: Dictionary = {}
var map_idx := 0
var car_idx := 0
var car
var cam: Camera2D
var bg
var terrain_root: Node2D
var chunks := {}
var fuel_chunks := {}
var flipped_t := 0.0
var targets: Array = []

var fuel := 100.0
var fuel_max := 100.0
var run_coins := 0
var max_dist := 0.0
var zero_time := 0.0
var time_t := 0.0
var game_over := false
var paused := false
var gas_pressed := false
var brake_pressed := false

# polish
var started := false
var countdown := 3.0
var last_count := 4
var tutorial_active := false
var shake := 0.0
var flips := 0
var air_best := 0.0
var bonus_pts := 0
var air_time := 0.0
var air_rot := 0.0
var prev_rot := 0.0
var was_air := false
var low_timer := 0.9
var was_low := false

var hud: CanvasLayer
var dist_label: Label
var coins_label: Label
var goal_label: Label
var debug_label: Label
var count_label: Label
var low_overlay: ColorRect
var tut_panel: Control
var fuel_bar: ProgressBar
var pause_panel: Control
var pause_main: Control
var pause_tune: Control
var tune_box: VBoxContainer

func on_back() -> void:
	set_paused(not paused)

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	bank_run()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if started and not game_over and not paused and not tutorial_active and hud != null:
			set_paused(true)

func build_fuel_chunks() -> void:
	var c := 12
	var k := 0
	while c < 600:
		fuel_chunks[c] = true
		c += FUEL_GAP0 + FUEL_GAP_STEP * k
		k += 1

# গেম থেকে বের হলেও এ পর্যন্ত আয় করা কয়েন জমা হবে
func bank_run() -> void:
	if game_over:
		return
	game_over = true
	if max_dist > 1.0 or run_coins > 0:
		air_best = maxf(air_best, air_time)
		Game.submit_run(map_idx, max_dist, run_coins, flips, air_best, bonus_pts)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	map_idx = Game.sel_map
	car_idx = Game.sel_car
	map = Game.maps[map_idx]
	targets = Game.map_targets(map_idx)
	var stats: Dictionary = Game.effective(car_idx)
	fuel_max = stats["fuel"]
	fuel = fuel_max
	tutorial_active = not Game.tutorial_done
	RenderingServer.set_default_clear_color(map["sky2"])

	var bgl := CanvasLayer.new()
	bgl.layer = -10
	add_child(bgl)
	bg = BgScript.new()
	bg.map = map
	bgl.add_child(bg)
	if map["fx"] != "none":
		add_fx(map["fx"])

	terrain_root = Node2D.new()
	add_child(terrain_root)
	add_wall()

	var cdata: Dictionary = Game.cars[car_idx]
	car = CarScript.new()
	car.idx = car_idx
	car.map = map
	car.start_pos = Vector2(START_X, terrain_y(START_X) - float(cdata["wy"]) - float(cdata["wr"]) - 6.0)
	add_child(car)
	car.crashed.connect(func(): end_game("CRASHED!", true))
	prev_rot = car.chassis.rotation

	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.zoom = Vector2(0.85, 0.85)
	add_child(cam)
	cam.position = car.chassis.position + Vector2(260, -100)

	build_hud()
	build_fuel_chunks()
	update_chunks()
	Sfx.start_engine()

# ---------------- weather fx ----------------
func add_fx(kind: String) -> void:
	var sz: Vector2 = get_viewport_rect().size
	var l := CanvasLayer.new()
	l.layer = 1
	add_child(l)
	var p := CPUParticles2D.new()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(sz.x * 0.6, 4)
	p.local_coords = true
	p.amount = 90
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 180.0
	p.scale_amount_min = 2.5
	p.scale_amount_max = 6.0
	if kind == "ash":
		p.position = Vector2(sz.x * 0.5, sz.y + 10.0)
		p.direction = Vector2(0.2, -1)
		p.spread = 15.0
		p.color = Color(1.0, 0.55, 0.2, 0.8)
		p.initial_velocity_min = 50.0
		p.initial_velocity_max = 120.0
	else:
		p.position = Vector2(sz.x * 0.5, -10.0)
		p.direction = Vector2(-0.3, 1)
		p.spread = 12.0
		p.color = Color(1, 1, 1, 0.85)
	l.add_child(p)

# ---------------- terrain ----------------
func terrain_y(x: float) -> float:
	var amp_m: float = map["amp"]
	var rough: float = map["rough"]
	var wl: float = map["wl"]
	var t: float = clampf((x - 300.0) / 1500.0, 0.0, 1.0)
	var amp: float = (35.0 + minf(maxf(x, 0.0) * 0.025, 85.0)) * amp_m
	var y := 500.0
	y += sin(x * 0.0025 * wl) * amp * t
	y += sin(x * 0.007 * wl + 1.3) * amp * 0.35 * t
	y += sin(x * 0.021 + 0.5) * (6.0 + rough) * t
	y += sin(x * 0.047 + 2.0) * rough * 0.6 * t
	return y

func add_wall() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 8
	wall.collision_mask = 0
	wall.position = Vector2(-780, 300)
	var ws := CollisionShape2D.new()
	var wr := RectangleShape2D.new()
	wr.size = Vector2(40, 3000)
	ws.shape = wr
	wall.add_child(ws)
	add_child(wall)

func circ(r: float, cx: float, cy: float) -> Array:
	var out: Array = []
	for i in range(14):
		var a: float = TAU * float(i) / 14.0
		out.append(cx + cos(a) * r)
		out.append(cy + sin(a) * r)
	return out

func dpoly(parent: Node, pts: Array, col: Color) -> void:
	var arr := PackedVector2Array()
	var i := 0
	while i < pts.size():
		arr.append(Vector2(float(pts[i]), float(pts[i + 1])))
		i += 2
	var p := Polygon2D.new()
	p.polygon = arr
	p.color = col
	parent.add_child(p)

func add_decor(parent: Node, kind: String, x: float, y: float, col: Color, rng: RandomNumberGenerator) -> void:
	var h := Node2D.new()
	h.position = Vector2(x, y + 8.0)
	var s: float = rng.randf_range(0.8, 1.4)
	h.scale = Vector2(s, s)
	parent.add_child(h)
	match kind:
		"tree":
			dpoly(h, [-5, -60, 5, -60, 5, 10, -5, 10], Color("5c4033"))
			dpoly(h, [1, -60, 5, -60, 5, 10, 1, 10], Color("4a3328"))
			dpoly(h, circ(28.0, 0.0, -70.0), col.darkened(0.15))
			dpoly(h, circ(24.0, -3.0, -73.0), col)
			dpoly(h, circ(14.0, -10.0, -82.0), col.lightened(0.2))
		"pine":
			dpoly(h, [-4, -20, 4, -20, 4, 10, -4, 10], Color("5c4033"))
			dpoly(h, [-26, -25, 0, -80, 26, -25], col.darkened(0.1))
			dpoly(h, [-20, -60, 0, -115, 20, -60], col.lightened(0.1))
			dpoly(h, [-8, -85, 0, -115, 6, -85], Color(1, 1, 1, 0.5))
		"cactus":
			dpoly(h, [-7, -90, 7, -90, 7, 10, -7, 10], col)
			dpoly(h, [-24, -60, -7, -60, -7, -48, -24, -48], col)
			dpoly(h, [-24, -60, -14, -60, -14, -80, -24, -80], col)
			dpoly(h, [7, -45, 24, -45, 24, -33, 7, -33], col)
			dpoly(h, [14, -45, 24, -45, 24, -64, 14, -64], col)
			dpoly(h, [-1, -90, 3, -90, 3, 10, -1, 10], col.lightened(0.2))
		"rock":
			dpoly(h, [-30, 10, -22, -25, 0, -38, 24, -22, 32, 10], col)
			dpoly(h, [-14, -20, 0, -32, 10, -22, -4, -14], col.lightened(0.2))
			dpoly(h, [10, -22, 24, -22, 32, 10, 14, 10], col.darkened(0.2))
		"reed":
			dpoly(h, [-12, -50, -8, -50, -5, 10, -13, 10], col)
			dpoly(h, [-3, -70, 1, -70, 4, 10, -4, 10], col.lightened(0.1))
			dpoly(h, [7, -45, 11, -45, 13, 10, 5, 10], col)
			dpoly(h, [-4, -76, 2, -76, 3, -62, -3, -62], Color("5c4033"))
		"lamp":
			dpoly(h, [-3, -110, 3, -110, 3, 10, -3, 10], Color("495057"))
			dpoly(h, circ(30.0, 0.0, -112.0), Color(col.r, col.g, col.b, 0.10))
			dpoly(h, circ(20.0, 0.0, -112.0), Color(col.r, col.g, col.b, 0.18))
			dpoly(h, circ(9.0, 0.0, -112.0), col)
		"crystal":
			dpoly(h, [-10, 10, -14, -30, 0, -70, 14, -30, 10, 10], col)
			dpoly(h, [-4, 10, -5, -25, 0, -55, 6, -25, 4, 10], col.lightened(0.4))
			dpoly(h, [8, 10, 6, -10, 20, -34, 26, 10], col.darkened(0.15))

func build_chunk(idx: int) -> void:
	var node := Node2D.new()
	terrain_root.add_child(node)
	chunks[idx] = node

	var x0: float = float(idx) * CHUNK_W
	var n: int = int(CHUNK_W / STEP)
	var top := PackedVector2Array()
	for i in range(n + 1):
		var x: float = x0 + float(i) * STEP
		top.append(Vector2(x, terrain_y(x)))

	var rng := RandomNumberGenerator.new()
	rng.seed = idx * 7919 + 13 + map_idx * 101

	# decor first (ground draws over their base)
	var kind: String = map["decor"]
	var dcol: Color = map["decor_c"]
	var dcount: int = rng.randi_range(1, 3)
	for k in range(dcount):
		var dx: float = x0 + rng.randf_range(20.0, CHUNK_W - 20.0)
		add_decor(node, kind, dx, terrain_y(dx), dcol, rng)

	# collision
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var pm := PhysicsMaterial.new()
	pm.friction = 2.0
	pm.bounce = 0.0
	body.physics_material_override = pm
	node.add_child(body)
	var segs := PackedVector2Array()
	for i in range(n):
		segs.append(top[i])
		segs.append(top[i + 1])
	var shape := ConcavePolygonShape2D.new()
	shape.segments = segs
	var cs := CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)

	# visuals: ground + depth shading + grass fringe
	var gcol: Color = map["ground"]
	var grass: Color = map["grass"]
	var pts := PackedVector2Array(top)
	pts.append(Vector2(top[n].x, 1600.0))
	pts.append(Vector2(top[0].x, 1600.0))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = gcol
	node.add_child(poly)
	for off in [30.0, 85.0]:
		var lp := PackedVector2Array()
		for p in top:
			lp.append(p + Vector2(0.0, float(off)))
		var l2 := Line2D.new()
		l2.points = lp
		l2.width = 44.0 if float(off) < 50.0 else 70.0
		l2.default_color = gcol.darkened(0.14) if float(off) < 50.0 else gcol.darkened(0.28)
		node.add_child(l2)
	var line := Line2D.new()
	line.points = top
	line.width = 14.0
	line.default_color = grass
	node.add_child(line)
	var fr := PackedVector2Array()
	var gx: float = x0
	var k2 := 0
	while gx <= x0 + CHUNK_W:
		var gy: float = terrain_y(gx)
		fr.append(Vector2(gx, gy - (9.0 if k2 % 2 == 1 else 3.0)))
		gx += 7.0
		k2 += 1
	var fl := Line2D.new()
	fl.points = fr
	fl.width = 4.0
	fl.default_color = grass.lightened(0.15)
	node.add_child(fl)

	# coins and fuel
	if idx >= 1:
		var count: int = rng.randi_range(0, 2)
		for k in range(count):
			var cx: float = x0 + rng.randf_range(40.0, CHUNK_W - 40.0)
			spawn_item(node, cx, terrain_y(cx) - rng.randf_range(50.0, 100.0), "coin")
		if fuel_chunks.has(idx):
			var fx: float = x0 + CHUNK_W * 0.5
			spawn_item(node, fx, terrain_y(fx) - 70.0, "fuel")

func spawn_item(parent: Node, x: float, y: float, kind: String) -> void:
	var item = ItemScript.new()
	item.kind = kind
	item.position = Vector2(x, y)
	parent.add_child(item)
	item.body_entered.connect(_on_item.bind(item))

func burst(pos: Vector2, col: Color) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 12
	p.lifetime = 0.5
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 220.0
	p.gravity = Vector2(0, 400)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = col
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func _on_item(body: Node, item) -> void:
	if game_over or not is_instance_valid(item) or item.is_queued_for_deletion():
		return
	if not car.is_ancestor_of(body):
		return
	if item.kind == "coin":
		run_coins += 1
		Sfx.play("coin")
		burst(item.global_position, Color("ffd43b"))
	else:
		fuel = minf(fuel_max, fuel + fuel_max * FUEL_GAIN)
		Sfx.play("fuel")
		burst(item.global_position, Color("ff6b6b"))
	item.queue_free()

func update_chunks() -> void:
	var cx: float = car.chassis.position.x
	var first: int = maxi(int(floor((cx - 1500.0) / CHUNK_W)), -2)
	var last: int = int(floor((cx + 2800.0) / CHUNK_W))
	for i in range(first, last + 1):
		if not chunks.has(i):
			build_chunk(i)
	for k in chunks.keys():
		if k < first - 1:
			chunks[k].queue_free()
			chunks.erase(k)

# ---------------- HUD ----------------
func build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)

	low_overlay = ColorRect.new()
	low_overlay.color = Color(1, 0.1, 0.1, 0.0)
	low_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(low_overlay)
	low_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var info := VBoxContainer.new()
	dist_label = UI.label("0 m", 52, Color.WHITE)
	coins_label = UI.label("Coins: 0", 32, UI.GOLD)
	goal_label = UI.label("", 26, Color(0.85, 0.95, 1.0))
	info.add_child(dist_label)
	info.add_child(coins_label)
	info.add_child(goal_label)
	hud.add_child(info)
	info.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)

	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 16)
	var fb := VBoxContainer.new()
	fb.add_child(UI.label("FUEL", 26, Color.WHITE))
	fuel_bar = ProgressBar.new()
	fuel_bar.custom_minimum_size = Vector2(300, 32)
	fuel_bar.max_value = 100.0
	fuel_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("51cf66")
	fill.set_corner_radius_all(10)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.5)
	back.set_corner_radius_all(10)
	fuel_bar.add_theme_stylebox_override("fill", fill)
	fuel_bar.add_theme_stylebox_override("background", back)
	fb.add_child(fuel_bar)
	tr.add_child(fb)
	var pb := UI.button("II", UI.GRAY, 40, Vector2(90, 90))
	pb.pressed.connect(func(): set_paused(true))
	tr.add_child(pb)
	hud.add_child(tr)
	tr.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)

	var brake_btn := UI.pedal("BRAKE", UI.RED, 48, Vector2(280, 170))
	brake_btn.modulate = Color(1, 1, 1, 0.85)
	brake_btn.button_down.connect(func(): brake_pressed = true)
	brake_btn.button_up.connect(func(): brake_pressed = false)
	hud.add_child(brake_btn)
	brake_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 30)
	var gas_btn := UI.pedal("GAS", UI.GREEN, 48, Vector2(280, 170))
	gas_btn.modulate = Color(1, 1, 1, 0.85)
	gas_btn.button_down.connect(func(): gas_pressed = true)
	gas_btn.button_up.connect(func(): gas_pressed = false)
	hud.add_child(gas_btn)
	gas_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 30)

	debug_label = UI.label("", 22, Color(1, 1, 1, 0.8))
	debug_label.visible = Game.debug_on
	hud.add_child(debug_label)
	debug_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 12)

	count_label = UI.label("3", 150, Color.WHITE)
	count_label.visible = false
	hud.add_child(count_label)
	count_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	count_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	count_label.grow_vertical = Control.GROW_DIRECTION_BOTH

	build_pause()
	if tutorial_active:
		build_tutorial()

func build_tutorial() -> void:
	tut_panel = Control.new()
	hud.add_child(tut_panel)
	tut_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	tut_panel.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := UI.panel_box(Color(0.06, 0.08, 0.16, 0.96), 28)
	tut_panel.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	card.add_child(v)
	var t := UI.label("HOW TO PLAY", 56, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var lines := [
		"Hold GAS (right) to drive forward.",
		"BRAKE (left) slows down and reverses.",
		"Collect coins and red fuel cans.",
		"Flips and long jumps give bonus coins.",
		"Do not hit your head on the ground!",
	]
	for ln in lines:
		v.add_child(UI.label(ln, 32, Color.WHITE))
	var got := UI.button("GOT IT", UI.GREEN, 44, Vector2(0, 100))
	got.pressed.connect(func():
		Game.tutorial_done = true
		Game.save_game()
		tutorial_active = false
		tut_panel.queue_free())
	v.add_child(got)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH

func build_pause() -> void:
	pause_panel = Control.new()
	pause_panel.visible = false
	hud.add_child(pause_panel)
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	pause_panel.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var card := UI.panel_box(Color(0.06, 0.08, 0.16, 0.96), 28)
	pause_panel.add_child(card)

	pause_main = VBoxContainer.new()
	pause_main.add_theme_constant_override("separation", 14)
	card.add_child(pause_main)
	var t := UI.label("PAUSED", 60, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_main.add_child(t)
	var resume := UI.button("RESUME", UI.GREEN, 40, Vector2(420, 90))
	resume.pressed.connect(func(): set_paused(false))
	pause_main.add_child(resume)
	var finish := UI.button("FINISH RUN", UI.ORANGE, 40, Vector2(420, 90))
	finish.pressed.connect(func():
		set_paused(false)
		end_game("RUN ENDED", false))
	pause_main.add_child(finish)
	var restart := UI.button("RESTART", UI.BLUE, 40, Vector2(420, 90))
	restart.pressed.connect(func(): leave("game"))
	pause_main.add_child(restart)
	var tune_btn := UI.button("TUNING", UI.ORANGE, 40, Vector2(420, 90))
	tune_btn.pressed.connect(func():
		pause_main.visible = false
		pause_tune.visible = true)
	pause_main.add_child(tune_btn)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var maps_btn := UI.button("MAPS", UI.GRAY, 36, Vector2(203, 90))
	maps_btn.pressed.connect(func(): leave("maps"))
	row.add_child(maps_btn)
	var menu_btn := UI.button("MENU", UI.GRAY, 36, Vector2(203, 90))
	menu_btn.pressed.connect(func(): leave("menu"))
	row.add_child(menu_btn)
	pause_main.add_child(row)

	pause_tune = VBoxContainer.new()
	pause_tune.add_theme_constant_override("separation", 12)
	pause_tune.visible = false
	card.add_child(pause_tune)
	var tt := UI.label("TUNING", 50, UI.GOLD)
	tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_tune.add_child(tt)
	tune_box = VBoxContainer.new()
	tune_box.add_theme_constant_override("separation", 10)
	pause_tune.add_child(tune_box)
	fill_tune()
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 14)
	var reset := UI.button("RESET", UI.RED, 34, Vector2(200, 80))
	reset.pressed.connect(func():
		for k in Game.tune.keys():
			Game.tune[k] = 1.0
		car.apply_tuning()
		for c in tune_box.get_children():
			c.queue_free()
		fill_tune())
	trow.add_child(reset)
	var done := UI.button("BACK", UI.GREEN, 34, Vector2(200, 80))
	done.pressed.connect(func():
		Game.save_game()
		pause_tune.visible = false
		pause_main.visible = true)
	trow.add_child(done)
	pause_tune.add_child(trow)

	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH

func fill_tune() -> void:
	tune_row("power", "Power")
	tune_row("grip", "Grip")
	tune_row("susp", "Suspension")
	tune_row("grav", "Gravity")

func tune_row(key: String, title: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var l := UI.label(title, 30, Color.WHITE)
	l.custom_minimum_size = Vector2(200, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.5
	s.max_value = 1.8
	s.step = 0.05
	s.value = float(Game.tune[key])
	s.custom_minimum_size = Vector2(380, 50)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(s)
	var vl := UI.label("%.2f" % s.value, 30, UI.GOLD)
	vl.custom_minimum_size = Vector2(80, 0)
	h.add_child(vl)
	s.value_changed.connect(func(v: float):
		Game.tune[key] = v
		vl.text = "%.2f" % v
		car.apply_tuning())
	tune_box.add_child(h)

func set_paused(p: bool) -> void:
	if game_over or tutorial_active:
		return
	paused = p
	get_tree().paused = p
	pause_panel.visible = p
	if p:
		Sfx.stop_engine()
	else:
		gas_pressed = false
		brake_pressed = false
		pause_tune.visible = false
		pause_main.visible = true
		Sfx.start_engine()

func leave(scr: String) -> void:
	bank_run()
	Engine.time_scale = 1.0
	get_tree().paused = false
	Sfx.stop_engine()
	main.go(scr)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		on_back()

func next_goal() -> String:
	for k in range(3):
		if max_dist < float(targets[k]):
			return "Goal %d/3: %d m" % [k + 1, int(targets[k])]
	return "All goals reached!"

# ---------------- popups / countdown ----------------
func pop(l: Label) -> void:
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(1.6, 1.6)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

func popup(text: String, col: Color) -> void:
	var l := UI.label(text, 44, col)
	hud.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 150)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", -60.0, 1.2).as_relative()
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)

func hide_count() -> void:
	if is_instance_valid(count_label):
		count_label.visible = false

func run_countdown(delta: float) -> void:
	countdown -= delta
	if countdown > 0.0:
		var n: int = int(ceil(countdown))
		if n != last_count:
			last_count = n
			count_label.text = str(n)
			count_label.visible = true
			Sfx.play("tick")
			pop(count_label)
	else:
		started = true
		count_label.text = "GO!"
		count_label.visible = true
		Sfx.play("go")
		pop(count_label)
		get_tree().create_timer(0.7).timeout.connect(hide_count)

# ---------------- flips / air time ----------------
func _physics_process(delta: float) -> void:
	if car == null or game_over:
		return
	if started:
		# মাথা মাটি ছুঁলে (গাড়ি উল্টালে) রান শেষ
		var hp: Vector2 = car.chassis.to_global(car.head_local)
		if hp.y + 8.0 >= terrain_y(hp.x):
			end_game("CRASHED!", true)
			return
		if cos(car.chassis.rotation) < 0.0 and car.on_ground:
			flipped_t += delta
			if flipped_t > 1.5:
				end_game("FLIPPED!", true)
				return
		else:
			flipped_t = 0.0
	var rot: float = car.chassis.rotation
	var air: bool = not car.on_ground
	if air:
		air_time += delta
		air_rot += angle_difference(prev_rot, rot)
	else:
		if was_air:
			on_land()
		air_time = 0.0
		air_rot = 0.0
	prev_rot = rot
	was_air = air

func on_land() -> void:
	air_best = maxf(air_best, air_time)
	if air_time < 0.4:
		return
	Sfx.play("land")
	shake = maxf(shake, 5.0)
	var n: int = int(absf(air_rot) / (TAU * 0.8))
	if n > 0:
		flips += n
		var pts: int = FLIP_BONUS * n
		bonus_pts += pts
		var nm: String = "FRONT FLIP" if air_rot > 0.0 else "BACK FLIP"
		if n > 1:
			nm = "%s x%d" % [nm, n]
		popup("%s +%d" % [nm, pts], UI.GOLD)
		Sfx.play("flip")
	elif air_time >= 1.0:
		var pts2: int = int(air_time * AIR_BONUS)
		bonus_pts += pts2
		popup("AIR TIME %.1fs +%d" % [air_time, pts2], Color("74c0fc"))

# ---------------- game loop ----------------
func _process(delta: float) -> void:
	time_t += delta
	update_chunks()
	if not started and not tutorial_active:
		run_countdown(delta)

	var cpos: Vector2 = car.chassis.position
	var vel: Vector2 = car.chassis.linear_velocity
	var spd: float = vel.length()
	var z: float = lerpf(0.9, 0.62, clampf(spd / 1500.0, 0.0, 1.0))
	cam.zoom = cam.zoom.lerp(Vector2(z, z), clampf(delta * 2.0, 0.0, 1.0))
	cam.position = cpos + Vector2(260.0 + clampf(vel.x * 0.15, -100.0, 200.0), -100.0)
	if shake > 0.1:
		cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
		shake = lerpf(shake, 0.0, clampf(delta * 8.0, 0.0, 1.0))
	else:
		cam.offset = Vector2.ZERO
	bg.cam_x = cam.get_screen_center_position().x

	var kb_gas: bool = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	var kb_brake: bool = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	var want_gas: bool = (gas_pressed or kb_gas) and started and not game_over

	if started and not game_over:
		var rate: float = FUEL_DRAIN * float(map["fuel"]) * (1.0 if want_gas else 0.5)
		fuel -= rate * delta
		if fuel <= 0.0:
			fuel = 0.0
			zero_time += delta
			if zero_time > 3.0:
				end_game("OUT OF FUEL", false)
		else:
			zero_time = 0.0
		if cpos.y > 2500.0:
			end_game("FELL OFF", true)

	# low fuel warning
	var low: bool = started and not game_over and fuel > 0.0 and fuel / fuel_max < 0.2
	if low:
		if not was_low:
			popup("LOW FUEL!", UI.RED)
		low_timer += delta
		if low_timer >= 1.0:
			low_timer = 0.0
			Sfx.play("low")
		low_overlay.color = Color(1, 0.1, 0.1, 0.07 + 0.10 * (0.5 + 0.5 * sin(time_t * 8.0)))
	else:
		low_timer = 0.9
		low_overlay.color = Color(1, 0.1, 0.1, 0.0)
	was_low = low

	car.gas = want_gas and fuel > 0.0
	car.brake = (brake_pressed or kb_brake) and started and not game_over
	Sfx.set_engine(clampf(spd / 1400.0, 0.0, 1.0), car.gas)

	var d: float = maxf(0.0, (cpos.x - START_X) / 50.0)
	max_dist = maxf(max_dist, d)
	dist_label.text = "%d m" % int(max_dist)
	coins_label.text = "Coins: %d" % run_coins
	goal_label.text = next_goal()
	fuel_bar.value = fuel / fuel_max * 100.0
	fuel_bar.modulate = Color(1, 0.4, 0.4) if fuel / fuel_max < 0.25 else Color.WHITE
	if debug_label.visible:
		debug_label.text = "FPS %d   SPEED %d m/s   AIR %.1f   CHUNKS %d" % [Engine.get_frames_per_second(), int(spd / 50.0), air_time, chunks.size()]

func restore_time() -> void:
	Engine.time_scale = 1.0

func end_game(reason: String, crash: bool) -> void:
	if game_over:
		return
	game_over = true
	car.gas = false
	car.brake = false
	Sfx.stop_engine()
	low_overlay.color = Color(1, 0.1, 0.1, 0.0)
	if crash:
		Sfx.play("crash")
		shake = 22.0
		Engine.time_scale = 0.3
		get_tree().create_timer(0.6, true, false, true).timeout.connect(restore_time)
	air_best = maxf(air_best, air_time)
	var res: Dictionary = Game.submit_run(map_idx, max_dist, run_coins, flips, air_best, bonus_pts)
	get_tree().create_timer(1.2, true, false, true).timeout.connect(show_result.bind(reason, res))

func show_result(reason: String, res: Dictionary) -> void:
	Engine.time_scale = 1.0
	var p := UI.panel_box(Color(0.06, 0.08, 0.16, 0.96), 28)
	p.custom_minimum_size = Vector2(640, 0)
	hud.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var t := UI.label(reason, 56, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var dl := UI.label("Distance: %d m" % int(max_dist), 40, Color.WHITE)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dl)
	if res["newbest"]:
		var nb := UI.label("NEW BEST!", 34, UI.GREEN)
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nb)

	var sr := HBoxContainer.new()
	sr.alignment = BoxContainer.ALIGNMENT_CENTER
	sr.add_theme_constant_override("separation", 12)
	v.add_child(sr)
	var got: int = res["stars"]
	var tw: Tween = null
	if got > 0:
		tw = create_tween()
	for k in range(3):
		var star := UI.star_icon(34.0, k < got)
		sr.add_child(star)
		if k < got:
			star.scale = Vector2.ZERO
			tw.tween_property(star, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
			tw.tween_callback(Sfx.play.bind("star"))

	var lines: Array = []
	lines.append(["Coins collected: %d  (+%d)" % [run_coins, int(res["pickup_coins"])], Color.WHITE])
	lines.append(["Distance bonus: +%d" % int(res["dist_coins"]), Color.WHITE])
	if int(res["bonus_pts"]) > 0:
		lines.append(["Stunts (%d flips): +%d" % [int(res["flips"]), int(res["bonus_pts"])], Color("74c0fc")])
	if int(res["bonus"]) > 0:
		lines.append(["Star bonus: +%d" % int(res["bonus"]), UI.GOLD])
	for ln in lines:
		var l := UI.label(ln[0], 28, ln[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var names: Array = res["ach"]
	for nm in names:
		var al := UI.label("Achievement: %s" % nm, 28, UI.GREEN)
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(al)
	if names.size() > 0:
		Sfx.play("ach")
	var tl := UI.label("+0 coins", 44, UI.GOLD)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	var total: float = float(res["total"])
	var tw2 := create_tween()
	tw2.tween_method(func(val: float): tl.text = "+" + UI.money(int(val)) + " coins", 0.0, total, 1.0)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	var retry := UI.button("RETRY", UI.GREEN, 36, Vector2(190, 90))
	retry.pressed.connect(func(): leave("game"))
	row.add_child(retry)
	var maps_btn := UI.button("MAPS", UI.BLUE, 36, Vector2(190, 90))
	maps_btn.pressed.connect(func(): leave("maps"))
	row.add_child(maps_btn)
	var menu_btn := UI.button("MENU", UI.GRAY, 36, Vector2(190, 90))
	menu_btn.pressed.connect(func(): leave("menu"))
	row.add_child(menu_btn)
	v.add_child(row)

	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH

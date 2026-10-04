extends Node2D

const CarScript = preload("res://car.gd")
const ItemScript = preload("res://collectible.gd")

const CHUNK_W := 400.0
const STEP := 20.0
const START_X := 200.0
const FUEL_DRAIN := 1.6   # প্রতি সেকেন্ডে ফুয়েল কমার হার

var car
var cam: Camera2D
var terrain_root: Node2D
var chunks := {}

var fuel := 100.0
var coins := 0
var best := 0
var max_dist := 0.0
var zero_time := 0.0
var game_over := false
var gas_pressed := false
var brake_pressed := false

var dist_label: Label
var coins_label: Label
var best_label: Label
var fuel_bar: ProgressBar
var over_panel: PanelContainer
var over_label: Label

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("8fd3f4"))
	load_best()
	terrain_root = Node2D.new()
	add_child(terrain_root)
	add_wall()
	car = CarScript.new()
	car.start_pos = Vector2(START_X, terrain_y(START_X) - 77.0)
	add_child(car)
	car.crashed.connect(func(): end_game("CRASHED!"))
	cam = Camera2D.new()
	cam.zoom = Vector2(0.85, 0.85)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	add_child(cam)
	cam.position = car.chassis.position + Vector2(280, -100)
	build_ui()
	update_chunks()

# ---------------- Terrain ----------------
func terrain_y(x: float) -> float:
	var t: float = clampf((x - 300.0) / 1500.0, 0.0, 1.0)
	var amp: float = 35.0 + minf(maxf(x, 0.0) * 0.025, 85.0)
	var y: float = 500.0
	y += sin(x * 0.0025) * amp * t
	y += sin(x * 0.007 + 1.3) * amp * 0.35 * t
	y += sin(x * 0.021 + 0.5) * 6.0 * t
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

	# collision: segments
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var pm := PhysicsMaterial.new()
	pm.friction = 1.2
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

	# visuals
	var pts := PackedVector2Array(top)
	pts.append(Vector2(top[n].x, 1600.0))
	pts.append(Vector2(top[0].x, 1600.0))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = Color("6b4a2b")
	node.add_child(poly)
	var line := Line2D.new()
	line.points = top
	line.width = 14.0
	line.default_color = Color("4caf50")
	node.add_child(line)

	# coins / fuel
	if idx >= 1:
		var rng := RandomNumberGenerator.new()
		rng.seed = idx * 7919 + 13
		var count: int = rng.randi_range(1, 3)
		for k in range(count):
			var cx: float = x0 + rng.randf_range(40.0, CHUNK_W - 40.0)
			spawn_item(node, cx, terrain_y(cx) - rng.randf_range(50.0, 100.0), "coin")
		if rng.randf() < 0.3:
			var fx: float = x0 + rng.randf_range(40.0, CHUNK_W - 40.0)
			spawn_item(node, fx, terrain_y(fx) - 70.0, "fuel")

func spawn_item(parent: Node, x: float, y: float, kind: String) -> void:
	var item = ItemScript.new()
	item.kind = kind
	item.position = Vector2(x, y)
	parent.add_child(item)
	item.body_entered.connect(_on_item.bind(item))

func _on_item(body: Node, item) -> void:
	if game_over or not is_instance_valid(item) or item.is_queued_for_deletion():
		return
	if not car.is_ancestor_of(body):
		return
	if item.kind == "coin":
		coins += 1
	else:
		fuel = minf(100.0, fuel + 35.0)
	item.queue_free()

func update_chunks() -> void:
	var cx: float = car.chassis.position.x
	var first: int = maxi(int(floor((cx - 1500.0) / CHUNK_W)), -2)
	var last: int = int(floor((cx + 2500.0) / CHUNK_W))
	for i in range(first, last + 1):
		if not chunks.has(i):
			build_chunk(i)
	for k in chunks.keys():
		if k < first - 1:
			chunks[k].queue_free()
			chunks.erase(k)

# ---------------- UI ----------------
func make_label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	return l

func make_button(text: String, preset: Control.LayoutPreset, parent: Node) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 150)
	b.add_theme_font_size_override("font_size", 44)
	b.focus_mode = Control.FOCUS_NONE
	b.modulate = Color(1, 1, 1, 0.8)
	parent.add_child(b)
	b.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 30)
	return b

func build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	var info := VBoxContainer.new()
	dist_label = make_label(40)
	coins_label = make_label(32)
	best_label = make_label(28)
	info.add_child(dist_label)
	info.add_child(coins_label)
	info.add_child(best_label)
	ui.add_child(info)
	info.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)

	var fuel_box := VBoxContainer.new()
	var fl := make_label(28)
	fl.text = "FUEL"
	fuel_bar = ProgressBar.new()
	fuel_bar.custom_minimum_size = Vector2(320, 34)
	fuel_bar.max_value = 100.0
	fuel_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("51cf66")
	fuel_bar.add_theme_stylebox_override("fill", fill)
	fuel_box.add_child(fl)
	fuel_box.add_child(fuel_bar)
	ui.add_child(fuel_box)
	fuel_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)

	var gas_btn := make_button("GAS", Control.PRESET_BOTTOM_RIGHT, ui)
	gas_btn.button_down.connect(func(): gas_pressed = true)
	gas_btn.button_up.connect(func(): gas_pressed = false)
	var brake_btn := make_button("BRAKE", Control.PRESET_BOTTOM_LEFT, ui)
	brake_btn.button_down.connect(func(): brake_pressed = true)
	brake_btn.button_up.connect(func(): brake_pressed = false)

	over_panel = PanelContainer.new()
	over_panel.visible = false
	ui.add_child(over_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 20)
	over_panel.add_child(vb)
	over_label = Label.new()
	over_label.add_theme_font_size_override("font_size", 40)
	over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(over_label)
	var rb := Button.new()
	rb.text = "RESTART"
	rb.custom_minimum_size = Vector2(300, 110)
	rb.add_theme_font_size_override("font_size", 44)
	rb.pressed.connect(func(): get_tree().reload_current_scene())
	vb.add_child(rb)
	over_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	over_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	over_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

# ---------------- Game loop ----------------
func _process(delta: float) -> void:
	update_chunks()
	cam.position = car.chassis.position + Vector2(280, -100)

	var kb_gas: bool = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	var kb_brake: bool = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)

	if not game_over:
		fuel -= FUEL_DRAIN * delta
		if fuel <= 0.0:
			fuel = 0.0
			zero_time += delta
			if zero_time > 3.0:
				end_game("OUT OF FUEL")
		else:
			zero_time = 0.0
		if car.chassis.position.y > 2500.0:
			end_game("FELL OFF")

	car.gas = (gas_pressed or kb_gas) and fuel > 0.0 and not game_over
	car.brake = (brake_pressed or kb_brake) and not game_over

	var d: float = maxf(0.0, (car.chassis.position.x - START_X) / 50.0)
	max_dist = maxf(max_dist, d)

	dist_label.text = "%d m" % int(max_dist)
	coins_label.text = "Coins: %d" % coins
	best_label.text = "Best: %d m" % best
	fuel_bar.value = fuel
	fuel_bar.modulate = Color(1, 0.4, 0.4) if fuel < 25.0 else Color.WHITE

func end_game(reason: String) -> void:
	if game_over:
		return
	game_over = true
	var d: int = int(max_dist)
	if d > best:
		best = d
		save_best()
	over_label.text = "%s\nDistance: %d m   Coins: %d\nBest: %d m" % [reason, d, coins, best]
	over_panel.visible = true

func load_best() -> void:
	if FileAccess.file_exists("user://best.dat"):
		var f := FileAccess.open("user://best.dat", FileAccess.READ)
		if f:
			best = f.get_32()

func save_best() -> void:
	var f := FileAccess.open("user://best.dat", FileAccess.WRITE)
	if f:
		f.store_32(best)

extends Node2D
# ফিজিক্স গাড়ি: Game.cars[idx] এর তথ্য থেকে তৈরি হয়।

signal crashed

const CarBody = preload("res://car_body.gd")
const WheelVis = preload("res://wheel_vis.gd")
const UI = preload("res://ui.gd")
const BRAKE_K := 3000.0
const MAX_REVERSE := 12.0

var idx := 0
var map: Dictionary = {}
var start_pos := Vector2(200, 400)
var gas := false
var brake := false
var stats: Dictionary = {}
var chassis: RigidBody2D
var wheels: Array[RigidBody2D] = []
var springs: Array[DampedSpringJoint2D] = []
var wmats: Array[PhysicsMaterial] = []
var dust: Array = []
var exhaust: CPUParticles2D
var wr := 30.0
var air_torque := 40000.0

func make_particles(col: Color, amount: int, life: float, vmin: float, vmax: float, smin: float, smax: float, dir: Vector2, spread: float, grav: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.emitting = false
	p.local_coords = false
	p.direction = dir
	p.spread = spread
	p.gravity = grav
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, 0.7))
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	p.color_ramp = g
	return p

func _ready() -> void:
	var cdata: Dictionary = Game.cars[idx]
	stats = Game.effective(idx)
	wr = cdata["wr"]
	var cw: float = cdata["cw"]
	var ch: float = cdata["ch"]
	var wx: float = cdata["wx"]
	var wy: float = cdata["wy"]
	var mass: float = cdata["mass"]
	var grav: float = float(map.get("grav", 1.0)) * float(Game.tune["grav"])
	var fric: float = float(map.get("fric", 1.0))
	air_torque = 10000.0 * mass

	# ---- chassis ----
	chassis = RigidBody2D.new()
	chassis.mass = mass
	chassis.collision_layer = 2
	chassis.collision_mask = 1 | 8
	chassis.can_sleep = false
	chassis.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	chassis.angular_damp = 1.0
	chassis.linear_damp = float(map.get("drag", 0.0))
	chassis.gravity_scale = grav
	chassis.center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	chassis.center_of_mass = Vector2(0, ch * 0.4)
	chassis.position = start_pos
	var cpm := PhysicsMaterial.new()
	cpm.friction = 0.4
	cpm.bounce = 0.0
	chassis.physics_material_override = cpm
	add_child(chassis)

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(cw, ch)
	cs.shape = rect
	chassis.add_child(cs)

	var body := CarBody.new()
	body.setup(cdata)
	chassis.add_child(body)

	# ---- head sensor ----
	var head := Area2D.new()
	head.collision_layer = 0
	head.collision_mask = 1
	head.position = Vector2(body.hx, body.top - 7.0)
	var hs := CollisionShape2D.new()
	var hc := CircleShape2D.new()
	hc.radius = 10.0
	hs.shape = hc
	head.add_child(hs)
	chassis.add_child(head)
	head.body_entered.connect(func(_b): crashed.emit())

	# ---- headlights ----
	if map.get("lights", false):
		var beam := Polygon2D.new()
		beam.polygon = PackedVector2Array([Vector2(cw * 0.5, -ch * 0.2), Vector2(cw * 0.5 + 420.0, -ch * 1.6), Vector2(cw * 0.5 + 420.0, ch * 1.4)])
		beam.color = Color(1.0, 0.95, 0.6, 0.2)
		chassis.add_child(beam)

	# ---- exhaust ----
	exhaust = make_particles(Color(0.7, 0.7, 0.7), 18, 0.6, 30.0, 80.0, 3.0, 7.0, Vector2(-1, -0.3), 25.0, Vector2(0, -40))
	exhaust.position = Vector2(-cw * 0.5 - 6.0, ch * 0.3)
	chassis.add_child(exhaust)

	# ---- wheels + suspension ----
	var dust_col: Color = map.get("dust", Color(0.7, 0.6, 0.4))
	var knob: bool = String(cdata["style"]) in ["monster", "tractor", "army"]
	var joint_y: float = ch * 0.35
	var d: float = wy - joint_y
	for sx in [-1.0, 1.0]:
		var x: float = float(sx) * wx
		var w := RigidBody2D.new()
		w.mass = 1.5 * wr / 30.0
		w.collision_layer = 4
		w.collision_mask = 1 | 8
		w.can_sleep = false
		w.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
		w.contact_monitor = true
		w.max_contacts_reported = 4
		w.gravity_scale = grav
		w.position = start_pos + Vector2(x, wy)
		var wpm := PhysicsMaterial.new()
		wpm.friction = float(stats["grip"]) * fric
		wpm.bounce = 0.0
		w.physics_material_override = wpm
		add_child(w)
		wmats.append(wpm)

		var wcs := CollisionShape2D.new()
		var wc := CircleShape2D.new()
		wc.radius = wr
		wcs.shape = wc
		w.add_child(wcs)
		var wv := WheelVis.new()
		wv.r = wr
		wv.rim = UI.rim_of(cdata)
		wv.knobby = knob
		w.add_child(wv)
		wheels.append(w)

		var groove := GrooveJoint2D.new()
		groove.position = start_pos + Vector2(x, joint_y)
		groove.length = d + 28.0
		groove.initial_offset = d
		add_child(groove)
		groove.node_a = groove.get_path_to(chassis)
		groove.node_b = groove.get_path_to(w)

		var spring := DampedSpringJoint2D.new()
		spring.position = start_pos + Vector2(x, joint_y)
		spring.length = d
		spring.rest_length = d + 8.0
		spring.stiffness = stats["stiff"]
		spring.damping = stats["damp"]
		add_child(spring)
		spring.node_a = spring.get_path_to(chassis)
		spring.node_b = spring.get_path_to(w)
		springs.append(spring)

		var dp := make_particles(dust_col, 16, 0.7, 40.0, 130.0, 3.0, 8.0, Vector2(-1, -0.6), 35.0, Vector2(0, 60))
		add_child(dp)
		dust.append(dp)

# স্লাইডার বদলালে লাইভ প্রয়োগ হয়
func apply_tuning() -> void:
	stats = Game.effective(idx)
	var fric: float = float(map.get("fric", 1.0))
	var grav: float = float(map.get("grav", 1.0)) * float(Game.tune["grav"])
	for m in wmats:
		m.friction = float(stats["grip"]) * fric
	for s in springs:
		s.stiffness = stats["stiff"]
		s.damping = stats["damp"]
	chassis.gravity_scale = grav
	for w in wheels:
		w.gravity_scale = grav

func _process(_d: float) -> void:
	var spd: float = chassis.linear_velocity.length()
	for i in range(wheels.size()):
		var p: CPUParticles2D = dust[i]
		p.global_position = wheels[i].global_position + Vector2(0, wr * 0.8)
		p.emitting = wheels[i].get_contact_count() > 0 and spd > 150.0
	exhaust.emitting = gas

func _physics_process(_delta: float) -> void:
	var on_ground := false
	for w in wheels:
		if w.get_contact_count() > 0:
			on_ground = true
	var power: float = stats["power"]
	var vmax: float = stats["vmax"]
	if gas:
		for w in wheels:
			if w.angular_velocity < vmax:
				w.apply_torque(power)
		if not on_ground:
			chassis.apply_torque(-air_torque)
	elif brake:
		for w in wheels:
			if w.angular_velocity > 1.0:
				w.apply_torque(-w.angular_velocity * BRAKE_K)
			elif w.angular_velocity > -MAX_REVERSE:
				w.apply_torque(-power * 0.6)
		if not on_ground:
			chassis.apply_torque(air_torque)

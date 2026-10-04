extends Node2D

signal crashed

# ---- Tuning (ফিজিক্স টিউনিং এখানেই করবেন) ----
const MOTOR_TORQUE := 60000.0
const MAX_WHEEL_SPEED := 40.0
const MAX_REVERSE := 12.0
const BRAKE_K := 3000.0
const AIR_TORQUE := 40000.0
const SPRING_STIFFNESS := 180.0
const SPRING_DAMPING := 10.0
const WHEEL_RADIUS := 30.0

var start_pos := Vector2(200, 420)
var gas := false
var brake := false

var chassis: RigidBody2D
var wheels: Array[RigidBody2D] = []

func add_poly(parent: Node, pts: PackedVector2Array, col: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	parent.add_child(p)

func circle_pts(r: float, n: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

func _ready() -> void:
	# ---- Chassis ----
	chassis = RigidBody2D.new()
	chassis.mass = 4.0
	chassis.collision_layer = 2
	chassis.collision_mask = 1 | 8
	chassis.can_sleep = false
	chassis.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	chassis.angular_damp = 1.0
	chassis.center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	chassis.center_of_mass = Vector2(0, 14)
	chassis.position = start_pos
	var cpm := PhysicsMaterial.new()
	cpm.friction = 0.4
	cpm.bounce = 0.0
	chassis.physics_material_override = cpm
	add_child(chassis)

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(130, 34)
	cs.shape = rect
	chassis.add_child(cs)

	add_poly(chassis, PackedVector2Array([Vector2(-65, -17), Vector2(65, -17), Vector2(65, 17), Vector2(-65, 17)]), Color("e8590c"))
	add_poly(chassis, PackedVector2Array([Vector2(-30, -17), Vector2(-20, -42), Vector2(25, -42), Vector2(40, -17)]), Color("9ad1f5"))
	var head_vis := Polygon2D.new()
	head_vis.polygon = circle_pts(11.0, 16)
	head_vis.color = Color("ffd8a8")
	head_vis.position = Vector2(-2, -50)
	chassis.add_child(head_vis)

	# ---- Head sensor (মাথা মাটিতে লাগলে ক্র্যাশ) ----
	var head := Area2D.new()
	head.collision_layer = 0
	head.collision_mask = 1
	head.position = Vector2(-2, -50)
	var hs := CollisionShape2D.new()
	var hc := CircleShape2D.new()
	hc.radius = 11.0
	hs.shape = hc
	head.add_child(hs)
	chassis.add_child(head)
	head.body_entered.connect(func(_b): crashed.emit())

	# ---- Wheels + suspension ----
	for sx in [-48.0, 48.0]:
		var x: float = sx
		var w := RigidBody2D.new()
		w.mass = 1.5
		w.collision_layer = 4
		w.collision_mask = 1 | 8
		w.can_sleep = false
		w.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
		w.contact_monitor = true
		w.max_contacts_reported = 4
		w.position = start_pos + Vector2(x, 42)
		var wpm := PhysicsMaterial.new()
		wpm.friction = 1.4
		wpm.bounce = 0.0
		w.physics_material_override = wpm
		add_child(w)

		var wcs := CollisionShape2D.new()
		var wc := CircleShape2D.new()
		wc.radius = WHEEL_RADIUS
		wcs.shape = wc
		w.add_child(wcs)
		add_poly(w, circle_pts(WHEEL_RADIUS), Color("222222"))
		add_poly(w, circle_pts(14.0, 16), Color("bbbbbb"))
		add_poly(w, PackedVector2Array([Vector2(-4, -24), Vector2(4, -24), Vector2(4, 24), Vector2(-4, 24)]), Color("777777"))
		wheels.append(w)

		var groove := GrooveJoint2D.new()
		groove.position = start_pos + Vector2(x, 12)
		groove.length = 55.0
		groove.initial_offset = 30.0
		add_child(groove)
		groove.node_a = groove.get_path_to(chassis)
		groove.node_b = groove.get_path_to(w)

		var spring := DampedSpringJoint2D.new()
		spring.position = start_pos + Vector2(x, 12)
		spring.length = 30.0
		spring.rest_length = 38.0
		spring.stiffness = SPRING_STIFFNESS
		spring.damping = SPRING_DAMPING
		add_child(spring)
		spring.node_a = spring.get_path_to(chassis)
		spring.node_b = spring.get_path_to(w)

func _physics_process(_delta: float) -> void:
	var on_ground := false
	for w in wheels:
		if w.get_contact_count() > 0:
			on_ground = true

	if gas:
		for w in wheels:
			if w.angular_velocity < MAX_WHEEL_SPEED:
				w.apply_torque(MOTOR_TORQUE)
		if not on_ground:
			chassis.apply_torque(-AIR_TORQUE)  # গ্যাস = নাক উপরে
	elif brake:
		for w in wheels:
			if w.angular_velocity > 1.0:
				w.apply_torque(-w.angular_velocity * BRAKE_K)
			elif w.angular_velocity > -MAX_REVERSE:
				w.apply_torque(-MOTOR_TORQUE * 0.6)  # থেমে গেলে পিছনে যাবে
		if not on_ground:
			chassis.apply_torque(AIR_TORQUE)  # ব্রেক = নাক নিচে

extends Node
# স্ক্রিন ম্যানেজার: splash -> menu -> maps / garage / settings -> game

var screens := {}
var current: Node
var busy := false
var fade: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	screens = {
		"menu": preload("res://menu.gd"),
		"maps": preload("res://maps_screen.gd"),
		"garage": preload("res://garage.gd"),
		"settings": preload("res://settings.gd"),
		"ach": preload("res://achievements.gd"),
		"missions": preload("res://missions.gd"),
		"mode": preload("res://mode_select.gd"),
		"game": preload("res://gameplay.gd"),
	}
	var fl := CanvasLayer.new()
	fl.layer = 100
	add_child(fl)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	show_splash()

func show_splash() -> void:
	var sp := Control.new()
	add_child(sp)
	sp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current = sp
	var bgc := ColorRect.new()
	bgc.color = Color("0b1230")
	sp.add_child(bgc)
	bgc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	sp.add_child(vb)
	var UI = preload("res://ui.gd")
	var t = UI.label("HILL RACE", 110, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var s = UI.label("Climb. Collect. Conquer.", 36, Color.WHITE)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(s)
	vb.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(vb, "modulate:a", 1.0, 0.6)
	await get_tree().create_timer(1.8).timeout
	go("menu")

func go(scr: String) -> void:
	if busy:
		return
	busy = true
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.18)
	await t.finished
	get_tree().paused = false
	if current != null:
		current.queue_free()
		current = null
	var s = screens[scr].new()
	s.main = self
	current = s
	add_child(s)
	var t2 := create_tween()
	t2.tween_property(fade, "color:a", 0.0, 0.18)
	await t2.finished
	busy = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if current != null and current.has_method("on_back"):
			current.on_back()

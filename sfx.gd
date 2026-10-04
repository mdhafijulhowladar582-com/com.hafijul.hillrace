extends Node
# Autoload "Sfx": সব সাউন্ড কোডে তৈরি হয় (কোনো অডিও ফাইল লাগে না)।

const RATE := 22050

var streams := {}
var pool: Array = []
var engine: AudioStreamPlayer
var music: AudioStreamPlayer
var engine_running := false

# Kenney (CC0) ফাইল -> সাউন্ডের নাম. ফাইল না থাকলে তৈরি-করা সাউন্ড ব্যবহার হবে।
const FILES := {
	"click": "click_003", "unlock": "confirmation_001", "go": "confirmation_002", "ach": "confirmation_004",
	"error": "error_001", "tick": "tick_001", "coin": "pepSound3", "fuel": "powerUp3", "star": "powerUp1",
	"daily": "powerUp5", "flip": "powerUp7", "low": "twoTone1",
	"crash": "impactMetal_heavy_000", "crash2": "impactGlass_heavy_000", "land": "impactSoft_heavy_000"
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	streams["click"] = tone([[700.0, 0.04], [950.0, 0.05]], 0.35)
	streams["coin"] = tone([[1000.0, 0.05], [1400.0, 0.12]], 0.35)
	streams["fuel"] = tone([[440.0, 0.07], [554.0, 0.07], [659.0, 0.14]], 0.4)
	streams["unlock"] = tone([[523.0, 0.09], [659.0, 0.09], [784.0, 0.09], [1047.0, 0.3]], 0.4)
	streams["star"] = tone([[880.0, 0.1], [1175.0, 0.1], [1568.0, 0.25]], 0.4)
	streams["error"] = tone([[220.0, 0.12], [180.0, 0.18]], 0.4)
	streams["crash"] = noise(0.55, 0.7)
	streams["tick"] = tone([[800.0, 0.06]], 0.35)
	streams["go"] = tone([[600.0, 0.08], [900.0, 0.2]], 0.4)
	streams["low"] = tone([[500.0, 0.08], [500.0, 0.08]], 0.4)
	streams["flip"] = tone([[700.0, 0.06], [1100.0, 0.12]], 0.4)
	streams["land"] = noise(0.15, 0.4)
	streams["ach"] = streams["unlock"]
	streams["daily"] = streams["star"]
	for k in FILES.keys():
		var path: String = "res://%s.ogg" % FILES[k]
		if ResourceLoader.exists(path):
			var st = load(path)
			if st != null:
				streams[k] = st
	for i in range(8):
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	engine = AudioStreamPlayer.new()
	engine.stream = make_engine()
	engine.volume_db = -14.0
	add_child(engine)
	music = AudioStreamPlayer.new()
	music.volume_db = -13.0
	add_child(music)
	call_deferred("start_music")

func play(n: String) -> void:
	if not Game.sound_on:
		return
	if not streams.has(n):
		return
	if n == "crash" and streams.has("crash2"):
		play_one("crash2")
	play_one(n)

func play_one(n: String) -> void:
	if not streams.has(n):
		return
	for p in pool:
		if not p.playing:
			p.stream = streams[n]
			p.play()
			return

func tone(notes: Array, vol: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	for n in notes:
		var f: float = n[0]
		var dur: float = n[1]
		var count: int = int(RATE * dur)
		for i in range(count):
			var t: float = float(i) / float(RATE)
			var env: float = 1.0 - float(i) / float(count)
			var v: float = (sin(TAU * f * t) * 0.7 + sin(TAU * f * 2.0 * t) * 0.2) * env * vol
			var s: int = clampi(int(v * 32767.0), -32767, 32767)
			data.append(s & 0xFF)
			data.append((s >> 8) & 0xFF)
	return wav(data, RATE, false)

func noise(dur: float, vol: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var count: int = int(RATE * dur)
	var lp := 0.0
	for i in range(count):
		var env: float = pow(1.0 - float(i) / float(count), 2.0)
		lp = lp * 0.7 + (randf() * 2.0 - 1.0) * 0.3
		var s: int = clampi(int(lp * env * vol * 32767.0 * 2.0), -32767, 32767)
		data.append(s & 0xFF)
		data.append((s >> 8) & 0xFF)
	return wav(data, RATE, false)

func make_engine() -> AudioStreamWAV:
	var data := PackedByteArray()
	for i in range(RATE):
		var t: float = float(i) / float(RATE)
		var v: float = sin(TAU * 90.0 * t) * 0.5 + sin(TAU * 180.0 * t) * 0.35 + sin(TAU * 270.0 * t) * 0.2
		v += (1.0 if sin(TAU * 135.0 * t) > 0.0 else -1.0) * 0.12
		var s: int = clampi(int(v * 0.6 * 32767.0), -32767, 32767)
		data.append(s & 0xFF)
		data.append((s >> 8) & 0xFF)
	return wav(data, RATE, true)

func make_music() -> AudioStreamWAV:
	var rate := 11025
	var chords := [[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [261.6, 329.6, 392.0], [196.0, 246.9, 293.7]]
	var pattern := [0, 1, 2, 1, 0, 1, 2, 1]
	var step_len := 0.125
	var count: int = int(float(rate) * step_len)
	var data := PackedByteArray()
	for ci in range(4):
		var ch: Array = chords[ci]
		for st in range(8):
			var f: float = float(ch[pattern[st]]) * 2.0
			var bf: float = float(ch[0]) * 0.5
			for i in range(count):
				var t: float = float(i) / float(rate)
				var tt: float = (float(ci * 8 + st) * step_len) + t
				var env: float = exp(-7.0 * t) * minf(1.0, (step_len - t) * 40.0)
				var v: float = (sin(TAU * f * t) * 0.5 + sin(TAU * f * 2.0 * t) * 0.12) * env * 0.6
				v += (1.0 if sin(TAU * bf * tt) > 0.0 else -1.0) * 0.07
				var s: int = clampi(int(v * 32767.0), -32767, 32767)
				data.append(s & 0xFF)
				data.append((s >> 8) & 0xFF)
	return wav(data, rate, true)

func wav(data: PackedByteArray, rate: int, loop: bool) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(data.size() / 2.0)
	return w

# ---- engine ----
func start_engine() -> void:
	if not Game.sound_on:
		return
	engine_running = true
	if not engine.playing:
		engine.play()

func stop_engine() -> void:
	engine_running = false
	engine.stop()

func set_engine(speed01: float, gas: bool) -> void:
	if not engine_running:
		return
	engine.pitch_scale = 0.7 + speed01 * 1.8 + (0.25 if gas else 0.0)
	engine.volume_db = -16.0 + (4.0 if gas else 0.0)

# ---- music ----
func start_music() -> void:
	music.stream = make_music()
	apply_music()

func apply_music() -> void:
	if music.stream == null:
		return
	if Game.music_on:
		if not music.playing:
			music.play()
	else:
		music.stop()

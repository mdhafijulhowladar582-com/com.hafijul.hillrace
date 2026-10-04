extends Node
# Autoload "Game": data (cars, maps), save system, coins, unlocks, upgrades.
# দাম/গুণ বদলাতে চাইলে build_data() এর সংখ্যা বদলান।

signal coins_changed

const SAVE_PATH := "user://hillrace_save.json"
const MAX_LEVEL := 5
const COIN_VALUE := 5
const UPGRADE_NAMES := ["Engine", "Suspension", "Tires", "Fuel Tank"]

var cars: Array = []
var maps: Array = []
var coins := 0
var cars_unlocked: Array = []
var maps_unlocked: Array = []
var upgrades: Array = []
var best: Array = []
var stars: Array = []
var sel_car := 0
var sel_map := 0
var sound_on := true
var music_on := true
var debug_on := false
var tune := {"power": 1.0, "grip": 1.0, "susp": 1.0, "grav": 1.0}
var achievements: Array = []
var ach: Array = []
var pending_ach: Array = []
var stats := {"runs": 0, "coins_picked": 0, "flips": 0, "best_air": 0.0, "best_dist": 0.0}
var last_daily := ""
var streak := 0
var tutorial_done := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_data()
	build_achievements()
	reset_state()
	load_game()

# ---------------- data ----------------
# order: name, price, desc, style, body color, cabin color, power, vmax(rad/s), grip, mass, fuel, stiffness, damping, wheel radius, wheel x, wheel y, width, height
func make_car(n: String, price: int, desc: String, style: String, c1: Color, c2: Color, power: float, vmax: float, grip: float, mass: float, fuel: float, stiff: float, damp: float, wr: float, wx: float, wy: float, cw: float, ch: float) -> Dictionary:
	return {"name": n, "price": price, "desc": desc, "style": style, "c1": c1, "c2": c2, "power": power, "vmax": vmax, "grip": grip, "mass": mass, "fuel": fuel, "stiff": stiff, "damp": damp, "wr": wr, "wx": wx, "wy": wy, "cw": cw, "ch": ch}

func make_map(n: String, price: int, sky1: String, sky2: String, ground: String, grass: String, bg1: String, bg2: String, bg3: String, extra: Dictionary) -> Dictionary:
	var m := {
		"name": n, "price": price,
		"sky1": Color(sky1), "sky2": Color(sky2), "ground": Color(ground), "grass": Color(grass),
		"bg": [Color(bg1), Color(bg2), Color(bg3)],
		"grav": 1.0, "fric": 1.0, "amp": 1.0, "rough": 0.0, "wl": 1.0, "drag": 0.0, "fuel": 1.0,
		"dust": Color(ground), "fx": "none", "stars": false, "clouds": true,
		"orb": Color(1.0, 0.95, 0.7), "orb_r": 50.0, "bgstyle": "hills",
		"decor": "tree", "decor_c": Color("2f9e44"), "lights": false, "desc": ""
	}
	for k in extra.keys():
		m[k] = extra[k]
	return m

func build_data() -> void:
	cars.clear()
	maps.clear()
	cars.append(make_car("Jeep", 0, "Balanced all-rounder.", "jeep", Color("e8590c"), Color("f08c00"), 60000, 40, 1.4, 4.0, 100, 180, 10, 30, 48, 42, 130, 34))
	cars.append(make_car("Buggy", 600, "Light and bouncy. Quick off the line.", "buggy", Color("fcc419"), Color("343a40"), 52000, 44, 1.3, 2.8, 85, 130, 8, 28, 46, 40, 118, 28))
	cars.append(make_car("Pickup", 1500, "Heavy truck with a big fuel tank.", "pickup", Color("1c7ed6"), Color("4dabf7"), 75000, 37, 1.4, 5.0, 130, 230, 12, 31, 52, 44, 150, 36))
	cars.append(make_car("Rally Car", 3000, "Fast and very grippy.", "rally", Color("2f9e44"), Color("dee2e6"), 66000, 44, 1.7, 3.6, 100, 190, 11, 29, 50, 40, 136, 30))
	cars.append(make_car("Monster", 5000, "Huge wheels crush any bump.", "monster", Color("9c36b5"), Color("ffd43b"), 130000, 26, 1.6, 7.0, 110, 380, 16, 46, 62, 55, 150, 40))
	cars.append(make_car("Tractor", 8000, "Slow but climbs anything.", "tractor", Color("66a80f"), Color("ffe066"), 140000, 24, 2.0, 6.0, 140, 300, 14, 40, 54, 48, 128, 36))
	cars.append(make_car("Sports Car", 12000, "Very fast, low grip. Handle with care.", "sports", Color("e03131"), Color("212529"), 70000, 52, 1.0, 3.2, 80, 150, 9, 26, 52, 34, 150, 26))
	cars.append(make_car("Moon Rover", 18000, "Soft suspension and long range.", "rover", Color("ced4da"), Color("4dabf7"), 62000, 38, 1.5, 3.0, 120, 120, 8, 32, 50, 42, 126, 30))
	cars.append(make_car("Army Jeep", 24000, "Tough, heavy and strong.", "army", Color("5c7a3a"), Color("3b4a26"), 90000, 36, 1.8, 5.2, 120, 250, 13, 34, 52, 44, 140, 36))
	cars.append(make_car("Super Car", 32000, "The fastest machine of all.", "super", Color("212529"), Color("ffd43b"), 90000, 56, 1.5, 3.4, 95, 190, 11, 28, 54, 36, 156, 26))

	maps.append(make_map("Green Hills", 0, "4dabf7", "d0ebff", "6b4a2b", "51cf66", "8ce99a", "69db7c", "40c057",
		{"desc": "Gentle hills. Perfect to learn.", "dust": Color("c8a97e"), "decor": "tree", "decor_c": Color("2f9e44")}))
	maps.append(make_map("Desert Dunes", 800, "f4a259", "ffe8b0", "d9a95b", "f0c674", "e0b07a", "cc9a62", "b8844f",
		{"desc": "Huge soft dunes. Sand slows you.", "amp": 1.25, "wl": 0.55, "drag": 0.04, "fric": 0.9, "dust": Color("e6c78a"), "decor": "cactus", "decor_c": Color("5c940d"), "orb": Color("fff3bf"), "orb_r": 60.0}))
	maps.append(make_map("Snow Peaks", 2000, "9ec5e8", "f1f8ff", "e9eef5", "ffffff", "c9dcee", "aec7e0", "93b0cf",
		{"desc": "Icy and slippery. Easy on the gas!", "fric": 0.42, "wl": 0.9, "fx": "snow", "dust": Color("ffffff"), "decor": "pine", "decor_c": Color("2f6f4f"), "orb": Color(1, 1, 1)}))
	maps.append(make_map("Rocky Mountain", 4000, "7a8ca5", "d0d8e2", "5c5750", "9a948a", "8d97a3", "737d89", "5a6470",
		{"desc": "Steep climbs and rough rock.", "amp": 1.25, "rough": 5.0, "wl": 1.1, "dust": Color("9a948a"), "decor": "rock", "decor_c": Color("6c6760")}))
	maps.append(make_map("Jungle Trail", 6500, "74c69d", "d8f3dc", "4a3320", "2b8a3e", "3f8f5a", "2f7549", "1f5c39",
		{"desc": "Bumpy roots all the way.", "rough": 8.0, "wl": 1.3, "dust": Color("6b4a2b"), "decor": "tree", "decor_c": Color("1b6b34")}))
	maps.append(make_map("Mud Swamp", 9500, "8c8c6e", "d6d3b4", "4b3a2a", "6b5a3a", "8a8461", "716c4e", "5a563f",
		{"desc": "Thick mud drags you down.", "drag": 0.4, "fric": 0.85, "amp": 0.9, "rough": 4.0, "dust": Color("5a4630"), "decor": "reed", "decor_c": Color("7a6a3a")}))
	maps.append(make_map("Moon", 14000, "05060f", "1c2340", "8d8d94", "c2c2cc", "3b3f55", "2d3047", "20233a",
		{"desc": "Low gravity. Big jumps!", "grav": 0.38, "amp": 1.1, "wl": 0.8, "stars": true, "clouds": false, "orb": Color("4dabf7"), "orb_r": 70.0, "dust": Color("b0b0ba"), "decor": "rock", "decor_c": Color("6e6e78")}))
	maps.append(make_map("Volcano", 20000, "2b0a0a", "e8590c", "2a1a17", "ff6b1a", "5a1e12", "44150d", "2e0d08",
		{"desc": "Hot and steep. Fuel burns faster.", "amp": 1.3, "rough": 6.0, "wl": 1.1, "fuel": 1.25, "fx": "ash", "clouds": false, "orb": Color("ff922b"), "orb_r": 80.0, "dust": Color("5a3a30"), "decor": "rock", "decor_c": Color("3a2420")}))
	maps.append(make_map("Night City", 27000, "070b1f", "2a2f6b", "22252e", "5c6bc0", "1b1f3b", "14172e", "0e1022",
		{"desc": "Fast city roads at night.", "amp": 0.8, "wl": 0.9, "stars": true, "clouds": false, "orb": Color("f1f3f5"), "orb_r": 40.0, "bgstyle": "city", "lights": true, "dust": Color("6b6f80"), "decor": "lamp", "decor_c": Color("ffd43b")}))
	maps.append(make_map("Space Station", 35000, "000008", "1a0b3b", "3a3f4b", "6ee7ff", "2a1b4d", "1c1236", "110a26",
		{"desc": "Low gravity, slippery metal.", "grav": 0.5, "fric": 0.8, "rough": 7.0, "fuel": 1.2, "stars": true, "clouds": false, "orb": Color("9775fa"), "orb_r": 90.0, "lights": true, "dust": Color("8ecae6"), "decor": "crystal", "decor_c": Color("66d9e8")}))

# ---------------- save ----------------
func reset_state() -> void:
	coins = 0
	sel_car = 0
	sel_map = 0
	cars_unlocked = []
	maps_unlocked = []
	upgrades = []
	best = []
	stars = []
	for i in range(10):
		cars_unlocked.append(i == 0)
		maps_unlocked.append(i == 0)
		upgrades.append([0, 0, 0, 0])
		best.append(0.0)
		stars.append(0)
	tune = {"power": 1.0, "grip": 1.0, "susp": 1.0, "grav": 1.0}
	ach = []
	for i in range(achievements.size()):
		ach.append(false)
	pending_ach = []
	stats = {"runs": 0, "coins_picked": 0, "flips": 0, "best_air": 0.0, "best_dist": 0.0}
	last_daily = ""
	streak = 0
	tutorial_done = false

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", 0))
	sel_car = clampi(int(parsed.get("sel_car", 0)), 0, 9)
	sel_map = clampi(int(parsed.get("sel_map", 0)), 0, 9)
	sound_on = bool(parsed.get("sound", true))
	music_on = bool(parsed.get("music", true))
	debug_on = bool(parsed.get("debug", false))
	var a = parsed.get("cars_unlocked")
	if a is Array and a.size() == 10:
		for i in range(10):
			cars_unlocked[i] = bool(a[i])
	a = parsed.get("maps_unlocked")
	if a is Array and a.size() == 10:
		for i in range(10):
			maps_unlocked[i] = bool(a[i])
	a = parsed.get("best")
	if a is Array and a.size() == 10:
		for i in range(10):
			best[i] = float(a[i])
	a = parsed.get("stars")
	if a is Array and a.size() == 10:
		for i in range(10):
			stars[i] = int(a[i])
	a = parsed.get("upgrades")
	if a is Array and a.size() == 10:
		for i in range(10):
			var row = a[i]
			if row is Array and row.size() == 4:
				for j in range(4):
					upgrades[i][j] = clampi(int(row[j]), 0, MAX_LEVEL)
	var t = parsed.get("tune")
	if t is Dictionary:
		for k in tune.keys():
			if t.has(k):
				tune[k] = clampf(float(t[k]), 0.5, 1.8)
	var aa = parsed.get("ach")
	if aa is Array and aa.size() == ach.size():
		for i in range(ach.size()):
			ach[i] = bool(aa[i])
	var st = parsed.get("stats")
	if st is Dictionary:
		for k in stats.keys():
			if st.has(k):
				stats[k] = float(st[k])
	last_daily = str(parsed.get("last_daily", ""))
	streak = int(parsed.get("streak", 0))
	tutorial_done = bool(parsed.get("tutorial", false))
	if not cars_unlocked[sel_car]:
		sel_car = 0
	if not maps_unlocked[sel_map]:
		sel_map = 0

func save_game() -> void:
	var d := {
		"coins": coins, "sel_car": sel_car, "sel_map": sel_map,
		"sound": sound_on, "music": music_on, "debug": debug_on,
		"cars_unlocked": cars_unlocked, "maps_unlocked": maps_unlocked,
		"best": best, "stars": stars, "upgrades": upgrades, "tune": tune,
		"ach": ach, "stats": stats, "last_daily": last_daily, "streak": streak, "tutorial": tutorial_done
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func reset_progress() -> void:
	reset_state()
	save_game()
	coins_changed.emit()

# ---------------- economy ----------------
func buy_car(i: int) -> bool:
	if cars_unlocked[i]:
		return true
	var price: int = cars[i]["price"]
	if coins < price:
		return false
	coins -= price
	cars_unlocked[i] = true
	check_achievements()
	save_game()
	coins_changed.emit()
	return true

func buy_map(i: int) -> bool:
	if maps_unlocked[i]:
		return true
	var price: int = maps[i]["price"]
	if coins < price:
		return false
	coins -= price
	maps_unlocked[i] = true
	check_achievements()
	save_game()
	coins_changed.emit()
	return true

func upgrade_cost(i: int, kind: int) -> int:
	var lvl: int = upgrades[i][kind]
	var price: int = cars[i]["price"]
	var base: int = 120 + int(price * 0.04)
	return base * (lvl + 1)

func buy_upgrade(i: int, kind: int) -> bool:
	var lvl: int = upgrades[i][kind]
	if lvl >= MAX_LEVEL:
		return false
	var cost: int = upgrade_cost(i, kind)
	if coins < cost:
		return false
	coins -= cost
	upgrades[i][kind] = lvl + 1
	save_game()
	coins_changed.emit()
	return true

# car stats including upgrades and tuning sliders
func effective(i: int) -> Dictionary:
	var c: Dictionary = cars[i]
	var u: Array = upgrades[i]
	var e: int = u[0]
	var s: int = u[1]
	var t: int = u[2]
	var f: int = u[3]
	return {
		"power": float(c["power"]) * (1.0 + 0.06 * e) * float(tune["power"]),
		"vmax": float(c["vmax"]) * (1.0 + 0.03 * e),
		"grip": float(c["grip"]) * (1.0 + 0.06 * t) * float(tune["grip"]),
		"fuel": float(c["fuel"]) * (1.0 + 0.10 * f),
		"stiff": float(c["stiff"]) * (1.0 + 0.04 * s) * float(tune["susp"]),
		"damp": float(c["damp"]) * (1.0 + 0.06 * s) * float(tune["susp"]),
		"mass": float(c["mass"])
	}

# distance goals (meters) for 1, 2, 3 stars
func map_targets(i: int) -> Array:
	var s: float = 1.0 + float(i) * 0.15
	return [int(250.0 * s), int(550.0 * s), int(900.0 * s)]

func submit_run(map_i: int, dist: float, pickups: int, flips: int, air_best: float, bonus_pts: int) -> Dictionary:
	var targets: Array = map_targets(map_i)
	var got := 0
	for k in range(3):
		if dist >= float(targets[k]):
			got = k + 1
	var old: int = stars[map_i]
	var bonus := 0
	for k in range(old, got):
		bonus += 100 * (k + 1) * (map_i + 1)
	if got > old:
		stars[map_i] = got
	var pickup_coins: int = pickups * COIN_VALUE
	var dist_coins: int = int(dist / 10.0)
	var newbest: bool = dist > float(best[map_i]) and dist > 1.0
	if newbest:
		best[map_i] = dist
	var total: int = pickup_coins + dist_coins + bonus + bonus_pts
	coins += total
	stats["runs"] = int(stats["runs"]) + 1
	stats["coins_picked"] = int(stats["coins_picked"]) + pickups
	stats["flips"] = int(stats["flips"]) + flips
	stats["best_air"] = maxf(float(stats["best_air"]), air_best)
	stats["best_dist"] = maxf(float(stats["best_dist"]), dist)
	check_achievements()
	var names: Array = pending_ach.duplicate()
	pending_ach.clear()
	save_game()
	coins_changed.emit()
	return {"stars": got, "pickup_coins": pickup_coins, "dist_coins": dist_coins, "bonus": bonus, "bonus_pts": bonus_pts, "total": total, "newbest": newbest, "ach": names, "flips": flips}

func total_stars() -> int:
	var n := 0
	for s in stars:
		n += int(s)
	return n

# ---------------- achievements ----------------
func make_ach(n: String, desc: String, kind: String, target: float, reward: int) -> Dictionary:
	return {"name": n, "desc": desc, "kind": kind, "target": target, "reward": reward}

func build_achievements() -> void:
	achievements.clear()
	achievements.append(make_ach("First Drive", "Finish your first run", "runs", 1, 50))
	achievements.append(make_ach("Rookie", "Reach 300 m in one run", "dist", 300, 100))
	achievements.append(make_ach("Explorer", "Reach 1000 m in one run", "dist", 1000, 300))
	achievements.append(make_ach("Legend", "Reach 2500 m in one run", "dist", 2500, 1000))
	achievements.append(make_ach("Coin Collector", "Collect 100 coins", "coins", 100, 150))
	achievements.append(make_ach("Treasure Hunter", "Collect 1000 coins", "coins", 1000, 500))
	achievements.append(make_ach("Flipper", "Do 10 flips", "flips", 10, 200))
	achievements.append(make_ach("Daredevil", "Stay 3 seconds in the air", "air", 3, 200))
	achievements.append(make_ach("Star Hunter", "Earn 10 stars", "stars", 10, 400))
	achievements.append(make_ach("Collector", "Own 3 cars", "cars", 3, 300))
	achievements.append(make_ach("Traveler", "Unlock 3 maps", "maps", 3, 300))
	achievements.append(make_ach("Marathon", "Play 50 runs", "runs", 50, 500))

func count_true(a: Array) -> int:
	var n := 0
	for v in a:
		if v:
			n += 1
	return n

func ach_value(kind: String) -> float:
	if kind == "runs":
		return float(stats["runs"])
	if kind == "dist":
		return float(stats["best_dist"])
	if kind == "coins":
		return float(stats["coins_picked"])
	if kind == "flips":
		return float(stats["flips"])
	if kind == "air":
		return float(stats["best_air"])
	if kind == "stars":
		return float(total_stars())
	if kind == "cars":
		return float(count_true(cars_unlocked))
	if kind == "maps":
		return float(count_true(maps_unlocked))
	return 0.0

func check_achievements() -> Array:
	var newly: Array = []
	for i in range(achievements.size()):
		if ach[i]:
			continue
		var a: Dictionary = achievements[i]
		if ach_value(a["kind"]) >= float(a["target"]):
			ach[i] = true
			coins += int(a["reward"])
			pending_ach.append(a["name"])
			newly.append(a)
	if newly.size() > 0:
		coins_changed.emit()
	return newly

# ---------------- daily reward ----------------
func today() -> String:
	return Time.get_date_string_from_system(true)

func daily_available() -> bool:
	return last_daily != today()

func next_streak() -> int:
	var yday: String = Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
	if last_daily == yday:
		return streak + 1
	return 1

func daily_reward_for(s: int) -> int:
	return 100 * mini(s, 7)

func claim_daily() -> int:
	if not daily_available():
		return 0
	var s: int = next_streak()
	var r: int = daily_reward_for(s)
	streak = s
	last_daily = today()
	coins += r
	save_game()
	coins_changed.emit()
	return r

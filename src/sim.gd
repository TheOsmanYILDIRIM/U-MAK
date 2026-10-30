extends RefCounted
## Fixed-step, deterministic company-level world model. No soldier-level AI.
const WORLD := Vector2(1200.0, 800.0)
const RIVER_X := 600.0
const CROSSINGS := [230.0, 575.0]
const FRONT_COUNT := 4
const RESERVE_COUNT := 2
const MAX_REPORTS := 12

var units: Array[Dictionary] = []
var wings: Array[Dictionary] = []
var reports: Array[String] = []
var ticks := 0
var elapsed := 0.0

func _init() -> void:
	reset()

func reset() -> void:
	units.clear()
	wings.clear()
	reports.clear()
	ticks = 0
	elapsed = 0.0
	for team in range(2):
		for wing_index in range(2):
			var wing_id := team * 2 + wing_index
			var line_x := 315.0 if team == 0 else 885.0
			var y_base := 105.0 + 315.0 * wing_index
			var commander := "Atılgan" if wing_index == 0 else "Temkinli"
			wings.append({"id": wing_id, "team": team, "name": "Sol kanat" if wing_index == 0 else "Sağ kanat", "commander": commander, "autonomy": 1, "a": Vector2(line_x, y_base), "b": Vector2(line_x, y_base + 260), "unit_ids": [], "version": 0})
			for local_index in range(FRONT_COUNT + RESERVE_COUNT):
				var id := units.size()
				var kind := "okçu" if local_index in [2, 5] else ("süvari" if local_index == 0 else "piyade")
				var u: Dictionary = {"id": id, "team": team, "wing": wing_id, "kind": kind, "pos": Vector2.ZERO, "target": Vector2.ZERO, "slot": local_index if local_index < FRONT_COUNT else -1, "order": "line", "personnel": 100.0, "morale": 88.0, "stamina": 96.0, "water": 75.0, "experience": 22.0 + local_index * 4.0, "last_hit": false, "message": "Mevzide", "version": 0}
				units.append(u)
				wings[wing_id]["unit_ids"].append(id)
			_assign_positions(wing_id, true)
	report("Gözcüler: iki ordu nehrin karşı kıyılarında.")
	report("Kanadı seç, hat çiz veya bölüğe özel görev ver.")

func report(msg: String) -> void:
	reports.push_front(msg)
	if reports.size() > MAX_REPORTS:
		reports.pop_back()

func get_unit(id: int) -> Dictionary:
	if id < 0 or id >= units.size():
		return {}
	return units[id]

func _slot_position(w: Dictionary, index: int) -> Vector2:
	return w["a"].lerp(w["b"], (float(index) + 0.5) / float(FRONT_COUNT))

func _reserve_position(w: Dictionary, index: int) -> Vector2:
	var middle: Vector2 = (w["a"] + w["b"]) * 0.5
	var back: Vector2 = Vector2(-94.0 if w["team"] == 0 else 94.0, 0.0)
	return middle + back + Vector2(0.0, (float(index) - 0.5) * 72.0)

func _assign_positions(wing_id: int, initial := false) -> void:
	var w: Dictionary = wings[wing_id]
	var reserve_i := 0
	for id in w["unit_ids"]:
		var u: Dictionary = units[id]
		if u["order"] != "line" or u["personnel"] < 1.0:
			continue
		var goal: Vector2 = _slot_position(w, u["slot"]) if u["slot"] >= 0 else _reserve_position(w, reserve_i)
		if u["slot"] < 0:
			reserve_i += 1
		u["target"] = goal
		if initial:
			u["pos"] = goal

func set_line(wing_id: int, a: Vector2, b: Vector2) -> bool:
	if wing_id < 0 or wing_id >= wings.size():
		return false
	var length := a.distance_to(b)
	if length < 90.0 or length > 480.0:
		return false
	for p in [a, b]:
		if p.x < 25.0 or p.x > WORLD.x - 25.0 or p.y < 25.0 or p.y > WORLD.y - 25.0:
			return false
	var w: Dictionary = wings[wing_id]
	w["a"] = a
	w["b"] = b
	w["version"] += 1
	_assign_positions(wing_id)
	if w["team"] == 0:
		report("%s: yeni hat kabul edildi." % w["name"])
	return true

func advance(wing_id: int, distance: float) -> void:
	if wing_id < 0 or wing_id >= wings.size():
		return
	var w: Dictionary = wings[wing_id]
	var direction := 1.0 if w["team"] == 0 else -1.0
	var shift := Vector2(distance * direction, 0.0)
	var a: Vector2 = w["a"]
	var b: Vector2 = w["b"]
	set_line(wing_id, a + shift, b + shift)

func special_order(unit_id: int, command: String, goal := Vector2.ZERO) -> bool:
	var u := get_unit(unit_id)
	if u.is_empty() or u["team"] != 0 or u["personnel"] <= 0.0:
		return false
	if not command in ["move", "charge", "hold", "recall"]:
		return false
	if command == "recall":
		u["order"] = "line"
		u["target"] = u["pos"]
		u["slot"] = -1
		_fill_vacancy(u["wing"])
		report("%d. bölük: kanat komutasına döndü." % (unit_id + 1))
		return true
	u["order"] = command
	u["target"] = u["pos"] if command == "hold" else goal
	u["slot"] = -1
	u["version"] += 1
	_fill_vacancy(u["wing"])
	report("%d. bölük: %s emri aldı." % [unit_id + 1, command])
	return true

func _fill_vacancy(wing_id: int) -> void:
	var w: Dictionary = wings[wing_id]
	var occupied: Dictionary = {}
	for id in w["unit_ids"]:
		var u: Dictionary = units[id]
		if u["order"] == "line" and u["personnel"] > 0.0 and u["slot"] >= 0:
			occupied[u["slot"]] = true
	for slot in range(FRONT_COUNT):
		if occupied.has(slot):
			continue
		for id in w["unit_ids"]:
			var u: Dictionary = units[id]
			if u["order"] == "line" and u["slot"] == -1 and u["personnel"] > 0.0:
				u["slot"] = slot
				occupied[slot] = true
				if w["team"] == 0:
					report("Yedek %d. bölük ön hattaki boşluğu dolduruyor." % (id + 1))
				break
	_assign_positions(wing_id)

func _crossing_goal(start: Vector2, finish: Vector2) -> Vector2:
	# River is uncrossable except bridge/ford; do not allow direct Euclidean path.
	var opposite_bank := (start.x < RIVER_X - 34.0 and finish.x > RIVER_X + 34.0) or (start.x > RIVER_X + 34.0 and finish.x < RIVER_X - 34.0)
	if not opposite_bank:
		return finish
	var crossing_y := CROSSINGS[0] if absf(start.y - CROSSINGS[0]) + absf(finish.y - CROSSINGS[0]) < absf(start.y - CROSSINGS[1]) + absf(finish.y - CROSSINGS[1]) else CROSSINGS[1]
	if absf(start.y - crossing_y) > 17.0:
		return Vector2(start.x, crossing_y)
	return Vector2(finish.x, crossing_y)

func _move_unit(u: Dictionary, delta: float) -> void:
	var goal: Vector2 = _crossing_goal(u["pos"], u["target"])
	var speed := 44.0 if u["kind"] == "süvari" else 31.0
	speed *= 0.55 + 0.45 * (u["stamina"] / 100.0)
	if u["order"] == "charge":
		speed *= 1.3
	var difference: Vector2 = goal - u["pos"]
	if difference.length() > 0.7:
		u["pos"] += difference.limit_length(delta * speed)
		u["stamina"] = maxf(0.0, u["stamina"] - delta * 0.27)
	else:
		u["stamina"] = minf(100.0, u["stamina"] + delta * 0.16)

func _nearest_enemy(u: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var dist := INF
	for enemy in units:
		if enemy["team"] == u["team"] or enemy["personnel"] <= 0.0:
			continue
		var d: float = u["pos"].distance_squared_to(enemy["pos"])
		if d < dist:
			dist = d
			best = enemy
	return best

func _resolve_combat(delta: float) -> void:
	var incoming: Array[float] = []
	for _i in range(units.size()):
		incoming.append(0.0)
	for u in units:
		u["last_hit"] = false
		if u["personnel"] <= 0.0:
			continue
		var enemy := _nearest_enemy(u)
		if enemy.is_empty():
			continue
		var d: float = u["pos"].distance_to(enemy["pos"])
		var reach := 100.0 if u["kind"] == "okçu" else 32.0
		if d < reach:
			var readiness: float = (0.5 + u["stamina"] / 200.0) * (0.5 + u["morale"] / 200.0)
			incoming[enemy["id"]] += delta * (0.95 if u["kind"] == "okçu" else 1.6) * readiness
			u["stamina"] = maxf(0.0, u["stamina"] - delta * 0.7)
	for id in range(units.size()):
		if incoming[id] <= 0.0:
			continue
		var u: Dictionary = units[id]
		u["personnel"] = maxf(0.0, u["personnel"] - incoming[id])
		u["morale"] = maxf(0.0, u["morale"] - incoming[id] * 0.36)
		u["last_hit"] = true
		if u["morale"] < 17.0 and u["order"] != "retreat":
			u["order"] = "retreat"
			u["slot"] = -1
			u["target"] = Vector2(80.0 if u["team"] == 0 else WORLD.x - 80.0, u["pos"].y)
			_fill_vacancy(u["wing"])
			if u["team"] == 0:
				report("%d. bölük çözülüyor!" % (id + 1))

func _enemy_ai() -> void:
	for wing_id in [2, 3]:
		var w: Dictionary = wings[wing_id]
		var active := 0.0
		var alive := 0
		for id in w["unit_ids"]:
			active += units[id]["morale"]
			alive += 1
		if alive > 0 and active / float(alive) < 36.0:
			advance(wing_id, -18.0) # retreat toward enemy home
		else:
			advance(wing_id, 12.0 if wing_id == 2 else 9.0)
	if ticks % 60 == 0:
		report("Keşif: düşman kanatları yeni mevzilere yöneliyor.")

func step(delta: float) -> void:
	ticks += 1
	elapsed += delta
	if ticks % 20 == 0:
		_enemy_ai()
	for u in units:
		if u["personnel"] > 0.0:
			_move_unit(u, delta)
	_resolve_combat(delta)

func total_personnel(team: int) -> int:
	var n := 0.0
	for u in units:
		if u["team"] == team:
			n += u["personnel"]
	return roundi(n)

func snapshot_signature() -> String:
	var packed := "%d|" % ticks
	for u in units:
		packed += "%d,%d,%d,%d;" % [roundi(u["pos"].x), roundi(u["pos"].y), roundi(u["personnel"] * 10.0), roundi(u["morale"] * 10.0)]
	return packed

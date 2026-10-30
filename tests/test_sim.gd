extends SceneTree
const Sim = preload("res://src/sim.gd")
var checks := 0
var errors: Array[String] = []

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		errors.append(description)
		printerr("FAIL ", description)
	else:
		print("PASS ", description)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var sim = Sim.new()
	check(sim.units.size() == 24, "24 simulated companies; soldiers are aggregated")
	check(sim.wings.size() == 4, "two wings on both sides")
	check(sim.total_personnel(0) == 1200, "player has 1200 personnel")
	check(not sim.set_line(0, Vector2(20, 20), Vector2(30, 40)), "reject undersized line")
	check(sim.set_line(0, Vector2(350, 120), Vector2(350, 360)), "accept valid line")
	var protected_id := 0
	check(sim.special_order(protected_id, "charge", Vector2(510, 260)), "issue independent company order")
	check(sim.units[protected_id]["order"] == "charge", "special order stored")
	var reserve_promoted := false
	for id in sim.wings[0]["unit_ids"]:
		if id != protected_id and id >= 4 and sim.units[id]["slot"] == 0:
			reserve_promoted = true
	check(reserve_promoted, "reserve fills vacated first-line position")
	sim.set_line(0, Vector2(380, 110), Vector2(380, 350))
	check(sim.units[protected_id]["order"] == "charge", "new wing line cannot overwrite special order")
	check(sim.units[protected_id]["target"].is_equal_approx(Vector2(510, 260)), "special goal preserved")
	check(sim.special_order(protected_id, "recall"), "recall succeeds")
	check(sim.units[protected_id]["order"] == "line", "recall restores line control")
	var river_goal: Vector2 = sim._crossing_goal(Vector2(420, 100), Vector2(800, 100))
	check(absf(river_goal.y - 230.0) < 0.1, "river crossings route via pass")
	var before: Vector2 = sim.units[4]["pos"]
	for _step in range(100):
		sim.step(0.1)
	check(sim.units[4]["pos"].distance_to(before) > 1.0, "units actually march toward allocated slots")
	check(sim.wings[2]["a"].x < 885.0, "enemy AI advances and repositions")
	check(sim.total_personnel(0) <= 1200, "casualties never increase population")
	var a = Sim.new()
	var b = Sim.new()
	for _step in range(240):
		a.step(0.1)
		b.step(0.1)
	check(a.snapshot_signature() == b.snapshot_signature(), "fixed-step AI simulation is deterministic")
	check(a.units.all(func(u): return u["personnel"] >= 0.0 and u["morale"] >= 0.0), "personnel and morale never below zero")
	print("TEST RESULT: %d checks, %d failures" % [checks, errors.size()])
	quit(0 if errors.is_empty() else 1)

extends Control
## World-space rendering and touch/mouse camera controller.
signal unit_chosen(unit_id: int)
signal line_drawn(a: Vector2, b: Vector2)
signal target_chosen(position: Vector2)

const WORLD := Vector2(1200.0, 800.0)
const BLUE := Color("69b4f0")
const RED := Color("ea866b")
var sim: RefCounted
var selected_wing := 0
var selected_unit := -1
var mode := "select" # select | line | move | charge
var camera_center := Vector2(600, 400)
var zoom := 1.0
var touch_points: Dictionary = {}
var mouse_active := false
var drag_origin := Vector2.ZERO
var drag_last := Vector2.ZERO
var is_dragging := false
var pinch_active := false
var pinch_origin := Vector2.ZERO
var pinch_distance := 1.0
var hint := "Sol kanadı seçip HAT düğmesine bas."

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	queue_redraw()

func _scale() -> float:
	return minf(size.x / WORLD.x, size.y / WORLD.y) * zoom

func world_to_screen(p: Vector2) -> Vector2:
	return (p - camera_center) * _scale() + size * 0.5

func screen_to_world(p: Vector2) -> Vector2:
	return (p - size * 0.5) / _scale() + camera_center

func zoom_at(factor: float, screen_pos: Vector2) -> void:
	var anchor := screen_to_world(screen_pos)
	zoom = clampf(zoom * factor, 0.7, 5.0)
	camera_center = anchor - (screen_pos - size * 0.5) / _scale()
	queue_redraw()

func reset_camera() -> void:
	zoom = 1.0
	camera_center = WORLD * 0.5
	queue_redraw()

func set_mode(value: String) -> void:
	mode = value
	is_dragging = false
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("182c2b"))
	var tl := world_to_screen(Vector2.ZERO)
	var bottom := world_to_screen(WORLD)
	draw_rect(Rect2(tl, bottom - tl), Color("394e37"))
	for gx in range(0, 1201, 100):
		_line(Vector2(gx, 0), Vector2(gx, 800), Color("526549", 0.23), 1.0)
	for gy in range(0, 801, 100):
		_line(Vector2(0, gy), Vector2(1200, gy), Color("526549", 0.23), 1.0)
	for i in range(18):
		var tx := float((i * 173 + 131) % 1100 + 45)
		var ty := float((i * 97 + 61) % 730 + 35)
		_circle(Vector2(tx, ty), 27.0 + float(i % 4) * 11.0, Color("233c32", 0.65))
	for i in range(10):
		var cx := 600.0 + sin(float(i) * 0.53) * 25.0
		_line(Vector2(cx, float(i) * 90.0), Vector2(600.0 + sin(float(i + 1) * 0.53) * 25.0, float(i + 1) * 90.0), Color("34758b"), 39.0 * _scale())
	for y in [230.0, 575.0]:
		var p := world_to_screen(Vector2(600.0, y))
		var rect := Rect2(p - Vector2(39, 12) * _scale(), Vector2(78, 24) * _scale())
		draw_rect(rect, Color("b3a27c"))
		_label(Vector2(654, y - 11), "KÖPRÜ" if y == 575.0 else "SIĞ GEÇİT", Color("e7d9aa"), 14)
	_circle(Vector2(430, 400), 14, Color("a8b6ac"))
	_label(Vector2(450, 397), "KUYU", Color("d5ebe2"), 16)
	if sim == null:
		return
	for w in sim.wings:
		var color: Color = BLUE if w["team"] == 0 else RED
		_line(w["a"], w["b"], color.darkened(0.15), (5.0 if w["id"] == selected_wing else 3.0) * _scale())
		if w["id"] == selected_wing:
			_circle(w["a"], 9.0, Color("d8f5ec"))
			_circle(w["b"], 9.0, Color("d8f5ec"))
	for u in sim.units:
		if u["personnel"] <= 0.0:
			continue
		var c: Color = BLUE if u["team"] == 0 else RED
		var p: Vector2 = u["pos"]
		if u["order"] != "line" and u["team"] == 0:
			_line(p, u["target"], Color("e3c575", 0.9), 2.1 * _scale())
		if u["id"] == selected_unit:
			_circle(p, 23.0, Color("f7e8a0", 0.35))
		var s := 15.0 if u["kind"] == "süvari" else 12.0
		var center := world_to_screen(p)
		var unit_rect := Rect2(center - Vector2(s, s) * _scale(), Vector2(s * 2.0, s * 2.0) * _scale())
		draw_rect(unit_rect, c.darkened(0.45))
		draw_rect(unit_rect.grow(-2.4 * _scale()), c)
		for k in range(4):
			var point := center + Vector2(-5.0 + (k % 2) * 10.0, -5.0 + int(k / 2) * 10.0) * _scale()
			draw_circle(point, maxf(1.8, 2.5 * _scale()), Color("e5e0c7"))
		if u["morale"] < 40.0:
			_label(p + Vector2(-14, -23), "!", Color("ffe08c"), 19)
		if u["order"] == "retreat":
			_label(p + Vector2(-8, -25), "↘", Color("ffad7c"), 19)
		var bar_rect := Rect2(center + Vector2(-15.0, 17.0) * _scale(), Vector2(30.0 * (u["morale"] / 100.0), 3.0) * _scale())
		draw_rect(bar_rect, Color("8dcc79") if u["morale"] > 45.0 else Color("edb26a"))
	if mode == "line" and is_dragging and not pinch_active:
		_line(drag_origin, drag_last, Color("f0e8ac"), 3.0 * _scale())
		_circle(drag_origin, 8.0, Color("f0e8ac"))
		_circle(drag_last, 8.0, Color("f0e8ac"))

func _line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	draw_line(world_to_screen(a), world_to_screen(b), color, maxf(1.0, width), true)

func _circle(pos: Vector2, radius: float, color: Color) -> void:
	draw_circle(world_to_screen(pos), maxf(1.0, radius * _scale()), color)

func _label(pos: Vector2, value: String, color: Color, font_size: int) -> void:
	draw_string(ThemeDB.fallback_font, world_to_screen(pos), value, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, roundi(float(font_size) * _scale())), color)

func _pick_unit(point: Vector2) -> int:
	var nearest := -1
	var distance := 40.0
	for u in sim.units:
		if u["team"] != 0 or u["personnel"] <= 0.0:
			continue
		var d: float = u["pos"].distance_to(point)
		if d < distance:
			distance = d
			nearest = u["id"]
	return nearest

func _start(screen_pos: Vector2) -> void:
	mouse_active = true
	is_dragging = false
	drag_origin = screen_to_world(screen_pos)
	drag_last = drag_origin

func _drag(old_screen: Vector2, new_screen: Vector2) -> void:
	if not mouse_active:
		return
	if old_screen.distance_to(new_screen) > 0.8:
		is_dragging = true
	if mode == "line":
		drag_last = screen_to_world(new_screen)
	elif mode == "select":
		camera_center += (old_screen - new_screen) / _scale()
	queue_redraw()

func _finish(screen_pos: Vector2) -> void:
	if not mouse_active:
		return
	mouse_active = false
	var finish := screen_to_world(screen_pos)
	if mode == "line" and is_dragging:
		line_drawn.emit(drag_origin, finish)
	elif mode == "move" or mode == "charge":
		target_chosen.emit(finish)
	elif not is_dragging:
		var id := _pick_unit(finish)
		if id >= 0:
			unit_chosen.emit(id)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_at(1.15, event.position)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_at(1.0 / 1.15, event.position)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start(event.position)
			else:
				_finish(event.position)
			accept_event()
	elif event is InputEventMouseMotion and mouse_active:
		_drag(event.position - event.relative, event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			if touch_points.size() == 1:
				_start(event.position)
			elif touch_points.size() == 2:
				pinch_active = true
				mouse_active = false
				var positions: Array = touch_points.values()
				pinch_origin = (positions[0] + positions[1]) * 0.5
				pinch_distance = maxf(1.0, positions[0].distance_to(positions[1]))
		else:
			var last_touch := touch_points.size() == 1 and not pinch_active
			touch_points.erase(event.index)
			if last_touch:
				_finish(event.position)
			if touch_points.size() < 2:
				pinch_active = false
				mouse_active = false
		accept_event()
	elif event is InputEventScreenDrag:
		if not touch_points.has(event.index):
			return
		var old: Vector2 = touch_points[event.index]
		touch_points[event.index] = event.position
		if touch_points.size() == 2:
			var positions: Array = touch_points.values()
			var center: Vector2 = (positions[0] + positions[1]) * 0.5
			var distance := maxf(1.0, positions[0].distance_to(positions[1]))
			var anchor := screen_to_world(pinch_origin)
			zoom = clampf(zoom * distance / pinch_distance, 0.7, 5.0)
			camera_center = anchor - (center - size * 0.5) / _scale()
			pinch_origin = center
			pinch_distance = distance
			queue_redraw()
		elif not pinch_active:
			_drag(old, event.position)
		accept_event()

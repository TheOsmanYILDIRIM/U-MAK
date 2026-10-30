extends Control
const Sim = preload("res://src/sim.gd")
const Arena = preload("res://src/arena.gd")

var sim = Sim.new()
var arena: Control
var status: Label
var info: Label
var reports: Label
var command_panel: PanelContainer
var unit_choice := -1
var wing_choice := 0
var accumulator := 0.0
var hud_timer := 0.0
var paused := false
var pause_button: Button

func _ready() -> void:
	arena = Arena.new()
	arena.sim = sim
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(arena)
	arena.unit_chosen.connect(_choose_unit)
	arena.line_drawn.connect(_draw_line)
	arena.target_chosen.connect(_choose_target)
	_build_hud()
	_update_hud()

func _make_button(text: String, callback: Callable, width: float = 99.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 47)
	b.pressed.connect(callback)
	return b

func _build_hud() -> void:
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 60
	add_child(top)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	status = Label.new()
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 16)
	top_row.add_child(status)
	top_row.add_child(_make_button("－", func(): arena.zoom_at(0.77, arena.size * 0.5), 48))
	top_row.add_child(_make_button("＋", func(): arena.zoom_at(1.3, arena.size * 0.5), 48))
	top_row.add_child(_make_button("⊡", func(): arena.reset_camera(), 48))
	pause_button = _make_button("⏸", _pause, 50)
	top_row.add_child(pause_button)

	var lower := PanelContainer.new()
	lower.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lower.offset_top = -178
	lower.offset_bottom = 0
	add_child(lower)
	var content := VBoxContainer.new()
	lower.add_child(content)
	info = Label.new()
	info.add_theme_font_size_override("font_size", 16)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(info)
	var commands := HFlowContainer.new()
	commands.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(commands)
	var labels := [
		["SOL", "wing0"], ["SAĞ", "wing1"], ["HAT", "line"], ["İLERLE", "advance"],
		["YÜRÜ", "move"], ["HÜCUM", "charge"], ["TUT", "hold"], ["GERİ", "recall"], ["BİLGİ", "info"]
	]
	for item in labels:
		var action: String = item[1]
		commands.add_child(_make_button(item[0], func(): _action(action), 89))
	command_panel = PanelContainer.new()
	command_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	command_panel.offset_left = -295
	command_panel.offset_top = 70
	command_panel.offset_right = -10
	command_panel.offset_bottom = 305
	add_child(command_panel)
	reports = Label.new()
	reports.custom_minimum_size = Vector2(250, 210)
	reports.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reports.add_theme_font_size_override("font_size", 14)
	command_panel.add_child(reports)
	command_panel.visible = false

func _choose_unit(id: int) -> void:
	unit_choice = id
	wing_choice = sim.units[id]["wing"]
	arena.selected_unit = id
	arena.selected_wing = wing_choice
	arena.set_mode("select")
	_update_hud()

func _draw_line(a: Vector2, b: Vector2) -> void:
	if sim.set_line(wing_choice, a, b):
		arena.hint = "Hat kuruldu. Yedekler yeni düzene uyuyor."
	else:
		arena.hint = "Hat reddedildi: sınır dışında veya uygun uzunlukta değil."
	arena.set_mode("select")
	_update_hud()

func _choose_target(pos: Vector2) -> void:
	if unit_choice < 0:
		arena.hint = "Önce bir dost bölüğü seç."
	else:
		var action: String = arena.mode
		sim.special_order(unit_choice, action, pos)
		arena.hint = "Bölük özel emri aldı; kanat planı devam ediyor."
	arena.set_mode("select")
	_update_hud()

func _action(action: String) -> void:
	match action:
		"wing0", "wing1":
			unit_choice = -1
			wing_choice = 0 if action == "wing0" else 1
			arena.selected_unit = -1
			arena.selected_wing = wing_choice
			arena.set_mode("select")
			arena.hint = "Kanat seçildi. HAT veya İLERLE emri verebilirsin."
		"line":
			arena.set_mode("line")
			arena.hint = "Haritada parmağınla yeni hat çiz."
		"advance":
			sim.advance(wing_choice, 70.0)
			arena.hint = "Kanat mevcut düzenini koruyarak ilerliyor."
		"move", "charge":
			if unit_choice < 0:
				arena.hint = "Önce haritadan bir dost bölüğü seç."
			else:
				arena.set_mode(action)
				arena.hint = "Haritada %s hedefini seç." % ("hücum" if action == "charge" else "yürüyüş")
		"hold":
			if unit_choice >= 0:
				sim.special_order(unit_choice, "hold")
				arena.hint = "Bölük mevcut mevzisini tutacak."
		"recall":
			if unit_choice >= 0:
				sim.special_order(unit_choice, "recall")
				arena.hint = "Bölük yeniden kanada bağlandı."
		"info":
			command_panel.visible = not command_panel.visible
	_update_hud()

func _pause() -> void:
	paused = not paused
	pause_button.text = "▶" if paused else "⏸"

func _process(delta: float) -> void:
	if not paused:
		accumulator += minf(delta, 0.25)
		while accumulator >= 0.1:
			sim.step(0.1)
			accumulator -= 0.1
		arena.queue_redraw()
	hud_timer += delta
	if hud_timer >= 0.4:
		hud_timer = 0.0
		_update_hud()

func _update_hud() -> void:
	status.text = "UÇMAK    DOST %d    DÜŞMAN %d    %ds" % [sim.total_personnel(0), sim.total_personnel(1), roundi(sim.elapsed)]
	if unit_choice >= 0:
		var u: Dictionary = sim.units[unit_choice]
		info.text = "Bölük %d • %s • %d asker • moral %d • %s" % [unit_choice + 1, u["kind"], roundi(u["personnel"]), roundi(u["morale"]), u["order"]]
	else:
		info.text = "%s • %s | %s" % [sim.wings[wing_choice]["name"], sim.wings[wing_choice]["commander"], arena.hint]
	if reports != null:
		reports.text = "İSTİHBARAT / EMİRLER\n\n" + "\n\n".join(sim.reports.slice(0, 5))

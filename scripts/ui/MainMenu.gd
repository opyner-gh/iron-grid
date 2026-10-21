class_name MainMenu
extends Control

## Dieselpunk War-Room Main Menu, Mission Briefing Console (3 Maps),
## and Armored Fighting Walker (AFW) Hangar Codex (6 Mech Types).

var selected_map_idx: int = 0
var selected_chassis_idx: int = 0
var _chassis_keys: Array[String] = ["vanguard", "goliath", "falke", "donner", "kommandant", "moloch"]
var _anim_time: float = 0.0

var _map_buttons: Array[Button] = []
var _chassis_buttons: Array[Button] = []
var _btn_launch: Button
var _btn_quit: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	selected_map_idx = GlobalState.selected_map_index

	# Create Mission Selection Buttons (3 Maps)
	for i in range(GlobalState.maps.size()):
		var m_def: MapDefinition = GlobalState.maps[i]
		var b := Button.new()
		b.text = "%d. %s [%s]" % [i + 1, m_def.map_name, m_def.get_strategy_name()]
		b.custom_minimum_size = Vector2(360, 44)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		var idx := i
		b.pressed.connect(func():
			SoundManager.play("ui_click")
			selected_map_idx = idx
			GlobalState.selected_map_index = idx
			queue_redraw()
		)
		add_child(b)
		_map_buttons.append(b)

	# Create Mech Chassis Codex Buttons (6 Chassis)
	for i in range(_chassis_keys.size()):
		var key: String = _chassis_keys[i]
		var ch: MechData = GlobalState.chassis_catalog[key]
		var b := Button.new()
		b.text = ch.callsign
		b.custom_minimum_size = Vector2(128, 32)
		b.focus_mode = Control.FOCUS_NONE
		var idx := i
		b.pressed.connect(func():
			SoundManager.play("ui_click")
			selected_chassis_idx = idx
			queue_redraw()
		)
		add_child(b)
		_chassis_buttons.append(b)

	# Launch Operation Button
	_btn_launch = Button.new()
	_btn_launch.text = ">> LAUNCH OPERATION // DEPLOY WALKERS [ENTER] <<"
	_btn_launch.custom_minimum_size = Vector2(440, 52)
	_btn_launch.focus_mode = Control.FOCUS_NONE
	_btn_launch.pressed.connect(_on_launch_pressed)
	add_child(_btn_launch)

	# Quit Button
	_btn_quit = Button.new()
	_btn_quit.text = "EXIT TERMINAL"
	_btn_quit.custom_minimum_size = Vector2(140, 36)
	_btn_quit.focus_mode = Control.FOCUS_NONE
	_btn_quit.pressed.connect(func(): get_tree().quit())
	add_child(_btn_quit)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_on_launch_pressed()
		elif event.keycode == KEY_1:
			selected_map_idx = 0
			GlobalState.selected_map_index = 0
		elif event.keycode == KEY_2 and GlobalState.maps.size() > 1:
			selected_map_idx = 1
			GlobalState.selected_map_index = 1
		elif event.keycode == KEY_3 and GlobalState.maps.size() > 2:
			selected_map_idx = 2
			GlobalState.selected_map_index = 2

func _on_launch_pressed() -> void:
	SoundManager.play("ui_confirm")
	GlobalState.selected_map_index = selected_map_idx
	get_tree().change_scene_to_file("res://scenes/Battlefield.tscn")

func _process(delta: float) -> void:
	_anim_time += delta
	_layout_ui()
	queue_redraw()

func _layout_ui() -> void:
	var vp: Vector2 = get_viewport_rect().size
	# Left column: 3 Map Selector buttons
	for i in range(_map_buttons.size()):
		_map_buttons[i].position = Vector2(36, 152 + i * 54)
		_map_buttons[i].modulate = Color(1.0, 0.92, 0.55) if i == selected_map_idx else Color(0.82, 0.85, 0.78)

	# Launch button in center-left below briefing
	_btn_launch.position = Vector2(40, vp.y - 84)
	_btn_quit.position = Vector2(vp.x - 170, 24)

	# Right column: 6 Mech Codex selector buttons (2 rows of 3)
	var right_x: float = vp.x - 456
	for i in range(_chassis_buttons.size()):
		@warning_ignore("integer_division")
		var r: int = i / 3
		var c: int = i % 3
		_chassis_buttons[i].position = Vector2(right_x + c * 138, 152 + r * 40)
		_chassis_buttons[i].modulate = Color(1.0, 0.90, 0.50) if i == selected_chassis_idx else Color(0.80, 0.84, 0.78)

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var vp: Vector2 = get_viewport_rect().size

	# Background Industrial CRT Slate
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.06, 0.07, 0.06), true)

	# Subtle tactical grid lines in background
	for gx in range(0, int(vp.x), 64):
		draw_line(Vector2(gx, 0), Vector2(gx, vp.y), Color(0.11, 0.13, 0.10, 0.45), 1.0)
	for gy in range(0, int(vp.y), 64):
		draw_line(Vector2(0, gy), Vector2(vp.x, gy), Color(0.11, 0.13, 0.10, 0.45), 1.0)

	# Top Title Banner
	var hdr := Rect2(20, 14, vp.x - 40, 88)
	draw_rect(hdr, Color(0.10, 0.12, 0.09, 0.96), true)
	draw_rect(hdr, Color(0.82, 0.64, 0.24), false, 2.5)
	draw_string(font, Vector2(40, 52), "OPERATION: IRON GRID", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.96, 0.80, 0.30))
	draw_string(font, Vector2(42, 82), "DIESELPUNK ISOMETRIC TACTICAL WARFARE // AUTOMATED TRIPLE-TRIAD SKIRMISH RESOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.76, 0.84, 0.72))

	# Left & Center Panel: Theater Selection & Briefing
	var left_panel := Rect2(20, 114, vp.x - 510, vp.y - 132)
	draw_rect(left_panel, Color(0.08, 0.10, 0.08, 0.95), true)
	draw_rect(left_panel, Color(0.45, 0.52, 0.38), false, 1.8)
	draw_string(font, Vector2(36, 140), "SELECT BATTLE ARENA (3 THEATERS OF OPERATION):", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.78, 0.32))

	var map_def: MapDefinition = GlobalState.maps[selected_map_idx]

	# Draw Tactical Minimap Preview on the right half of the Left Panel
	var mini_rect := Rect2(446, 148, left_panel.size.x - 446, 210)
	_draw_minimap_preview(font, mini_rect, map_def)

	# Briefing Details Box below buttons/minimap
	var brief_y: float = 374.0
	draw_line(Vector2(36, brief_y - 10), Vector2(left_panel.position.x + left_panel.size.x - 20, brief_y - 10), Color(0.35, 0.40, 0.30), 1.2)
	draw_string(font, Vector2(36, brief_y + 14), "%s  —  %s" % [map_def.map_name, map_def.subtitle], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.98, 0.86, 0.36))
	draw_string(font, Vector2(36, brief_y + 38), "STRATEGY PROFILE: %s   |   TURN LIMIT: %d TURNS" % [map_def.get_strategy_name(), map_def.turn_limit], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.48, 0.92, 0.56))

	# Multiline briefing text
	draw_multiline_string(
		font,
		Vector2(36, brief_y + 66),
		map_def.briefing_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		left_panel.size.x - 48,
		13,
		-1,
		Color(0.86, 0.88, 0.80)
	)

	draw_string(font, Vector2(36, brief_y + 132), "VICTORY CONDITION: " + map_def.get_victory_condition_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.98, 0.78, 0.32))

	draw_multiline_string(
		font,
		Vector2(36, brief_y + 158),
		map_def.tactical_tip,
		HORIZONTAL_ALIGNMENT_LEFT,
		left_panel.size.x - 48,
		12,
		-1,
		Color(0.68, 0.86, 0.74)
	)

	# Right Panel: Armored Walker Hangar / Codex
	var right_panel := Rect2(vp.x - 474, 114, 454, vp.y - 132)
	_draw_mech_hangar_panel(font, right_panel)

func _draw_minimap_preview(font: Font, rect: Rect2, map_def: MapDefinition) -> void:
	draw_rect(rect, Color(0.05, 0.06, 0.05), true)
	draw_rect(rect, Color(0.38, 0.44, 0.34), false, 1.4)
	draw_string(font, rect.position + Vector2(10, 18), "SATELLITE TERRAIN & ELEVATION RECON (%dx%d):" % [map_def.width, map_def.height], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.84, 0.80, 0.62))

	var cell_w: float = minf((rect.size.x - 24.0) / float(map_def.width), 34.0)
	var cell_h: float = minf((rect.size.y - 36.0) / float(map_def.height), 20.0)
	var ox: float = rect.position.x + (rect.size.x - cell_w * map_def.width) * 0.5
	var oy: float = rect.position.y + 26.0

	for y in range(map_def.height):
		var t_row := map_def.terrain_codes[y].split(" ", false)
		var e_row := map_def.elevation_rows[y].split(" ", false)
		for x in range(map_def.width):
			var code: String = t_row[x] if x < t_row.size() else "P"
			var elev: int = int(e_row[x]) if x < e_row.size() else 1
			var col := Color(0.30, 0.36, 0.24)
			match code:
				"R": col = Color(0.16, 0.36, 0.44)
				"D": col = Color(0.42, 0.40, 0.36)
				"F": col = Color(0.20, 0.28, 0.17)
				"C": col = Color(0.55, 0.50, 0.38)
				"M": col = Color(0.50, 0.48, 0.44)
			col = col.lightened(float(elev - 1) * 0.06)
			var cr := Rect2(ox + x * cell_w, oy + y * cell_h, cell_w - 2, cell_h - 2)
			draw_rect(cr, col, true)
			draw_string(font, cr.position + Vector2(3, 12), "%s%d" % [code, elev], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.9, 0.85, 0.7))

	# Draw spawn markers on minimap
	for sp in map_def.spawns:
		var pos: Vector2i = sp["pos"]
		var fac: int = int(sp["faction"])
		var u_col := Color(0.4, 0.95, 0.45) if fac == 0 else Color(1.0, 0.32, 0.25)
		var center := Vector2(ox + (pos.x + 0.5) * cell_w, oy + (pos.y + 0.5) * cell_h)
		draw_circle(center, 4.5, Color(0.05, 0.05, 0.05))
		draw_circle(center, 3.2, u_col)

func _draw_mech_hangar_panel(font: Font, rect: Rect2) -> void:
	draw_rect(rect, Color(0.08, 0.10, 0.08, 0.95), true)
	draw_rect(rect, Color(0.75, 0.58, 0.24), false, 1.8)

	var x: float = rect.position.x + 18
	var y: float = rect.position.y + 26
	draw_string(font, Vector2(x, y), "ARMORED WALKER HANGAR CODEX (6 CHASSIS):", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.78, 0.32))

	var key: String = _chassis_keys[selected_chassis_idx]
	var mech: MechData = GlobalState.chassis_catalog[key]

	y = rect.position.y + 132
	var port_rect := Rect2(x, y, rect.size.x - 36, 138)
	draw_rect(port_rect, Color(0.04, 0.05, 0.04), true)
	draw_rect(port_rect, Color(0.32, 0.38, 0.28), false, 1.4)

	# Draw both Coalition & Syndicate livery previews side-by-side in the Hangar!
	MechUnit.draw_mech_silhouette(
		self,
		port_rect.position + Vector2(port_rect.size.x * 0.32, port_rect.size.y * 0.80),
		mech.chassis_id,
		MechData.Faction.PLAYER,
		1.95,
		_anim_time
	)
	MechUnit.draw_mech_silhouette(
		self,
		port_rect.position + Vector2(port_rect.size.x * 0.72, port_rect.size.y * 0.80),
		mech.chassis_id,
		MechData.Faction.AI,
		1.95,
		_anim_time + 1.5
	)
	draw_string(font, port_rect.position + Vector2(12, 18), "COALITION LIVERY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.48, 0.90, 0.52))
	draw_string(font, port_rect.position + Vector2(port_rect.size.x - 125, 18), "SYNDICATE LIVERY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.96, 0.38, 0.32))

	y += 156
	draw_string(font, Vector2(x, y), "%s // %s" % [mech.unit_name, mech.chassis_class], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.98, 0.94, 0.84))
	y += 22
	draw_string(
		font,
		Vector2(x, y),
		"HULL ARMOR: %d   |   ARMOR RATING: %d   |   FIREPOWER: %d" % [mech.max_armor, mech.armor_rating, mech.firepower],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color(0.95, 0.80, 0.34)
	)
	y += 20
	draw_string(
		font,
		Vector2(x, y),
		"FUEL CAPACITY: %d   |   GENERATOR REFUEL: +%d/TURN" % [mech.max_fuel, mech.passive_refuel],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color(0.68, 0.88, 0.96)
	)
	y += 22
	draw_multiline_string(
		font,
		Vector2(x, y),
		mech.lore_blurb,
		HORIZONTAL_ALIGNMENT_LEFT,
		rect.size.x - 36,
		12,
		-1,
		Color(0.78, 0.82, 0.74)
	)

	y += 58
	draw_string(font, Vector2(x, y), "CHASSIS EQUIPMENT DECK (3x3 SKIRMISH CARDS):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.80, 0.32))
	y += 10

	for i in range(mech.deck.size()):
		var c: EquipmentCard = mech.deck[i]
		var cr := Rect2(x, y + i * 50, rect.size.x - 36, 44)
		draw_rect(cr, Color(0.12, 0.14, 0.11), true)
		draw_rect(cr, Color(0.45, 0.54, 0.38), false, 1.2)
		draw_string(font, cr.position + Vector2(10, 17), "%d. %s [%s] — %s" % [i + 1, c.card_name, c.category, c.description], HORIZONTAL_ALIGNMENT_LEFT, int(cr.size.x - 16), 11, Color(0.96, 0.94, 0.86))
		var r_str := "RANKS: [ TOP:%s  RIGHT:%s  BOTTOM:%s  LEFT:%s ]  |  DMG: %d  |  SHD: %d" % [
			EquipmentCard.format_rank(c.top),
			EquipmentCard.format_rank(c.right),
			EquipmentCard.format_rank(c.bottom),
			EquipmentCard.format_rank(c.left),
			c.damage_rating,
			c.shield_rating
		]
		draw_string(font, cr.position + Vector2(10, 35), r_str, HORIZONTAL_ALIGNMENT_LEFT, int(cr.size.x - 16), 11, Color(0.72, 0.88, 0.74))

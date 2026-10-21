class_name SkirmishModal
extends Control

## Automated Skirmish Resolver Showdown Screen (Resolution Phase UI)
## Displays Stats-vs-Stats telemetry (Firepower, Armor Rating, Terrain & Elevation Modifiers)
## alongside an animated 3x3 Triple Triad style Equipment Deck clash.

signal resolution_confirmed(result: SkirmishEngine.SkirmishResult)

var current_result: SkirmishEngine.SkirmishResult = null
var _is_active: bool = false
var _anim_time: float = 0.0
var _step_timer: float = 0.0
var _step_interval: float = 0.72
var _current_step_idx: int = -1
var _all_steps_done: bool = false
var _fast_mode: bool = false

# Visual state of the 3x3 board during step-by-step playback
var _vis_board: Array[Dictionary] = []
var _vis_atk_armor: float = 100.0
var _vis_def_armor: float = 100.0
var _atk_flash: float = 0.0
var _def_flash: float = 0.0
var _last_flipped_slots: Array[int] = []
var _flip_anim_t: float = 0.0
var _status_line: String = ""

var _btn_confirm: Button
var _btn_speed: Button
var _btn_skip: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_btn_speed = Button.new()
	_btn_speed.focus_mode = Control.FOCUS_NONE # Space/Enter are handled in _unhandled_input
	_btn_speed.text = "SPEED: 1X"
	_btn_speed.custom_minimum_size = Vector2(130, 38)
	_btn_speed.pressed.connect(_on_speed_pressed)
	add_child(_btn_speed)

	_btn_skip = Button.new()
	_btn_skip.focus_mode = Control.FOCUS_NONE # Space/Enter are handled in _unhandled_input
	_btn_skip.text = "INSTANT RESOLVE"
	_btn_skip.custom_minimum_size = Vector2(160, 38)
	_btn_skip.pressed.connect(_on_skip_pressed)
	add_child(_btn_skip)

	_btn_confirm = Button.new()
	_btn_confirm.focus_mode = Control.FOCUS_NONE # Space/Enter are handled in _unhandled_input
	_btn_confirm.text = "CONFIRM OUTCOME [SPACE]"
	_btn_confirm.custom_minimum_size = Vector2(260, 44)
	_btn_confirm.pressed.connect(_on_confirm_pressed)
	add_child(_btn_confirm)

func start_showdown(result: SkirmishEngine.SkirmishResult) -> void:
	current_result = result
	_is_active = true
	visible = true
	_current_step_idx = -1
	_all_steps_done = false
	_step_timer = 0.15
	_step_interval = 0.32 if _fast_mode else 0.72
	_vis_atk_armor = float(result.atk_armor_before)
	_vis_def_armor = float(result.def_armor_before)
	_atk_flash = 0.0
	_def_flash = 0.0
	_last_flipped_slots.clear()
	_status_line = "INITIATING AUTOMATED DECK CLASH // EVALUATING TERRAIN & ELEVATION..."

	_vis_board.clear()
	for i in range(9):
		_vis_board.append({ "card": null, "owner": -1 })

	_btn_confirm.visible = false
	_btn_skip.visible = true
	_btn_speed.visible = true
	SoundManager.play("radar_lock")
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if _all_steps_done:
				_on_confirm_pressed()
			else:
				_on_skip_pressed()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible or not _is_active or current_result == null:
		return

	_anim_time += delta
	if _atk_flash > 0.0:
		_atk_flash = maxf(0.0, _atk_flash - delta * 3.0)
	if _def_flash > 0.0:
		_def_flash = maxf(0.0, _def_flash - delta * 3.0)
	if _flip_anim_t > 0.0:
		_flip_anim_t = maxf(0.0, _flip_anim_t - delta * 2.5)

	if not _all_steps_done:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_advance_one_step()
			_step_timer = _step_interval

	_layout_buttons()
	queue_redraw()

func _layout_buttons() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var modal_w: float = 1160.0
	var modal_h: float = 690.0
	var mx: float = (vp_size.x - modal_w) * 0.5
	var my: float = (vp_size.y - modal_h) * 0.5

	_btn_speed.position = Vector2(mx + 40, my + modal_h - 56)
	_btn_skip.position = Vector2(mx + 184, my + modal_h - 56)
	_btn_confirm.position = Vector2(mx + (modal_w - 260) * 0.5, my + modal_h - 60)

func _advance_one_step() -> void:
	_current_step_idx += 1
	if _current_step_idx >= current_result.steps.size():
		_finish_all_steps()
		return

	var step: SkirmishEngine.BoutStep = current_result.steps[_current_step_idx]
	_vis_board[step.slot_index] = {
		"card": step.card_placed,
		"owner": step.actor_faction
	}
	_last_flipped_slots = step.flipped_slots.duplicate()
	for f_idx in step.flipped_slots:
		_vis_board[f_idx]["owner"] = step.actor_faction

	if step.flipped_slots.size() > 0:
		_flip_anim_t = 1.0
		SoundManager.play("card_flip")
	else:
		SoundManager.play("card_place")

	if step.atk_damage_dealt > 0:
		_vis_def_armor = maxf(0.0, _vis_def_armor - float(step.atk_damage_dealt))
		_def_flash = 1.0
		SoundManager.play("cannon_fire", randf_range(0.95, 1.08))
	if step.def_damage_dealt > 0:
		_vis_atk_armor = maxf(0.0, _vis_atk_armor - float(step.def_damage_dealt))
		_atk_flash = 1.0
		SoundManager.play("cannon_fire", randf_range(0.85, 0.98))

	_status_line = step.description

func _finish_all_steps() -> void:
	_all_steps_done = true
	for i in range(9):
		var s: SkirmishEngine.BoardSlot = current_result.final_board[i]
		_vis_board[i] = { "card": s.card, "owner": s.owner_faction }
	_vis_atk_armor = float(current_result.atk_armor_after)
	_vis_def_armor = float(current_result.def_armor_after)
	_status_line = current_result.summary_headline
	_btn_skip.visible = false
	_btn_speed.visible = false
	_btn_confirm.visible = true
	if current_result.defender_destroyed or current_result.attacker_destroyed:
		SoundManager.play("mech_destroy")
	else:
		SoundManager.play("ui_confirm")

func _on_speed_pressed() -> void:
	_fast_mode = not _fast_mode
	_btn_speed.text = "SPEED: 2X" if _fast_mode else "SPEED: 1X"
	_step_interval = 0.32 if _fast_mode else 0.72
	SoundManager.play("ui_click")

func _on_skip_pressed() -> void:
	SoundManager.play("ui_click")
	_finish_all_steps()
	queue_redraw()

func _on_confirm_pressed() -> void:
	if not _all_steps_done:
		_finish_all_steps()
		return
	SoundManager.play("ui_confirm")
	_is_active = false
	visible = false
	var res := current_result
	current_result = null
	resolution_confirmed.emit(res)

func _draw() -> void:
	if current_result == null:
		return

	var font: Font = ThemeDB.fallback_font
	var vp_size: Vector2 = get_viewport_rect().size

	# Darkened battlefield backdrop
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.02, 0.03, 0.02, 0.84), true)

	var modal_w: float = 1160.0
	var modal_h: float = 690.0
	var mx: float = (vp_size.x - modal_w) * 0.5
	var my: float = (vp_size.y - modal_h) * 0.5
	var modal_rect := Rect2(mx, my, modal_w, modal_h)

	# Main Steel Frame
	draw_rect(modal_rect, Color(0.09, 0.11, 0.09, 0.98), true)
	draw_rect(modal_rect, Color(0.78, 0.60, 0.24, 0.95), false, 3.0)
	draw_rect(modal_rect.grow(-5), Color(0.28, 0.32, 0.25, 0.8), false, 1.2)

	# Header Banner
	var hdr_rect := Rect2(mx + 8, my + 8, modal_w - 16, 62)
	draw_rect(hdr_rect, Color(0.14, 0.17, 0.13), true)
	draw_rect(hdr_rect, Color(0.78, 0.60, 0.24, 0.7), false, 1.5)
	draw_string(font, Vector2(mx + 24, my + 34), "SKIRMISH RESOLUTION PHASE // AUTOMATED TACTICAL CLASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.95, 0.78, 0.30))
	draw_string(font, Vector2(mx + 24, my + 58), "VECTOR: " + current_result.approach_summary, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.78, 0.86, 0.74))

	# Draw Left Column (Attacker Telemetry & Deck)
	var left_rect := Rect2(mx + 20, my + 80, 310, 520)
	_draw_combatant_column(
		font, left_rect, "ATTACKER", current_result.attacker,
		current_result.from_tile, current_result.atk_effective_firepower,
		current_result.atk_effective_armor, current_result.atk_total_mod_pct,
		current_result.atk_card_edge_mod, int(round(_vis_atk_armor)),
		current_result.total_dmg_to_attacker if _all_steps_done else 0, _atk_flash > 0.0
	)

	# Draw Right Column (Defender Telemetry & Deck)
	var right_rect := Rect2(mx + modal_w - 330, my + 80, 310, 520)
	_draw_combatant_column(
		font, right_rect, "DEFENDER", current_result.defender,
		current_result.target_tile, current_result.def_effective_firepower,
		current_result.def_effective_armor, current_result.def_total_mod_pct,
		current_result.def_card_edge_mod, int(round(_vis_def_armor)),
		current_result.total_dmg_to_defender if _all_steps_done else 0, _def_flash > 0.0
	)

	# Draw Center 3x3 Tactical Clash Matrix
	var center_rect := Rect2(mx + 346, my + 80, 468, 520)
	_draw_tactical_matrix(font, center_rect)

	# Bottom Status / Outcome Ticker
	var status_rect := Rect2(mx + 20, my + 606, modal_w - 40, 26)
	var status_col := Color(0.98, 0.84, 0.32) if _all_steps_done else Color(0.75, 0.92, 0.78)
	draw_string(font, status_rect.position + Vector2(12, 18), _status_line, HORIZONTAL_ALIGNMENT_CENTER, int(status_rect.size.x - 24), 15, status_col)

func _draw_combatant_column(
	font: Font,
	rect: Rect2,
	role_label: String,
	mech: MechData,
	tile: GridTileData,
	eff_fp: int,
	eff_arm: int,
	mod_pct: int,
	edge_mod: int,
	shown_armor: int,
	dmg_taken: int,
	is_flashing: bool
) -> void:
	var is_player: bool = (mech.faction == MechData.Faction.PLAYER)
	var accent := Color(0.45, 0.88, 0.48) if is_player else Color(0.95, 0.34, 0.28)
	draw_rect(rect, Color(0.06, 0.08, 0.06, 0.95), true)
	draw_rect(rect, accent, false, 2.0)

	var x: float = rect.position.x + 14
	var y: float = rect.position.y + 24

	draw_string(font, Vector2(x, y), "%s // %s" % [role_label, "8TH IRON DIV" if is_player else "SYNDICATE RED"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, accent)
	y += 22
	draw_string(font, Vector2(x, y), mech.callsign, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.96, 0.94, 0.86))
	y += 18
	draw_string(font, Vector2(x, y), "%s (%s)" % [mech.unit_name, mech.chassis_class], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.75, 0.68))

	# Mech Blueprint Viewport Box
	var port_rect := Rect2(x, y + 10, rect.size.x - 28, 122)
	draw_rect(port_rect, Color(0.04, 0.05, 0.04), true)
	draw_rect(port_rect, Color(0.25, 0.30, 0.24), false, 1.2)
	MechUnit.draw_mech_silhouette(
		self,
		port_rect.position + Vector2(port_rect.size.x * 0.5, port_rect.size.y * 0.78),
		mech.chassis_id,
		mech.faction,
		1.75,
		_anim_time,
		1.0,
		is_flashing
	)

	if dmg_taken > 0:
		draw_string(font, port_rect.position + Vector2(port_rect.size.x - 86, 24), "-%d DMG" % dmg_taken, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.30, 0.22))

	y += 148

	# Hull Armor Gauge
	var ratio: float = clampf(float(shown_armor) / float(maxi(1, mech.max_armor)), 0.0, 1.0)
	draw_string(font, Vector2(x, y), "HULL ARMOR: %d / %d" % [shown_armor, mech.max_armor], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.92, 0.90, 0.82))
	y += 8
	var bar_w: float = rect.size.x - 28
	draw_rect(Rect2(x, y, bar_w, 14), Color(0.15, 0.16, 0.15), true)
	var bar_col := Color(0.35, 0.88, 0.45) if ratio > 0.5 else (Color(0.95, 0.72, 0.22) if ratio > 0.25 else Color(0.95, 0.24, 0.20))
	draw_rect(Rect2(x, y, bar_w * ratio, 14), bar_col, true)
	draw_rect(Rect2(x, y, bar_w, 14), Color(0.5, 0.52, 0.46), false, 1.0)

	y += 30
	# Stats vs Stats Breakdown
	var stat_box := Rect2(x, y, bar_w, 114)
	draw_rect(stat_box, Color(0.10, 0.12, 0.10), true)
	draw_rect(stat_box, Color(0.30, 0.35, 0.28), false, 1.0)

	var sx: float = x + 10
	var sy: float = y + 20
	draw_string(font, Vector2(sx, sy), "NODE TERRAIN: %s (%dm)" % [tile.get_terrain_name(), tile.get_elevation_meters()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.88, 0.78))
	sy += 21
	var mod_col := Color(0.45, 0.95, 0.55) if mod_pct >= 0 else Color(1.0, 0.42, 0.35)
	draw_string(font, Vector2(sx, sy), "TERRAIN + ELEV MOD: %+d%%" % mod_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, mod_col)
	sy += 21
	draw_string(font, Vector2(sx, sy), "FIREPOWER: %d  ->  EFF: %d" % [mech.firepower, eff_fp], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.96, 0.80, 0.35))
	sy += 21
	draw_string(font, Vector2(sx, sy), "ARMOR RATING: %d  ->  EFF: %d" % [mech.armor_rating, eff_arm], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.68, 0.86, 0.96))
	sy += 21
	var edge_str := "%+d TO ALL CARD EDGES" % edge_mod if edge_mod != 0 else "+0 STANDARD CARD EDGES"
	draw_string(font, Vector2(sx, sy), "DECK MOD: " + edge_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, mod_col)

	y += 130
	draw_string(font, Vector2(x, y), "EQUIPPED TACTICAL DECK (3 CARDS):", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.82, 0.80, 0.72))
	y += 8
	for c_idx in range(mech.deck.size()):
		var c: EquipmentCard = mech.deck[c_idx]
		var strip_rect := Rect2(x, y + c_idx * 40, bar_w, 35)
		draw_rect(strip_rect, Color(0.13, 0.15, 0.13), true)
		draw_rect(strip_rect, accent.darkened(0.25), false, 1.2)
		draw_string(font, strip_rect.position + Vector2(8, 15), "%d. %s" % [c_idx + 1, c.card_name], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.93, 0.85))
		var ranks_txt := "[N:%s E:%s S:%s W:%s] DMG:%d SHD:%d" % [
			EquipmentCard.format_rank(clampi(c.top + edge_mod, 1, 10)),
			EquipmentCard.format_rank(clampi(c.right + edge_mod, 1, 10)),
			EquipmentCard.format_rank(clampi(c.bottom + edge_mod, 1, 10)),
			EquipmentCard.format_rank(clampi(c.left + edge_mod, 1, 10)),
			c.damage_rating,
			c.shield_rating
		]
		draw_string(font, strip_rect.position + Vector2(8, 30), ranks_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.84, 0.72))

func _draw_tactical_matrix(font: Font, rect: Rect2) -> void:
	draw_rect(rect, Color(0.05, 0.06, 0.05, 0.96), true)
	draw_rect(rect, Color(0.55, 0.48, 0.28), false, 1.8)

	draw_string(font, rect.position + Vector2(18, 26), "3x3 TRIPLE-TRIAD EQUIPMENT MATRIX", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.80, 0.34))

	var cell_w: float = 132.0
	var cell_h: float = 132.0
	var gap: float = 12.0
	var grid_w: float = cell_w * 3.0 + gap * 2.0
	var start_x: float = rect.position.x + (rect.size.x - grid_w) * 0.5
	var start_y: float = rect.position.y + 42.0

	var p_count: int = 0
	var e_count: int = 0

	for idx in range(9):
		@warning_ignore("integer_division")
		var r: int = idx / 3
		var c: int = idx % 3
		var cx: float = start_x + c * (cell_w + gap)
		var cy: float = start_y + r * (cell_h + gap)
		var slot_rect := Rect2(cx, cy, cell_w, cell_h)

		var entry: Dictionary = _vis_board[idx]
		var card: EquipmentCard = entry["card"]
		var owner_fac: int = entry["owner"]

		if card == null:
			draw_rect(slot_rect, Color(0.09, 0.11, 0.09), true)
			draw_rect(slot_rect, Color(0.22, 0.26, 0.22), false, 1.2)
			draw_string(font, slot_rect.position + Vector2(46, 70), "SLOT %d" % (idx + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.32, 0.36, 0.32))
		else:
			if owner_fac == MechData.Faction.PLAYER:
				p_count += 1
			else:
				e_count += 1
			var is_player_card: bool = (owner_fac == MechData.Faction.PLAYER)
			var bg_col := Color(0.16, 0.26, 0.17) if is_player_card else Color(0.28, 0.14, 0.13)
			var border_col := Color(0.45, 0.92, 0.50) if is_player_card else Color(0.96, 0.35, 0.28)
			if _last_flipped_slots.has(idx) and _flip_anim_t > 0.0:
				border_col = Color(1.0, 0.92, 0.35)
				bg_col = bg_col.lightened(0.22 * _flip_anim_t)

			draw_rect(slot_rect, bg_col, true)
			draw_rect(slot_rect, border_col, false, 2.5)

			# Card Name Header
			draw_rect(Rect2(cx + 2, cy + 2, cell_w - 4, 22), border_col.darkened(0.55), true)
			var short_title := card.card_name.substr(0, 15)
			draw_string(font, Vector2(cx + 6, cy + 17), short_title, HORIZONTAL_ALIGNMENT_LEFT, int(cell_w - 12), 11, Color(0.98, 0.96, 0.88))

			# Central Triple Triad Directional Rank Diamond
			var d_center := slot_rect.position + Vector2(cell_w * 0.5, cell_h * 0.54)
			draw_circle(d_center, 31.0, Color(0.07, 0.08, 0.07, 0.9))
			draw_arc(d_center, 31.0, 0, TAU, 24, border_col, 1.5)

			var rank_col := Color(1.0, 0.90, 0.45)
			# Top (North)
			draw_string(font, d_center + Vector2(-5, -14), EquipmentCard.format_rank(card.top), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, rank_col)
			# Bottom (South)
			draw_string(font, d_center + Vector2(-5, 24), EquipmentCard.format_rank(card.bottom), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, rank_col)
			# Left (West)
			draw_string(font, d_center + Vector2(-23, 5), EquipmentCard.format_rank(card.left), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, rank_col)
			# Right (East)
			draw_string(font, d_center + Vector2(14, 5), EquipmentCard.format_rank(card.right), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, rank_col)

			# Bottom Damage / Shield strip
			draw_string(font, Vector2(cx + 8, cy + cell_h - 8), "DMG:%d  SHD:%d" % [card.damage_rating, card.shield_rating], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.84, 0.86, 0.78))

	# Matrix Control Tally Bar at bottom of center panel
	var tally_y: float = start_y + 3.0 * (cell_h + gap) + 16.0
	draw_string(
		font,
		Vector2(rect.position.x + 24, tally_y),
		"COALITION CARDS: %d     vs     SYNDICATE CARDS: %d" % [p_count, e_count],
		HORIZONTAL_ALIGNMENT_CENTER,
		int(rect.size.x - 48),
		15,
		Color(0.92, 0.88, 0.74)
	)

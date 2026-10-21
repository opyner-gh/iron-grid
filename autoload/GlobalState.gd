extends Node

## GlobalState Autoload
## Manages global campaign/mission selection, turn phase state, mech & card databases,
## map arena definitions, and combat telemetry logs.

enum TurnPhase {
	PLAYER_PHASE = 0,
	RESOLUTION_PHASE = 1,
	AI_PHASE = 2,
	GAME_OVER = 3
}

signal phase_changed(new_phase: TurnPhase, turn_num: int)
signal log_added(entry: String)

var current_phase: TurnPhase = TurnPhase.PLAYER_PHASE
var turn_number: int = 1
var selected_map_index: int = 0
var last_battle_winner: int = -1 # -1 = None, 0 = Player, 1 = AI
var last_battle_reason: String = ""

var card_catalog: Dictionary = {}
var chassis_catalog: Dictionary = {}
var maps: Array[MapDefinition] = []
var combat_log: Array[String] = []

func _ready() -> void:
	_init_card_catalog()
	_init_chassis_catalog()
	_init_maps()

func reset_battle_state() -> void:
	current_phase = TurnPhase.PLAYER_PHASE
	turn_number = 1
	last_battle_winner = -1
	last_battle_reason = ""
	combat_log.clear()
	add_log("SYSTEM BOOT // OPERATION: IRON GRID TACTICAL LINK ESTABLISHED.")

func set_phase(new_phase: TurnPhase) -> void:
	current_phase = new_phase
	phase_changed.emit(current_phase, turn_number)

func add_log(msg: String) -> void:
	var prefix := "[T%02d] " % turn_number
	var full_msg := prefix + msg
	combat_log.append(full_msg)
	if combat_log.size() > 60:
		combat_log.pop_front()
	log_added.emit(full_msg)

func get_phase_name() -> String:
	match current_phase:
		TurnPhase.PLAYER_PHASE:
			return "PLAYER COMMAND PHASE"
		TurnPhase.RESOLUTION_PHASE:
			return "SKIRMISH RESOLUTION PHASE"
		TurnPhase.AI_PHASE:
			return "SYNDICATE AI PHASE"
		TurnPhase.GAME_OVER:
			return "OPERATION CONCLUDED"
	return "UNKNOWN"

func _init_card_catalog() -> void:
	# Directional ranks: Top, Right, Bottom, Left (1..10 where 10 displays as 'A')
	card_catalog["kwk_88"] = EquipmentCard.new(
		"kwk_88", "88mm KwK AP-Shell", "BALLISTIC",
		7, 6, 4, 6, 22, 8, "High-velocity armor-piercing cannon shell."
	)
	card_catalog["krupp_plate"] = EquipmentCard.new(
		"krupp_plate", "Sloped Krupp Plate", "ARMOR",
		5, 7, 7, 5, 12, 18, "Angled face-hardened steel hull deflectors."
	)
	card_catalog["coax_mg"] = EquipmentCard.new(
		"coax_mg", "Twin MG-42 Salvo", "BALLISTIC",
		6, 5, 6, 5, 16, 8, "Suppressive rapid-fire tracer barrage."
	)
	card_catalog["morser_210"] = EquipmentCard.new(
		"morser_210", "210mm Siege Howitzer", "ARTILLERY",
		9, 8, 3, 7, 30, 6, "Devastating heavy bunker-busting shell."
	)
	card_catalog["ferro_bulkhead"] = EquipmentCard.new(
		"ferro_bulkhead", "Ferro-Bunker Bulkhead", "ARMOR",
		6, 8, 9, 6, 14, 24, "Massive dreadnought frontal armor slab."
	)
	card_catalog["flak_38"] = EquipmentCard.new(
		"flak_38", "Quad Flak-38 Battery", "BALLISTIC",
		7, 6, 5, 7, 20, 10, "Multi-barrel autocannon point defense."
	)
	card_catalog["autocannon_50"] = EquipmentCard.new(
		"autocannon_50", "50mm Rapid Autocannon", "BALLISTIC",
		6, 8, 4, 5, 18, 6, "Lightweight high-cyclic flanker cannon."
	)
	card_catalog["gyro_thruster"] = EquipmentCard.new(
		"gyro_thruster", "Gyro-Flank Thrusters", "TACTICAL",
		4, 7, 6, 8, 15, 14, "Steam-boosted lateral evasion maneuver."
	)
	card_catalog["recon_lock"] = EquipmentCard.new(
		"recon_lock", "Optical Rangefinder", "TACTICAL",
		8, 5, 5, 6, 17, 10, "Precision stereoscopic targeting telemetry."
	)
	card_catalog["rocket_pod"] = EquipmentCard.new(
		"rocket_pod", "Nebelwerfer Rocket Pod", "ARTILLERY",
		9, 6, 4, 8, 28, 6, "Saturation high-angle rocket artillery barrage."
	)
	card_catalog["plunging_comp"] = EquipmentCard.new(
		"plunging_comp", "Elevation Ballistics", "TACTICAL",
		8, 7, 5, 5, 21, 10, "Analog fire-control computer for high ground."
	)
	card_catalog["anchor_strut"] = EquipmentCard.new(
		"anchor_strut", "Quad Anchor Struts", "ARMOR",
		5, 6, 8, 6, 13, 16, "Hydraulic outriggers that brace against recoil."
	)
	card_catalog["enigma_ecm"] = EquipmentCard.new(
		"enigma_ecm", "Enigma ECM Scrambler", "TACTICAL",
		7, 8, 6, 7, 19, 15, "Broad-spectrum radio & targeting jammer."
	)
	card_catalog["cmd_override"] = EquipmentCard.new(
		"cmd_override", "Command Uplink", "TACTICAL",
		6, 7, 7, 7, 18, 14, "Tactical battle-net coordination pulse."
	)
	card_catalog["assault_105"] = EquipmentCard.new(
		"assault_105", "105mm StuH Howitzer", "BALLISTIC",
		8, 6, 5, 6, 24, 9, "Direct-fire assault gun for urban combat."
	)
	card_catalog["thermite_lance"] = EquipmentCard.new(
		"thermite_lance", "Thermite Flame Lance", "THERMAL",
		8, 9, 4, 6, 27, 7, "Superheated plasma-diesel incinerator jet."
	)
	card_catalog["pile_bunker"] = EquipmentCard.new(
		"pile_bunker", "Hydraulic Pile-Bunker", "BALLISTIC",
		9, 5, 6, 8, 29, 8, "Explosive-driven tungsten spike ram."
	)
	card_catalog["ablative_shield"] = EquipmentCard.new(
		"ablative_shield", "Reactive Shield Wall", "ARMOR",
		6, 7, 8, 7, 14, 20, "Explosive reactive armor bricks."
	)

func _init_chassis_catalog() -> void:
	# 1. Vanguard (Medium Assault Walker)
	var vanguard := MechData.new(
		"vanguard", "KPZ-09 Sturmjäger", "VANGUARD", "vanguard", "Medium Assault Walker",
		MechData.Faction.PLAYER, Vector2i.ZERO,
		110, 30, 34, 13, 0, 5,
		"Backbone bipedal walker of the 8th Iron Division. Balanced Krupp armor, 88mm cannon, and dependable diesel-turbine fuel economy across all terrain."
	)
	vanguard.deck = [
		card_catalog["kwk_88"].duplicate_card(),
		card_catalog["krupp_plate"].duplicate_card(),
		card_catalog["coax_mg"].duplicate_card()
	]
	chassis_catalog["vanguard"] = vanguard

	# 2. Goliath (Super-Heavy Dreadnought)
	var goliath := MechData.new(
		"goliath", "VK-100 Siegebreaker", "GOLIATH", "goliath", "Super-Heavy Dreadnought",
		MechData.Faction.PLAYER, Vector2i.ZERO,
		155, 44, 46, 10, 1, 4,
		"Towering fortress mech armed with a 210mm siege mortar. Nearly impervious in frontal duels, but guzzles fuel off-road. Keep it on roads or cities."
	)
	goliath.deck = [
		card_catalog["morser_210"].duplicate_card(),
		card_catalog["ferro_bulkhead"].duplicate_card(),
		card_catalog["flak_38"].duplicate_card()
	]
	chassis_catalog["goliath"] = goliath

	# 3. Falke (Light Recon Strider)
	var falke := MechData.new(
		"falke", "Sd.Kfz-22 Spähfalke", "FALKE", "falke", "Light Recon Strider",
		MechData.Faction.PLAYER, Vector2i.ZERO,
		85, 21, 28, 17, -1, 6,
		"High-mobility scout strider fitted with amphibious seals and high-capacity fuel tanks. Excels at crossing rivers, flanking artillery, and capturing cities."
	)
	falke.amphibious_gear = true
	falke.deck = [
		card_catalog["autocannon_50"].duplicate_card(),
		card_catalog["gyro_thruster"].duplicate_card(),
		card_catalog["recon_lock"].duplicate_card()
	]
	chassis_catalog["falke"] = falke

	# 4. Donner (Quadruped Siege Artillery)
	var donner := MechData.new(
		"donner", "SPG-88 Spinne", "DONNER", "donner", "Quadruped Mountain Walker",
		MechData.Faction.PLAYER, Vector2i.ZERO,
		98, 26, 43, 12, 0, 5,
		"Four-legged spider chassis engineered for climbing steep mountain crags. Unleashes devastating plunging rocket salvos from elevated ridges."
	)
	donner.mountain_gear = true
	donner.deck = [
		card_catalog["rocket_pod"].duplicate_card(),
		card_catalog["plunging_comp"].duplicate_card(),
		card_catalog["anchor_strut"].duplicate_card()
	]
	chassis_catalog["donner"] = donner

	# 5. Kommandant (Tactical Command Mech)
	var kommandant := MechData.new(
		"kommandant", "Befehls-IV Kaiserstuhl", "KOMMANDANT", "kommandant", "Tactical Command Walker",
		MechData.Faction.PLAYER, Vector2i.ZERO,
		120, 34, 36, 14, 0, 5,
		"Command-and-control walker equipped with Enigma ECM jammers and well-rounded directional card ranks that excel at flipping enemy decks."
	)
	kommandant.deck = [
		card_catalog["enigma_ecm"].duplicate_card(),
		card_catalog["cmd_override"].duplicate_card(),
		card_catalog["assault_105"].duplicate_card()
	]
	chassis_catalog["kommandant"] = kommandant

	# 6. Moloch (Close-Quarters Siege Brawler)
	var moloch := MechData.new(
		"moloch", "Sturm-V Brenner", "MOLOCH", "moloch", "Heavy Urban Brawler",
		MechData.Faction.PLAYER, Vector2i.ZERO,
		135, 38, 41, 12, 0, 5,
		"Brutal close-combat walker armed with a thermite projector and hydraulic pile-bunker. Built to storm fortified cities and crush entrenched foes."
	)
	moloch.deck = [
		card_catalog["thermite_lance"].duplicate_card(),
		card_catalog["pile_bunker"].duplicate_card(),
		card_catalog["ablative_shield"].duplicate_card()
	]
	chassis_catalog["moloch"] = moloch

func create_mech_instance(chassis_id: String, faction: MechData.Faction, callsign: String, pos: Vector2i, unique_suffix: String = "") -> MechData:
	var template: MechData = chassis_catalog.get(chassis_id, chassis_catalog["vanguard"])
	var inst := template.duplicate_mech()
	inst.unit_id = "%s_%s_%s" % [chassis_id, "P" if faction == MechData.Faction.PLAYER else "E", unique_suffix]
	inst.faction = faction
	inst.callsign = callsign
	inst.grid_pos = pos
	inst.prev_grid_pos = pos
	return inst

func _init_maps() -> void:
	maps.clear()

	# =========================================================================
	# MAP 1: OPERATION IRON BRIDGE — PITCHED BATTLE (10x8)
	# Terrain codes: P=Plain, D=Road, R=River, F=Forest/Trench, C=City, M=Mountain
	# =========================================================================
	var map1 := MapDefinition.new()
	map1.map_id = "iron_bridge"
	map1.map_name = "OPERATION: IRON BRIDGE"
	map1.subtitle = "Sector 04 // Rhine-Fulda Contested Crossing"
	map1.strategy_mode = MapDefinition.StrategyMode.PITCHED_BATTLE
	map1.turn_limit = 10
	map1.width = 10
	map1.height = 8
	map1.briefing_text = (
		"PITCHED BATTLE: Both forces converge on the industrial river valley of Sector 04. " +
		"Two reinforced stone bridges carry the main transit roads across the river. " +
		"Seize the central bridgehead cities or use the northern and southern mountain ridges to rain plunging fire onto enemies bogged down in the river fords."
	)
	map1.tactical_tip = (
		"TACTICAL ADVISORY: Rivers cost 4 Fuel and impose -15% ATK / -15% DEF. " +
		"Use Roads (1 Fuel) to rush Heavy Walkers into Central Cities (+25% DEF, +Fuel/Repair), and position Quad Artillery on Elevation 3 Ridges!"
	)
	map1.terrain_codes = PackedStringArray([
		"M M F P R R P F M M",
		"F P P C R R C P P F",
		"D D D D D D D D D D",
		"P F P P R R P P F P",
		"P F P P R R P P F P",
		"D D D D D D D D D D",
		"F P P C R R C P P F",
		"M M F P R R P F M M"
	])
	map1.elevation_rows = PackedStringArray([
		"3 3 2 1 0 0 1 2 3 3",
		"2 1 1 2 0 0 2 1 1 2",
		"1 1 1 1 1 1 1 1 1 1",
		"1 2 1 1 0 0 1 1 2 1",
		"1 2 1 1 0 0 1 1 2 1",
		"1 1 1 1 1 1 1 1 1 1",
		"2 1 1 2 0 0 2 1 1 2",
		"3 3 2 1 0 0 1 2 3 3"
	])
	map1.objectives = [
		{ "pos": Vector2i(3, 1), "label": "North West Bridgehead", "owner": 0 },
		{ "pos": Vector2i(6, 1), "label": "North East Bridgehead", "owner": 1 },
		{ "pos": Vector2i(3, 6), "label": "South West Bridgehead", "owner": 0 },
		{ "pos": Vector2i(6, 6), "label": "South East Bridgehead", "owner": 1 }
	]
	map1.spawns = [
		# Player Coalition Forces (West Side)
		{ "chassis": "vanguard", "callsign": "IRON-1 (Sturmjäger)", "pos": Vector2i(1, 2), "faction": 0 },
		{ "chassis": "goliath",  "callsign": "TITAN-2 (Siegebreaker)", "pos": Vector2i(0, 5), "faction": 0 },
		{ "chassis": "falke",    "callsign": "SWIFT-3 (Spähfalke)", "pos": Vector2i(2, 3), "faction": 0 },
		{ "chassis": "donner",   "callsign": "CRAG-4 (Spinne)", "pos": Vector2i(1, 0), "faction": 0 },
		# AI Syndicate Forces (East Side)
		{ "chassis": "vanguard", "callsign": "ROTE-1 (Sturmjäger)", "pos": Vector2i(8, 2), "faction": 1 },
		{ "chassis": "moloch",   "callsign": "GLUT-2 (Brenner)", "pos": Vector2i(8, 5), "faction": 1 },
		{ "chassis": "falke",    "callsign": "JÄGER-3 (Spähfalke)", "pos": Vector2i(7, 4), "faction": 1 },
		{ "chassis": "donner",   "callsign": "SPINNE-4 (Artillery)", "pos": Vector2i(8, 7), "faction": 1 }
	]
	maps.append(map1)

	# =========================================================================
	# MAP 2: BASTION REDOUBT — FORTIFIED DEFENSE (10x8)
	# =========================================================================
	var map2 := MapDefinition.new()
	map2.map_id = "bastion_redoubt"
	map2.map_name = "BASTION REDOUBT"
	map2.subtitle = "Sector 09 // Citadel Höhenburg Defense"
	map2.strategy_mode = MapDefinition.StrategyMode.DEFENSE
	map2.turn_limit = 8
	map2.width = 10
	map2.height = 8
	map2.briefing_text = (
		"FORTIFIED DEFENSE: A numerically superior Kriegs-Syndikat armored column is storming up the Western valley toward Citadel Höhenburg. " +
		"Your defenders command the Eastern mountain plateau (Elevation 3-4). Hold the Citadel Cities until Turn 8 or annihilate the assault wave!"
	)
	map2.tactical_tip = (
		"TACTICAL ADVISORY: Each level of Elevation advantage grants +12% Firepower & +10% Armor deflection! " +
		"Let enemy walkers burn fuel climbing the mountain switchbacks or wading the moat river, then counter-strike from Elevation 3-4!"
	)
	map2.terrain_codes = PackedStringArray([
		"P P F R P M M M M M",
		"D D D D D D C M C M",
		"P F P R P F M M M M",
		"P P P R F P M C M M",
		"P P P R F P M C M M",
		"P F P R P F M M M M",
		"D D D D D D C M C M",
		"P P F R P M M M M M"
	])
	map2.elevation_rows = PackedStringArray([
		"1 1 1 0 2 3 3 4 4 4",
		"1 1 1 1 2 2 3 3 4 4",
		"1 2 1 0 2 2 3 3 4 4",
		"1 1 1 0 2 2 3 4 4 4",
		"1 1 1 0 2 2 3 4 4 4",
		"1 2 1 0 2 2 3 3 4 4",
		"1 1 1 1 2 2 3 3 4 4",
		"1 1 1 0 2 3 3 4 4 4"
	])
	map2.objectives = [
		{ "pos": Vector2i(6, 1), "label": "North Bastion Gate", "owner": 0 },
		{ "pos": Vector2i(6, 6), "label": "South Bastion Gate", "owner": 0 },
		{ "pos": Vector2i(7, 3), "label": "Citadel Upper Core", "owner": 0 },
		{ "pos": Vector2i(7, 4), "label": "Citadel Lower Core", "owner": 0 }
	]
	map2.spawns = [
		# Player Defenders on High Ground (East Citadel)
		{ "chassis": "goliath",    "callsign": "BASTION-1 (Dreadnought)", "pos": Vector2i(6, 1), "faction": 0 },
		{ "chassis": "donner",     "callsign": "EYRIE-2 (Spinne)", "pos": Vector2i(6, 3), "faction": 0 },
		{ "chassis": "kommandant", "callsign": "AEGIS-3 (Command)", "pos": Vector2i(6, 4), "faction": 0 },
		{ "chassis": "vanguard",   "callsign": "WATCH-4 (Sturmjäger)", "pos": Vector2i(6, 6), "faction": 0 },
		# AI Assault Wave (West Valley - 5 Units!)
		{ "chassis": "moloch",     "callsign": "STURM-1 (Brenner)", "pos": Vector2i(2, 1), "faction": 1 },
		{ "chassis": "vanguard",   "callsign": "STURM-2 (Sturmjäger)", "pos": Vector2i(1, 2), "faction": 1 },
		{ "chassis": "goliath",    "callsign": "KOLOS-3 (Siegebreaker)", "pos": Vector2i(1, 6), "faction": 1 },
		{ "chassis": "falke",      "callsign": "SPÄH-4 (Recon)", "pos": Vector2i(2, 4), "faction": 1 },
		{ "chassis": "donner",     "callsign": "FEUER-5 (Spinne)", "pos": Vector2i(0, 4), "faction": 1 }
	]
	maps.append(map2)

	# =========================================================================
	# MAP 3: BREAKTHROUGH AT KESSEL-9 — BLITZKRIEG OFFENSE (10x8)
	# =========================================================================
	var map3 := MapDefinition.new()
	map3.map_id = "kessel_breakthrough"
	map3.map_name = "BREAKTHROUGH AT KESSEL-9"
	map3.subtitle = "Sector 12 // Armored Spearhead Assault"
	map3.strategy_mode = MapDefinition.StrategyMode.OFFENSE
	map3.turn_limit = 10
	map3.width = 10
	map3.height = 8
	map3.briefing_text = (
		"BLITZKRIEG OFFENSE: Syndicate command has fortified the Kessel-9 rail nexus. " +
		"Lead an armored spearhead of five mobile walkers down the central highway or around the river/mountain flanks to capture the Syndicate HQ Bunker at (8,3) or (8,4) before Turn 10!"
	)
	map3.tactical_tip = (
		"TACTICAL ADVISORY: Don't attack entrenched City/Mountain defenders from low rivers! " +
		"Use Falke Striders and Donner Mountain Walkers to seize the flanking ridges (Elevation 3), then strike the HQ Bunker with Moloch & Kommandant units!"
	)
	map3.terrain_codes = PackedStringArray([
		"P D D F M M F P M M",
		"P D P P F C F P C M",
		"P P P R R F P P F M",
		"D D D D D C D D C M",
		"D D D D D C D D C M",
		"P P P R R F P P F M",
		"P D P P F C F P C M",
		"P D D F M M F P M M"
	])
	map3.elevation_rows = PackedStringArray([
		"1 1 2 2 3 3 2 2 3 4",
		"1 1 1 2 2 2 2 2 3 3",
		"1 1 1 0 0 2 2 2 3 3",
		"1 1 1 1 1 2 2 2 3 4",
		"1 1 1 1 1 2 2 2 3 4",
		"1 1 1 0 0 2 2 2 3 3",
		"1 1 1 2 2 2 2 2 3 3",
		"1 1 2 2 3 3 2 2 3 4"
	])
	map3.objectives = [
		{ "pos": Vector2i(5, 3), "label": "Outer Gate North", "owner": 1 },
		{ "pos": Vector2i(5, 4), "label": "Outer Gate South", "owner": 1 },
		{ "pos": Vector2i(8, 3), "label": "Syndicate HQ North", "owner": 1 },
		{ "pos": Vector2i(8, 4), "label": "Syndicate HQ South", "owner": 1 }
	]
	map3.spawns = [
		# Player Strike Force (5 Units on West Spearhead)
		{ "chassis": "moloch",     "callsign": "SPEAR-1 (Brenner)", "pos": Vector2i(1, 3), "faction": 0 },
		{ "chassis": "kommandant", "callsign": "COMMAND-2 (Kaiserstuhl)", "pos": Vector2i(1, 4), "faction": 0 },
		{ "chassis": "vanguard",   "callsign": "LANCE-3 (Sturmjäger)", "pos": Vector2i(1, 1), "faction": 0 },
		{ "chassis": "falke",      "callsign": "GHOST-4 (Spähfalke)", "pos": Vector2i(1, 6), "faction": 0 },
		{ "chassis": "donner",     "callsign": "THUNDER-5 (Spinne)", "pos": Vector2i(0, 0), "faction": 0 },
		# AI Entrenched Defense Line (4 Units guarding Gates & HQ)
		{ "chassis": "vanguard",   "callsign": "WACHE-1 (Gate Guard)", "pos": Vector2i(5, 3), "faction": 1 },
		{ "chassis": "moloch",     "callsign": "WACHE-2 (Bunker Brawler)", "pos": Vector2i(5, 4), "faction": 1 },
		{ "chassis": "donner",     "callsign": "FLAK-3 (Ridge Artillery)", "pos": Vector2i(5, 1), "faction": 1 },
		{ "chassis": "goliath",    "callsign": "KOMMANDANTUR-4 (HQ Boss)", "pos": Vector2i(8, 3), "faction": 1 }
	]
	maps.append(map3)


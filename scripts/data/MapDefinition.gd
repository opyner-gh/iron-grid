class_name MapDefinition
extends RefCounted

## Defines a complete Battle Arena map including its strategic mode (Offense, Defense, Pitched Battle),
## grid layout of terrain & elevations, objective nodes, and starting unit deployments.

enum StrategyMode {
	PITCHED_BATTLE = 0,
	DEFENSE = 1,
	OFFENSE = 2
}

var map_id: String = ""
var map_name: String = ""
var subtitle: String = ""
var strategy_mode: StrategyMode = StrategyMode.PITCHED_BATTLE
var turn_limit: int = 10
var briefing_text: String = ""
var tactical_tip: String = ""

var width: int = 10
var height: int = 8

# 2D arrays or dictionaries indexed by Vector2i
var terrain_codes: PackedStringArray = PackedStringArray() # Row strings e.g. "P P R C M ..."
var elevation_rows: PackedStringArray = PackedStringArray() # Row strings e.g. "1 1 0 2 3 ..."

# Array of Dictionary: { "pos": Vector2i, "label": String, "owner": int }
var objectives: Array[Dictionary] = []

# Array of Dictionary: { "chassis": String, "callsign": String, "pos": Vector2i, "faction": int }
var spawns: Array[Dictionary] = []

func get_strategy_name() -> String:
	match strategy_mode:
		StrategyMode.PITCHED_BATTLE:
			return "PITCHED BATTLE"
		StrategyMode.DEFENSE:
			return "FORTIFIED DEFENSE"
		StrategyMode.OFFENSE:
			return "BLITZKRIEG OFFENSE"
	return "TACTICAL ENGAGEMENT"

func get_victory_condition_text() -> String:
	match strategy_mode:
		StrategyMode.PITCHED_BATTLE:
			return "Destroy all Syndicate mechs OR control majority of Objective Cities by Turn %d." % turn_limit
		StrategyMode.DEFENSE:
			return "Hold the Citadel Command Node until Turn %d ends OR eliminate all attackers." % turn_limit
		StrategyMode.OFFENSE:
			return "Capture the Syndicate HQ Bunker OR destroy all enemy defenders within %d Turns." % turn_limit
	return "Eliminate enemy forces."


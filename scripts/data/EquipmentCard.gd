class_name EquipmentCard
extends RefCounted

## Represents a Tactical Equipment / Weapon Card in a Mech's Deck for the Skirmish Resolver.
## Inspired by Triple Triad directional ranks (Top, Right, Bottom, Left: 1..10 where 10 = 'A')
## combined with dieselpunk mech hardpoint telemetry.

var card_id: String = ""
var card_name: String = ""
var category: String = "BALLISTIC" # BALLISTIC, ARTILLERY, ARMOR, TACTICAL, THERMAL
var top: int = 5
var right: int = 5
var bottom: int = 5
var left: int = 5
var damage_rating: int = 18
var shield_rating: int = 8
var description: String = ""

func _init(
	p_id: String = "",
	p_name: String = "",
	p_cat: String = "BALLISTIC",
	p_top: int = 5,
	p_right: int = 5,
	p_bottom: int = 5,
	p_left: int = 5,
	p_dmg: int = 18,
	p_shd: int = 8,
	p_desc: String = ""
) -> void:
	card_id = p_id
	card_name = p_name
	category = p_cat
	top = p_top
	right = p_right
	bottom = p_bottom
	left = p_left
	damage_rating = p_dmg
	shield_rating = p_shd
	description = p_desc

func duplicate_card() -> EquipmentCard:
	return EquipmentCard.new(
		card_id, card_name, category, top, right, bottom, left, damage_rating, shield_rating, description
	)

static func format_rank(val: int) -> String:
	if val >= 10:
		return "A"
	return str(maxi(1, val))

func get_total_power() -> int:
	return top + right + bottom + left


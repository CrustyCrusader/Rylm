extends Node
class_name FactionComponent

# Faction relationships and reputation system
var character: BaseCharacter3D

# Current faction and relationships
@export var primary_faction: String = "neutral"
var faction_relationships: Dictionary = {}  # faction_name: reputation_value
var allies: Array[String] = []
var enemies: Array[String] = []

# Diplomatic states
enum DiplomaticState { NEUTRAL, FRIENDLY, HOSTILE, ALLIED, AT_WAR }
var diplomatic_states: Dictionary = {}  # faction_name: DiplomaticState

func initialize_faction(race: String, _character_type: String):
	# Set up initial factions based on race and type
	match race:
		"human":
			primary_faction = "humans"
			allies = ["survivors", "traders"]
			enemies = ["zombies", "infected"]
		"alien":
			primary_faction = "aliens"
			allies = ["alien_colony"]
			enemies = ["humans", "zombies"]
		"zombie":
			primary_faction = "zombies"
			allies = ["infected"]
			enemies = ["humans", "aliens", "survivors"]
	
	# Initialize default diplomatic states
	for faction in allies:
		diplomatic_states[faction] = DiplomaticState.ALLIED
		faction_relationships[faction] = 100
	
	for faction in enemies:
		diplomatic_states[faction] = DiplomaticState.AT_WAR
		faction_relationships[faction] = -100
	
	# Neutral to unknown factions
	diplomatic_states["neutral"] = DiplomaticState.NEUTRAL
	faction_relationships["neutral"] = 0
	
	print("Faction initialized: ", primary_faction)

func get_relationship_with(faction: String) -> int:
	return faction_relationships.get(faction, 0)

func get_diplomatic_state(faction: String) -> DiplomaticState:
	return diplomatic_states.get(faction, DiplomaticState.NEUTRAL)

func is_hostile_to(faction: String) -> bool:
	var state = get_diplomatic_state(faction)
	return state == DiplomaticState.HOSTILE or state == DiplomaticState.AT_WAR

func is_friendly_to(faction: String) -> bool:
	var state = get_diplomatic_state(faction)
	return state == DiplomaticState.FRIENDLY or state == DiplomaticState.ALLIED

func modify_relationship(faction: String, amount: int):
	var current = get_relationship_with(faction)
	var new_value = current + amount
	
	faction_relationships[faction] = new_value
	
	# Update diplomatic state based on new relationship
	if new_value >= 75:
		diplomatic_states[faction] = DiplomaticState.ALLIED
	elif new_value >= 50:
		diplomatic_states[faction] = DiplomaticState.FRIENDLY
	elif new_value >= 25:
		diplomatic_states[faction] = DiplomaticState.NEUTRAL
	elif new_value >= -25:
		diplomatic_states[faction] = DiplomaticState.NEUTRAL
	elif new_value >= -50:
		diplomatic_states[faction] = DiplomaticState.HOSTILE
	else:
		diplomatic_states[faction] = DiplomaticState.AT_WAR

func get_faction_info() -> Dictionary:
	return {
		"primary_faction": primary_faction,
		"allies": allies,
		"enemies": enemies,
		"relationships": faction_relationships.duplicate(),
		"diplomatic_states": diplomatic_states.duplicate()
	}

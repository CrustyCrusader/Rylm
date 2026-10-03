extends BaseCharacter3D
class_name HumanNPC

# NPC-specific nodes
@onready var dialogue_system = $DialogueSystem
@onready var quest_giver = $QuestGiver

# NPC settings
@export var npc_type: String = "villager"
@export var is_trader: bool = false
@export var trade_items: Array[String] = []

# Fleeing state
var is_fleeing: bool = false
var flee_target: Node = null
@export var safe_flee_distance: float = 20.0

func _ready() -> void:
	character_type = "npc"
	character_race = "human"
	
	if character_name == "Unnamed":
		character_name = "Villager"
	
	# Distinct NPC settings & animations
	melee_attack_animation = "AnimationLibrary_Godot_Standard/Punch_Jab"
	base_damage = 5.0
	
	super._ready()
	add_to_group("npcs")
	
	print("NPC spawned: ", character_name, " (", npc_type, ")")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if not is_alive or is_attacking or movement_locked:
		return
	
	# Process fleeing behavior via MovementController
	if is_fleeing:
		if is_instance_valid(flee_target):
			var dist = global_position.distance_to(flee_target.global_position)
			if dist < safe_flee_distance:
				# Calculate fleeing direction on the horizontal XZ plane
				var flee_dir = (global_position - flee_target.global_position)
				flee_dir.y = 0.0
				flee_dir = flee_dir.normalized()
				
				# Delegate movement & sprint state to MovementController
				if movement:
					movement.handle_directional_input(delta, flee_dir, true)
			else:
				# Stop fleeing once safe distance is reached
				is_fleeing = false
				flee_target = null
				if movement:
					movement.stop_movement()
		else:
			is_fleeing = false
			if movement:
				movement.stop_movement()

func interact(player: PlayerCharacter) -> void:
	if not is_alive or is_fleeing:
		return
		
	print(character_name, " interacting with ", player.character_name)
	
	if dialogue_system and dialogue_system.has_method("start_dialogue"):
		dialogue_system.start_dialogue(player)
	elif quest_giver and quest_giver.has_method("offer_quest"):
		quest_giver.offer_quest(player)
	elif is_trader:
		open_trade_interface(player)

func open_trade_interface(player: PlayerCharacter) -> void:
	print("Opening trade interface with ", player.character_name)
	# TODO: Implement trade interface UI hook

func on_attacked(attacker) -> void:
	if not is_alive:
		return
	super.on_attacked(attacker)
	
	print(character_name, " was attacked! Fleeing!")
	
	# Trigger flee state towards safe distance
	if attacker and attacker != self:
		is_fleeing = true
		flee_target = attacker

func get_death_animation_name() -> String:
	return "AnimationLibrary_Godot_Standard/Death01"

func _on_death_started() -> void:
	super._on_death_started()
	is_fleeing = false
	flee_target = null

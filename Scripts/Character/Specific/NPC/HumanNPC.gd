extends BaseCharacter3D
class_name HumanNPC

# NPC-specific nodes
@onready var dialogue_system = $DialogueSystem
@onready var quest_giver = $QuestGiver

# NPC settings
@export var npc_type: String = "villager"
@export var is_trader: bool = false
@export var trade_items: Array[String] = []

func _ready() -> void:
	character_type = "npc"
	character_race = "human"
	
	# Set default name
	if character_name == "Unnamed":
		character_name = "Villager"
	
	# Parent initialization
	super._ready()
	
	# Add to NPC group
	add_to_group("npcs")
	
	print("NPC spawned: ", character_name, " (", npc_type, ")")

func interact(player: PlayerCharacter) -> void:
	print(character_name, " interacting with ", player.character_name)
	
	if dialogue_system:
		dialogue_system.start_dialogue(player)
	elif quest_giver:
		quest_giver.offer_quest(player)
	elif is_trader:
		open_trade_interface(player)

func open_trade_interface(player: PlayerCharacter) -> void:
	print("Opening trade interface with ", player.character_name)
	# TODO: Implement trade interface

func on_attacked(attacker) -> void:
	super.on_attacked(attacker)
	
	print(character_name, " was attacked! Fleeing!")
	
	# NPCs typically flee when attacked
	if movement:
		movement.set_move_state(MovementController.MoveState.RUNNING)
		# Run away from attacker
		if attacker:
			var flee_direction = (global_position - attacker.global_position).normalized()
			# Set velocity to flee (simplified)
			velocity = flee_direction * movement.run_speed

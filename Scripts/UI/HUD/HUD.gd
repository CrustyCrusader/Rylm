extends CanvasLayer
class_name HUD

@onready var health_bar = $HealthBar
@onready var stamina_bar = $StaminaBar
@onready var hunger_bar = $HungerBar
@onready var thirst_bar = $ThirstBar
@onready var infection_bar = $InfectionBar

var player: Node = null

func _ready():
	add_to_group("hud")  # Important! PlayerCharacter looks for this group
	visible = true

func connect_to_player(target_player: Node):
	player = target_player
	print("HUD connected to player")

func show_damage_indicator(direction: Vector2, damage_amount: float):
	print("Damage indicator: ", direction, " damage: ", damage_amount)
	# Add visual effect here

func update_display():
	if not player:
		return
	
	# Update health
	if player.has_method("get_health"):
		var health_data = player.get_health()
		health_bar.value = health_data.current
	
	# Update other bars as needed

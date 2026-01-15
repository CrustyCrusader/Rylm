extends CanvasLayer

@onready var health_bar = $HUD/HealthBar
@onready var stamina_bar = $HUD/StaminaBar
@onready var weight_label = $HUD/WeightLabel

var player: BaseCharacter3D = null

func _ready():
	# Update every second
	$UpdateTimer.start()

func set_player(new_player: BaseCharacter3D):
	player = new_player

func _on_update_timer_timeout():
	if not player:
		return
	
	# Update health bar
	if player.stats:
		var health_percent = (player.stats.current_health / player.stats.max_health) * 100
		health_bar.value = health_percent
		
		# Update stamina bar
		var stamina_percent = (player.stats.current_stamina / player.stats.max_stamina) * 100
		stamina_bar.value = stamina_percent
	
	# Update weight info
	if player.inventory:
		var current_weight = player.inventory.get_current_weight()
		var total_capacity = player.inventory.get_total_capacity()
		weight_label.text = "%.1f / %.1f kg" % [current_weight, total_capacity]

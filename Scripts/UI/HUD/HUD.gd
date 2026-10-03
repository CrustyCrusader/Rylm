class_name HUD
extends CanvasLayer

# References using Scene Unique Names (%) with fallback search
@onready var health_bar: TextureProgressBar = _find_ui_node(["%HealthBar", "HealthBar", "Control/HealthBar", "VBoxContainer/HealthBar"])
@onready var stamina_bar: TextureProgressBar = _find_ui_node(["%StaminaBar", "StaminaBar", "Control/StaminaBar", "VBoxContainer/StaminaBar"])
@onready var weight_label: Label = _find_ui_node(["%WeightLabel", "WeightLabel", "Weight", "Control/WeightLabel"])

var player: Node = null


func _ready() -> void:
	add_to_group("hud") # PlayerCharacter searches for this group
	visible = true


func _find_ui_node(possible_paths: Array) -> Node:
	for path in possible_paths:
		var found_node = get_node_or_null(path)
		if found_node:
			return found_node
	return null


func connect_to_player(target_player: Node) -> void:
	player = target_player
	print("HUD connected to player: ", player.name)
	
	# Connect to player health signal if available
	if player.has_signal("health_changed"):
		if not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)

	update_display()


func _on_player_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current


func update_display() -> void:
	if not player:
		return

	# Update HealthBar (TextureProgressBar)
	if health_bar:
		if player.has_method("get_health"):
			var health_data = player.get_health()
			if "max" in health_data:
				health_bar.max_value = health_data.max
			health_bar.value = health_data.current
		elif "current_health" in player:
			if "max_health" in player:
				health_bar.max_value = player.max_health
			health_bar.value = player.current_health

	# Update StaminaBar (TextureProgressBar)
	if stamina_bar:
		if "stamina" in player:
			stamina_bar.value = player.stamina
		elif "current_stamina" in player:
			stamina_bar.value = player.current_stamina

	# Update Weight Label
	if weight_label:
		if "current_weight" in player:
			var max_w = player.max_weight if "max_weight" in player else 0.0
			weight_label.text = "Weight: %.1f / %.1f kg" % [player.current_weight, max_w]


func show_damage_indicator(direction: Vector2, damage_amount: float) -> void:
	print("Damage indicator: ", direction, " damage: ", damage_amount)

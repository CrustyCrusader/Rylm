# UI/HUD/SurvivalDisplay.gd
extends Control
class_name SurvivalDisplay

@onready var hunger_bar = $HungerBar
@onready var thirst_bar = $ThirstBar
@onready var fatigue_bar = $FatigueBar
@onready var infection_bar = $InfectionBar
@onready var temp_indicator = $TemperatureIndicator

@onready var hunger_label = $HungerLabel
@onready var thirst_label = $ThirstLabel
@onready var fatigue_label = $FatigueLabel

var survival_system: SurvivalSystem = null

func _ready():
	visible = true
	set_process(false)

func connect_to_survival_system(system: SurvivalSystem):
	survival_system = system
	if survival_system:
		survival_system.needs_updated.connect(_on_needs_updated)
		survival_system.infection_changed.connect(_on_infection_changed)
		survival_system.body_temperature_changed.connect(_on_temp_changed)
		set_process(true)
		print("SurvivalDisplay connected to SurvivalSystem")

func _on_needs_updated(hunger_val: float, thirst_val: float, fatigue_val: float):
	update_bars(hunger_val, thirst_val, fatigue_val)

func _on_infection_changed(level: float):
	infection_bar.value = level
	infection_bar.get_node("Label").text = "Infection: %.1f%%" % level

func _on_temp_changed(temp: float):
	temp_indicator.text = "Temp: %.1f°C" % temp
	# Change color based on temperature
	if temp < 35.0:
		temp_indicator.modulate = Color.BLUE
	elif temp > 39.0:
		temp_indicator.modulate = Color.RED
	else:
		temp_indicator.modulate = Color.WHITE

func update_bars(hunger_val: float, thirst_val: float, fatigue_val: float):
	hunger_bar.value = hunger_val
	thirst_bar.value = thirst_val
	fatigue_bar.value = fatigue_val
	
	hunger_label.text = "Hunger: %d%%" % hunger_val
	thirst_label.text = "Thirst: %d%%" % thirst_val
	fatigue_label.text = "Fatigue: %d%%" % fatigue_val
	
	# Change bar colors based on severity
	update_bar_colors()

func update_bar_colors():
	# Hunger bar
	if hunger_bar.value > 80:
		hunger_bar.get_node("Bar").self_modulate = Color.RED
	elif hunger_bar.value > 50:
		hunger_bar.get_node("Bar").self_modulate = Color.ORANGE
	else:
		hunger_bar.get_node("Bar").self_modulate = Color.GREEN
	
	# Thirst bar
	if thirst_bar.value > 80:
		thirst_bar.get_node("Bar").self_modulate = Color.DARK_BLUE
	elif thirst_bar.value > 50:
		thirst_bar.get_node("Bar").self_modulate = Color.BLUE
	else:
		thirst_bar.get_node("Bar").self_modulate = Color.CYAN
	
	# Fatigue bar
	if fatigue_bar.value > 80:
		fatigue_bar.get_node("Bar").self_modulate = Color.PURPLE
	elif fatigue_bar.value > 50:
		fatigue_bar.get_node("Bar").self_modulate = Color.VIOLET
	else:
		fatigue_bar.get_node("Bar").self_modulate = Color.LIGHT_BLUE

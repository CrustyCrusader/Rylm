# HealthSystem/InjuryManager.gd
extends Node
class_name InjuryManager

signal injury_added(injury_data: Dictionary)
signal injury_healed(injury_type: String, body_part: String)
signal injury_worsened(injury_data: Dictionary)

# Injury database
var injury_database = {
	"scratch": {
		"base_severity": 0.1,
		"bleed_rate": 0.05,
		"pain": 10.0,
		"heal_time": 2.0,  # hours
		"treatment": "bandage"
	},
	"cut": {
		"base_severity": 0.3,
		"bleed_rate": 0.15,
		"pain": 25.0,
		"heal_time": 8.0,
		"treatment": "stitches"
	},
	"deep_wound": {
		"base_severity": 0.7,
		"bleed_rate": 0.4,
		"pain": 50.0,
		"heal_time": 24.0,
		"treatment": "surgery"
	},
	"fracture": {
		"base_severity": 0.8,
		"bleed_rate": 0.0,
		"pain": 60.0,
		"heal_time": 72.0,
		"treatment": "splint"
	},
	"burn": {
		"base_severity": 0.5,
		"bleed_rate": 0.0,
		"pain": 40.0,
		"heal_time": 12.0,
		"treatment": "ointment"
	},
	"bruise": {
		"base_severity": 0.2,
		"bleed_rate": 0.0,
		"pain": 15.0,
		"heal_time": 4.0,
		"treatment": "rest"
	}
}

# Active injuries
var active_injuries: Array[Dictionary] = []
var injury_history: Array[Dictionary] = []

# Treatment supplies needed
var treatment_supplies = {
	"bandage": ["cloth", 1],
	"stitches": ["needle", 1, "thread", 2, "disinfectant", 1],
	"surgery": ["scalpel", 1, "suture_kit", 1, "anesthetic", 2, "disinfectant", 2],
	"splint": ["wood", 2, "cloth", 3],
	"ointment": ["herbs", 2, "fat", 1],
	"disinfectant": ["alcohol", 1, "herbs", 1]
}

func _ready():
	print("InjuryManager initialized")

func add_injury(injury_type: String, body_part: String, severity_multiplier: float = 1.0) -> Dictionary:
	if not injury_database.has(injury_type):
		print("Unknown injury type:", injury_type)
		return {}
	
	var base_data = injury_database[injury_type]
	
	var injury = {
		"id": str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000),
		"type": injury_type,
		"body_part": body_part,
		"severity": base_data["base_severity"] * severity_multiplier,
		"bleed_rate": base_data["bleed_rate"] * severity_multiplier,
		"pain": base_data["pain"] * severity_multiplier,
		"heal_time_remaining": base_data["heal_time"] * 3600.0,  # Convert to seconds
		"heal_time_total": base_data["heal_time"] * 3600.0,
		"treatment": base_data["treatment"],
		"treated": false,
		"infected": false,
		"time_created": Time.get_unix_time_from_system(),
		"complications": []
	}
	
	active_injuries.append(injury)
	injury_history.append(injury.duplicate())
	
	injury_added.emit(injury)
	
	print("Injury added:", injury_type, " to ", body_part)
	
	return injury

func _process(delta):
	# Update healing progress
	for injury in active_injuries:
		if injury["treated"] and injury["heal_time_remaining"] > 0:
			injury["heal_time_remaining"] = max(0, injury["heal_time_remaining"] - delta)
			
			# Check if healed
			if injury["heal_time_remaining"] <= 0:
				complete_healing(injury)

func treat_injury(injury_id: String, treatment_type: String, inventory) -> bool:
	# Find the injury
	var injury = null
	for inj in active_injuries:
		if inj["id"] == injury_id:
			injury = inj
			break
	
	if not injury:
		return false
	
	# Check if treatment matches injury type
	if injury["treatment"] != treatment_type:
		print("Wrong treatment for injury type")
		return false
	
	# Check if we have required supplies
	if not has_treatment_supplies(treatment_type, inventory):
		print("Missing supplies for treatment")
		return false
	
	# Apply treatment
	injury["treated"] = true
	injury["pain"] *= 0.5  # Reduce pain when treated
	injury["bleed_rate"] = 0.0  # Stop bleeding
	
	# Mark as treated in history
	for hist_injury in injury_history:
		if hist_injury["id"] == injury_id:
			hist_injury["treated"] = true
			hist_injury["time_treated"] = Time.get_unix_time_from_system()
			break
	
	print("Injury treated:", injury["type"], " on ", injury["body_part"])
	return true

func has_treatment_supplies(treatment_type: String, inventory) -> bool:
	if not treatment_supplies.has(treatment_type):
		return false
	
	var supplies = treatment_supplies[treatment_type]
	
	# Supplies array is [item1, quantity1, item2, quantity2, ...]
	for i in range(0, supplies.size(), 2):
		var item = supplies[i]
		var quantity = supplies[i + 1]
		
		if not inventory.has_item(item, quantity):
			return false
	
	return true

func complete_healing(injury: Dictionary):
	# Move from active to history (mark as healed)
	active_injuries.erase(injury)
	
	injury["time_healed"] = Time.get_unix_time_from_system()
	injury["healed"] = true
	
	injury_healed.emit(injury["type"], injury["body_part"])
	
	print("Injury healed:", injury["type"], " on ", injury["body_part"])

func worsen_injury(injury_id: String, reason: String = "untreated"):
	var injury = null
	for inj in active_injuries:
		if inj["id"] == injury_id:
			injury = inj
			break
	
	if not injury:
		return
	
	# Increase severity
	injury["severity"] = min(1.0, injury["severity"] + 0.1)
	
	# Add complication
	var complication = {
		"reason": reason,
		"time": Time.get_unix_time_from_system(),
		"severity_increase": 0.1
	}
	
	injury["complications"].append(complication)
	
	injury_worsened.emit(injury)
	
	print("Injury worsened:", injury["type"], " on ", injury["body_part"])

func get_total_pain() -> float:
	var total_pain = 0.0
	for injury in active_injuries:
		total_pain += injury["pain"]
	return total_pain

func get_total_bleed_rate() -> float:
	var total_bleed = 0.0
	for injury in active_injuries:
		if not injury["treated"]:
			total_bleed += injury["bleed_rate"]
	return total_bleed

func get_injuries_by_body_part(body_part: String) -> Array:
	var injuries = []
	for injury in active_injuries:
		if injury["body_part"] == body_part:
			injuries.append(injury)
	return injuries

func get_active_injuries() -> Array:
	return active_injuries.duplicate()

func get_injury_status() -> Dictionary:
	return {
		"active_injuries": active_injuries.size(),
		"total_pain": get_total_pain(),
		"total_bleed_rate": get_total_bleed_rate(),
		"untreated_injuries": active_injuries.filter(func(inj): return not inj["treated"]).size(),
		"infected_injuries": active_injuries.filter(func(inj): return inj["infected"]).size()
	}

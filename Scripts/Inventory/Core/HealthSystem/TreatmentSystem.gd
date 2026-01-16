# Health/TreatmentSystem.gd
class_name TreatmentSystem
extends Node

# Signals
signal treatment_applied(treatment_type: String, injury_id: String)
signal treatment_failed(treatment_type: String, reason: String)

# Character reference
var character: BaseCharacter3D

# Treatment types
enum TreatmentType {
	DISINFECT,
	SPLINT,
	PAIN_MEDICATION,
	ANTIBIOTICS,
	BANDAGE,
	SURGERY
}

# Treatment requirements
var treatment_requirements: Dictionary = {
	"disinfect": [{"item": "alcohol", "quantity": 1}, {"item": "bandage", "quantity": 1}],
	"splint": [{"item": "splint", "quantity": 1}],
	"pain_med": [{"item": "painkillers", "quantity": 1}],
	"antibiotics": [{"item": "antibiotics", "quantity": 1}],
	"bandage": [{"item": "bandage", "quantity": 1}],
	"surgery": [{"item": "surgical_kit", "quantity": 1}]
}

func initialize(character_ref: BaseCharacter3D) -> void:
	character = character_ref
	print("TreatmentSystem initialized for: ", character.character_name)

func apply_treatment(treatment_type: String, injury_id: String) -> bool:
	if not character or not character.is_alive:
		treatment_failed.emit(treatment_type, "Character not available")
		return false
	
	if not has_required_items(treatment_type):
		treatment_failed.emit(treatment_type, "Missing required items")
		return false
	
	# Apply specific treatment
	match treatment_type:
		"disinfect":
			return apply_disinfect(injury_id)
		"splint":
			return apply_splint(injury_id)
		"pain_med":
			return apply_pain_med(injury_id)
		"antibiotics":
			return apply_antibiotics(injury_id)
		"bandage":
			return apply_bandage(injury_id)
		"surgery":
			return apply_surgery(injury_id)
		_:
			treatment_failed.emit(treatment_type, "Unknown treatment type")
			return false

func has_required_items(treatment_type: String) -> bool:
	if treatment_type not in treatment_requirements:
		return false
	
	var requirements = treatment_requirements[treatment_type]
	for req in requirements:
		var item_id = req.get("item", "")
		var quantity = req.get("quantity", 1)
		if not character.inventory.has_item(item_id, quantity):
			return false
	
	return true

func consume_required_items(treatment_type: String) -> bool:
	if treatment_type not in treatment_requirements:
		return false
	
	var requirements = treatment_requirements[treatment_type]
	for req in requirements:
		var item_id = req.get("item", "")
		var quantity = req.get("quantity", 1)
		if not character.inventory.remove_item(item_id, quantity):
			return false
	
	return true

func apply_disinfect(injury_id: String) -> bool:
	print("Applying disinfect to injury: ", injury_id)
	# Add disinfect logic here
	if consume_required_items("disinfect"):
		treatment_applied.emit("disinfect", injury_id)
		return true
	return false

func apply_splint(injury_id: String) -> bool:
	print("Applying splint to injury: ", injury_id)
	# Add splint logic here
	if consume_required_items("splint"):
		treatment_applied.emit("splint", injury_id)
		return true
	return false

func apply_pain_med(injury_id: String) -> bool:
	print("Applying pain medication to injury: ", injury_id)
	# Add pain med logic here
	if consume_required_items("pain_med"):
		treatment_applied.emit("pain_med", injury_id)
		return true
	return false

func apply_antibiotics(injury_id: String) -> bool:
	print("Applying antibiotics to injury: ", injury_id)
	# Add antibiotics logic here
	if consume_required_items("antibiotics"):
		treatment_applied.emit("antibiotics", injury_id)
		return true
	return false

func apply_bandage(injury_id: String) -> bool:
	print("Applying bandage to injury: ", injury_id)
	# Add bandage logic here
	if consume_required_items("bandage"):
		treatment_applied.emit("bandage", injury_id)
		return true
	return false

func apply_surgery(injury_id: String) -> bool:
	print("Applying surgery to injury: ", injury_id)
	# Add surgery logic here
	if consume_required_items("surgery"):
		treatment_applied.emit("surgery", injury_id)
		return true
	return false

func get_treatment_requirements(treatment_type: String) -> Array:
	return treatment_requirements.get(treatment_type, [])

func can_perform_treatment(treatment_type: String) -> bool:
	return has_required_items(treatment_type)

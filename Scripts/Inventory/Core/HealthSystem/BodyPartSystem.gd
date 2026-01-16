extends Node
class_name BodyPartSystem

# Body Parts Enum
enum BodyPart {
	HEAD,
	TORSO,
	LEFT_ARM,
	RIGHT_ARM,
	LEFT_LEG,
	RIGHT_LEG,
	HANDS,
	FEET
}

# Injury Types
enum InjuryType {
	SCRATCH,      # Minor - needs bandage
	CUT,          # Moderate - needs stitching
	DEEP_WOUND,   # Severe - needs surgery
	FRACTURE,     # Bone - needs splint
	BURN,         # Thermal - needs ointment
	BRUISE        # Internal - time heals
}

# Body Part Data Structure
class BodyPartData:
	var part: BodyPart
	var health: float
	var max_health: float
	var injuries: Array = []
	var bandaged: bool = false
	var disinfected: bool = false
	var splinted: bool = false
	
	func _init(body_part: BodyPart, max_hp: float):
		part = body_part
		health = max_hp
		max_health = max_hp

# Injury Data Structure
class InjuryData:
	var type: InjuryType
	var severity: float  # 0.0 to 1.0
	var location: BodyPart
	var bleed_rate: float
	var pain_level: float
	var infection_risk: float
	var time_inflicted: float
	
	func _init(injury_type: InjuryType, inj_severity: float, loc: BodyPart):
		type = injury_type
		severity = inj_severity
		location = loc
		bleed_rate = calculate_bleed_rate()
		pain_level = calculate_pain()
		infection_risk = calculate_infection_risk()
		time_inflicted = Time.get_unix_time_from_system()
	
	func calculate_bleed_rate() -> float:
		match type:
			InjuryType.SCRATCH:
				return 0.1 * severity
			InjuryType.CUT:
				return 0.3 * severity
			InjuryType.DEEP_WOUND:
				return 0.7 * severity
			InjuryType.FRACTURE:
				return 0.0
			InjuryType.BURN:
				return 0.0
			InjuryType.BRUISE:
				return 0.0
			_:
				return 0.0
	
	func calculate_pain() -> float:
		match type:
			InjuryType.SCRATCH:
				return 10.0 * severity
			InjuryType.CUT:
				return 25.0 * severity
			InjuryType.DEEP_WOUND:
				return 50.0 * severity
			InjuryType.FRACTURE:
				return 60.0 * severity
			InjuryType.BURN:
				return 40.0 * severity
			InjuryType.BRUISE:
				return 15.0 * severity
			_:
				return 0.0
	
	func calculate_infection_risk() -> float:
		match type:
			InjuryType.SCRATCH:
				return 0.1 * severity
			InjuryType.CUT:
				return 0.3 * severity
			InjuryType.DEEP_WOUND:
				return 0.6 * severity
			InjuryType.FRACTURE:
				return 0.2 * severity
			InjuryType.BURN:
				return 0.4 * severity
			InjuryType.BRUISE:
				return 0.05 * severity
			_:
				return 0.0

# Main System
signal health_changed(new_health: float, old_health: float)

var body_parts: Dictionary = {}
var total_health: float = 100.0
var overall_pain: float = 0.0
var bleeding_rate: float = 0.0

func _ready():
	initialize_body_parts()
	print("BodyPartSystem initialized")

func initialize_body_parts():
	# Set up each body part with its max health
	body_parts[BodyPart.HEAD] = BodyPartData.new(BodyPart.HEAD, 30.0)
	body_parts[BodyPart.TORSO] = BodyPartData.new(BodyPart.TORSO, 40.0)
	body_parts[BodyPart.LEFT_ARM] = BodyPartData.new(BodyPart.LEFT_ARM, 20.0)
	body_parts[BodyPart.RIGHT_ARM] = BodyPartData.new(BodyPart.RIGHT_ARM, 20.0)
	body_parts[BodyPart.LEFT_LEG] = BodyPartData.new(BodyPart.LEFT_LEG, 25.0)
	body_parts[BodyPart.RIGHT_LEG] = BodyPartData.new(BodyPart.RIGHT_LEG, 25.0)
	body_parts[BodyPart.HANDS] = BodyPartData.new(BodyPart.HANDS, 10.0)
	body_parts[BodyPart.FEET] = BodyPartData.new(BodyPart.FEET, 10.0)

func apply_damage(part: BodyPart, damage: float, injury_type: InjuryType = InjuryType.SCRATCH):
	var old_health = total_health
	var body_part = body_parts.get(part)
	if not body_part:
		return
	
	# Apply damage
	body_part.health = max(0, body_part.health - damage)
	
	# Create injury based on damage severity
	var injury_severity = damage / body_part.max_health
	if injury_severity > 0.1:  # Only create injury if significant damage
		var injury = InjuryData.new(injury_type, injury_severity, part)
		body_part.injuries.append(injury)
		
		# Update overall stats
		update_overall_health()
		update_pain_level()
		update_bleeding_rate()
		
		print("Injury applied: ", InjuryType.keys()[injury_type], " to ", BodyPart.keys()[part])
	
	# Emit signal
	if old_health != total_health:
		health_changed.emit(total_health, old_health)

func add_injury(part: BodyPart, injury_type: InjuryType, severity: float):
	var body_part = body_parts.get(part)
	if not body_part:
		return
	
	var injury = InjuryData.new(injury_type, severity, part)
	body_part.injuries.append(injury)
	
	# Update stats
	update_overall_health()
	update_pain_level()
	update_bleeding_rate()
	
	print("Injury added: ", InjuryType.keys()[injury_type], 
		  " to ", BodyPart.keys()[part], " severity: ", severity)

func update_overall_health():
	var total = 0.0
	var max_total = 0.0
	
	for part in body_parts.values():
		total += part.health
		max_total += part.max_health
	
	total_health = (total / max_total) * 100.0

func update_pain_level():
	overall_pain = 0.0
	for part in body_parts.values():
		for injury in part.injuries:
			overall_pain += injury.pain_level * injury.severity
	overall_pain = clamp(overall_pain, 0.0, 100.0)

func update_bleeding_rate():
	bleeding_rate = 0.0
	for part in body_parts.values():
		for injury in part.injuries:
			if not part.bandaged:  # Only count bleeding if not bandaged
				bleeding_rate += injury.bleed_rate
	bleeding_rate = clamp(bleeding_rate, 0.0, 10.0)

func can_perform_action(part: BodyPart, action_type: String) -> bool:
	var body_part = body_parts.get(part)
	if not body_part:
		return false
	
	# Check if body part is functional for the action
	match action_type:
		"attack":
			return body_part.health > 10.0 and not has_fracture(part)
		"move":
			return body_part.health > 15.0
		"craft":
			return body_part.health > 5.0 and not has_deep_wound(part)
		_:
			return true

func has_fracture(part: BodyPart) -> bool:
	var body_part = body_parts.get(part)
	if not body_part:
		return false
	
	for injury in body_part.injuries:
		if injury.type == InjuryType.FRACTURE:
			return true
	return false

func has_deep_wound(part: BodyPart) -> bool:
	var body_part = body_parts.get(part)
	if not body_part:
		return false
	
	for injury in body_part.injuries:
		if injury.type == InjuryType.DEEP_WOUND:
			return true
	return false

func get_body_part_status(part: BodyPart) -> Dictionary:
	var body_part = body_parts.get(part)
	if not body_part:
		return {}
	
	return {
		"health": body_part.health,
		"max_health": body_part.max_health,
		"health_percent": (body_part.health / body_part.max_health) * 100.0,
		"injuries": body_part.injuries.size(),
		"bandaged": body_part.bandaged,
		"disinfected": body_part.disinfected,
		"splinted": body_part.splinted,
		"functional": body_part.health > (body_part.max_health * 0.3)
	}

func get_all_body_part_status() -> Dictionary:
	var status = {}
	for part in BodyPart.values():
		status[part] = get_body_part_status(part)
	return status

func heal_part(part: BodyPart, amount: float):
	var old_health = total_health
	var body_part = body_parts.get(part)
	if not body_part:
		return
	
	body_part.health = min(body_part.max_health, body_part.health + amount)
	update_overall_health()
	
	if old_health != total_health:
		health_changed.emit(total_health, old_health)

func apply_bandage(part: BodyPart):
	var body_part = body_parts.get(part)
	if not body_part:
		return false
	
	body_part.bandaged = true
	update_bleeding_rate()
	return true

func apply_disinfectant(part: BodyPart):
	var body_part = body_parts.get(part)
	if not body_part:
		return false
	
	body_part.disinfected = true
	return true

func apply_splint(part: BodyPart):
	var body_part = body_parts.get(part)
	if not body_part:
		return false
	
	body_part.splinted = true
	return true

func get_total_health_percent() -> float:
	return total_health

func get_overall_pain() -> float:
	return overall_pain

func get_bleeding_rate() -> float:
	return bleeding_rate

func is_alive() -> bool:
	return total_health > 0.0

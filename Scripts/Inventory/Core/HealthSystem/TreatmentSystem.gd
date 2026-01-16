# Core/TreatmentSystem.gd
extends Node
class_name TreatmentSystem

enum TreatmentType {
	BANDAGE,
	STITCH,
	DISINFECT,
	SPLINT,
	PAIN_MED,
	ANTIBIOTICS
}

# Treatment items needed
var treatment_requirements = {
	TreatmentType.BANDAGE: ["bandage", 1],
	TreatmentType.STITCH: ["suture_kit", 1, "disinfectant", 1],
	TreatmentType.DISINFECT: ["disinfectant", 1, "bandage", 1],
	TreatmentType.SPLINT: ["splint", 1, "bandage", 2],
	TreatmentType.PAIN_MED: ["painkillers", 1],
	TreatmentType.ANTIBIOTICS: ["antibiotics", 1]
}

func apply_treatment(body_part_system: BodyPartSystem, part: BodyPartSystem.BodyPart, 
					treatment: TreatmentType, inventory: Node) -> bool:
	
	# Check if player has required items
	if not has_required_items(treatment, inventory):
		print("Missing items for treatment: ", TreatmentType.keys()[treatment])
		return false
	
	var body_part = body_part_system.body_parts.get(part)
	if not body_part:
		return false
	
	# Apply treatment effects
	match treatment:
		TreatmentType.BANDAGE:
			return apply_bandage(body_part)
		TreatmentType.STITCH:
			return apply_stitch(body_part)
		TreatmentType.DISINFECT:
			return apply_disinfect(body_part)
		TreatmentType.SPLINT:
			return apply_splint(body_part)
		TreatmentType.PAIN_MED:
			return apply_pain_med(body_part)
		TreatmentType.ANTIBIOTICS:
			return apply_antibiotics(body_part)
	
	return false

func apply_bandage(body_part):
	body_part.bandaged = true
	# Reduce bleeding rate
	for injury in body_part.injuries:
		if injury.type in [BodyPartSystem.InjuryType.SCRATCH, BodyPartSystem.InjuryType.CUT]:
			injury.bleed_rate *= 0.2
	print("Bandage applied")
	return true

func apply_stitch(body_part):
	# Remove deep wounds and severe cuts
	var new_injuries = []
	for injury in body_part.injuries:
		if injury.type == BodyPartSystem.InjuryType.DEEP_WOUND:
			# Convert to regular cut
			injury.type = BodyPartSystem.InjuryType.CUT
			injury.severity *= 0.5
			new_injuries.append(injury)
		elif injury.type == BodyPartSystem.InjuryType.CUT:
			injury.severity *= 0.3
			new_injuries.append(injury)
		else:
			new_injuries.append(injury)
	body_part.injuries = new_injuries
	body_part.bandaged = true
	print("Wound stitched")
	return true

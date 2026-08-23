# auto_bonemap.gd - Processes imported scenes
@tool
extends EditorScenePostImportPlugin

func _post_process(scene: Node) -> void:
	print("Processing imported scene:", scene.name)
	_apply_profile_to_all_skeletons(scene)

func _apply_profile_to_all_skeletons(node):
	if node is Skeleton3D:
		print("  Found skeleton:", node.name)
		
		# Create and apply humanoid profile
		var profile = SkeletonProfileHumanoid.new()
		profile.create_bone_map(node)  # Auto-map bones by name
		
		node.skeleton_retargeting_profile = profile
		node.retargeting = true
		
		print("  Applied humanoid profile")
	
	# Process children
	for child in node.get_children():
		_apply_profile_to_all_skeletons(child)

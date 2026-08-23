# combine_libraries.gd (@tool script for editor use)
@tool
extends EditorScript

func _run():
	# --- CONFIGURE THESE PATHS ---
	var library_paths = [
		"res://path/to/anim_lib1.tres",
		"res://path/to/anim_lib2.tres",
	]
	var output_path = "res://path/to/combined_animations.tres"
	# ----------------------------

	var combined_library = AnimationLibrary.new()

	for lib_path in library_paths:
		var lib: AnimationLibrary = load(lib_path)
		if lib:
			for anim_name in lib.get_animation_list():
				# Avoid name collisions: you can add a prefix if needed
				var final_name = anim_name
				if combined_library.has_animation(final_name):
					print("Warning: Skipping duplicate animation name: ", anim_name)
					continue
				var anim = lib.get_animation(anim_name)
				combined_library.add_animation(final_name, anim)
				print("Added: ", final_name)

	# Save the new combined library
	var error = ResourceSaver.save(combined_library, output_path)
	if error == OK:
		print("Successfully saved combined library to: ", output_path)
	else:
		printerr("Failed to save library. Error code: ", error)

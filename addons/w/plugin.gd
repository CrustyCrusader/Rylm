@tool
extends EditorPlugin

var post_import_plugin

func _enter_tree() -> void:
	post_import_plugin = preload("res://addons/w/auto_bonemap.gd").new()
	add_scene_post_import_plugin(post_import_plugin)

func _exit_tree() -> void:
	remove_scene_post_import_plugin(post_import_plugin)

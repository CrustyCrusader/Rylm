extends Node

signal quest_updated(quest_id: String, state: String)

var play_time: float = 0.0
var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var global_metrics: Dictionary = {
	"enemies_defeated": 0,
	"items_crafted": 0
}

func _process(delta: float) -> void:
	if not get_tree().paused:
		play_time += delta

func toggle_pause(paused: bool) -> void:
	get_tree().paused = paused

func add_quest(quest_id: String, initial_data: Dictionary = {}) -> void:
	active_quests[quest_id] = initial_data
	quest_updated.emit(quest_id, "started")

func complete_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		active_quests.erase(quest_id)
		if not completed_quests.has(quest_id):
			completed_quests.append(quest_id)
		quest_updated.emit(quest_id, "completed")

func collect_save_data() -> Dictionary:
	return {
		"play_time": play_time,
		"active_quests": active_quests,
		"completed_quests": completed_quests,
		"global_metrics": global_metrics
	}

func load_save_data(data: Dictionary) -> void:
	play_time = float(data.get("play_time", 0.0))
	active_quests = data.get("active_quests", {})
	
	# Use .assign() to safely transfer elements into typed Array[String]
	completed_quests.clear()
	completed_quests.assign(data.get("completed_quests", []))
	
	global_metrics = data.get("global_metrics", {"enemies_defeated": 0, "items_crafted": 0})

func save_to_slot(slot_id: int) -> bool:
	return SaveSystem.save_game(slot_id, collect_save_data())

func load_from_slot(slot_id: int) -> bool:
	var data := SaveSystem.load_game(slot_id)
	if data.is_empty():
		return false
	load_save_data(data)
	return true

# game_flow.gd
extends Node

# Define your level paths in order
@export var level_paths: Array[String] = [
	"res://scenes/Level1.tscn", # Your Level 1 scene
	"res://scenes/Level2.tscn", # Your Level 2 scene
	# Add more level paths here as you create them
]

var current_level_index = -1 # -1 means no level loaded yet

func _ready():
	# No need to connect to deprecated scene_changed signal anymore!
	
	# If the game starts directly from a level (e.g., for testing),
	# try to find its index. This is mostly for development convenience.
	var initial_scene_path = get_tree().current_scene.scene_file_path
	current_level_index = level_paths.find(initial_scene_path)
	if current_level_index != -1:
		print("GameFlow: Started at level ", current_level_index + 1)
	else:
		print("GameFlow: Not starting in a defined level path. Current scene: ", initial_scene_path)

func load_level(index: int):
	if index >= 0 and index < level_paths.size():
		current_level_index = index
		var path = level_paths[index]
		print("GameFlow: Loading level: ", path)
		get_tree().change_scene_to_file(path)
	else:
		print("GameFlow: No more levels or invalid level index: ", index)
		# Handle game finished / back to main menu / credits here
		get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn") # Example: Go back to main menu

# This method will be called by each level when it's ready and has found its WinZone
func register_level_completion(win_zone_node):
	print("GameFlow: Level registered its WinZone for completion detection")
	if win_zone_node and not win_zone_node.is_connected("level_completed", Callable(self, "_on_level_completed")):
		win_zone_node.connect("level_completed", Callable(self, "_on_level_completed"))
		print("GameFlow: Successfully connected to WinZone")
	else:
		print("GameFlow: Failed to connect to WinZone or already connected")

func _on_level_completed():
	print("GameFlow: Current level completed!")
	load_level(current_level_index + 1)

# Optional: Method to start the game from level 1 (called from main menu)
func start_new_game():
	load_level(0)

# Optional: Method to restart current level
func restart_current_level():
	if current_level_index >= 0:
		load_level(current_level_index)
	else:
		print("GameFlow: No current level to restart")

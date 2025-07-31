# game_flow.gd
extends Node

# Define your level paths in order
@export var level_paths: Array[String] = [
	#"res://Scenes/Levels/Level1.tscn", # Your Level 1 scene
	#"res://Scenes/Levels/Level2.tscn", # Your Level 2 scene
	"res://scenes/Level1.tscn", # Your Level 1 scene
	"res://scenes/Level2.tscn", # Your Level 2 scene
	# Add more level paths here as you create them (e.g., "res://Scenes/Levels/Level3.tscn")
]

var current_level_index = -1 # -1 means no level loaded yet

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to the scene_changed signal to re-connect to the WinZone
	# This is important because the WinZone signal connection is per-scene and will be lost on scene change.
	#get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))

	if not get_tree().is_connected("scene_changed", Callable(self, "_on_scene_changed")):
		get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))
		print("GameFlow DEBUG: Successfully connected 'scene_changed' signal.")
	else:
		print("GameFlow DEBUG: 'scene_changed' signal already connected (expected on subsequent _ready calls if any).")

	# If the game starts directly from a level (e.g., for testing),
	# try to find its index. This is mostly for development convenience.
	var initial_scene_path = get_tree().current_scene.scene_file_path
	current_level_index = level_paths.find(initial_scene_path)
	if current_level_index != -1:
		print("GameFlow: Started at level ", current_level_index + 1)
		# If starting directly in a level, try to connect to its WinZone if available
		_connect_to_win_zone()
	else:
		print("GameFlow: Not starting in a defined level path. Current scene: ", initial_scene_path)
		# If you start from MainMenu, this will be -1, which is fine.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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

func _on_level_completed():
	print("GameFlow: Current level completed!")
	load_level(current_level_index + 1)

# This function is called by the scene_changed signal from the SceneTree
func _on_scene_changed():
	# Attempt to connect to the WinZone in the newly loaded scene
	print("GameFlow DEBUG: Scene changed signal received. Attempting to connect WinZone in new scene.")
	_connect_to_win_zone()

func _connect_to_win_zone():
	# Find the WinZone in the current scene and connect its signal
	# We need to wait for the scene to be fully added to the tree
	print("GameFlow DEBUG: _connect_to_win_zone function called.")
	await get_tree().current_scene.ready

	var win_zone = get_tree().current_scene.find_child("WinZone", true, false)
	if win_zone:
		if not win_zone.is_connected("level_completed", Callable(self, "_on_level_completed")):
			win_zone.connect("level_completed", Callable(self, "_on_level_completed"))
			print("GameFlow: Connected to WinZone in current level.")
	else:
		print("GameFlow: No WinZone found in current level.")

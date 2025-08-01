# level_base.gd
# Attach this script to each level's root node
extends Node2D  # or Node3D if you're using 3D

@export var level_name = "Default"

func _ready():
	# Wait a frame to ensure all child nodes are fully initialized
	await get_tree().process_frame
	
	# Find the WinZone in this level
	var win_zone = find_child("WinZone", true, false)
	
	if win_zone:
		# Register this level's WinZone with the GameFlow manager
		GameFlow.register_level_completion(win_zone)
		print("Level: Found and registered WinZone with GameFlow")
	else:
		print("Level: Warning - No WinZone found in this level!")
		
	# You can add any other level-specific initialization here
	print("Level: ", scene_file_path, " is ready")

func get_locked_skills():
	match level_name:
		"Level 1":
			return ["ui_up", "ui_down"]
		"Level 2":
			return ["ui_up"]
		"Level 3":
			return []
		_:
			return []

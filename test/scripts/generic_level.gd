# level_base.gd
# Attach this script to each level's root node
extends Node2D  # or Node3D if you're using 3D

@export var level_name = "Default"
@export var level_number = 0
var win_zone_ref = null  # Store reference to win zone

func _ready():
	# Wait a frame to ensure all child nodes are fully initialized
	await get_tree().process_frame
	
	# Find the WinZone in this level
	var win_zone = find_child("WinZone", true, false)
	
	if win_zone:
		win_zone_ref = win_zone  # Store reference for debug win
		# Register this level's WinZone with the GameFlow manager
		GameFlow.register_level_completion(win_zone)
		print("Level: Found and registered WinZone with GameFlow")
	else:
		print("Level: Warning - No WinZone found in this level!")
	
	var player = find_child("Dachshund", true, false)
	if player:
		GameFlow.register_player(player)
		
	# You can add any other level-specific initialization here
	print("Level: ", scene_file_path, " is ready")

func _input(event):
	if event is InputEventKey and event.pressed:
		# Level restart shortcut - works in both debug and release builds
		if event.keycode == KEY_R and event.shift_pressed:
			print("Shift+R pressed - restarting current level!")
			GameFlow.restart_current_level()
		
		# Debug win shortcut - only works in debug builds
		if OS.is_debug_build():
			if event.keycode == KEY_W and event.shift_pressed:
				print("Debug: Shift+W pressed - triggering level win!")
				if win_zone_ref:
					win_zone_ref.level_completed.emit()
				else:
					# Fallback: directly tell GameFlow level is complete
					GameFlow._on_level_completed()

func get_locked_skills():
	match level_number:
		1:
			return ["move_up", "move_down"]
		2:
			return ["move_up"]
		3:
			return []
		_:
			return []

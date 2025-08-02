# main_menu.gd
extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var debug_button = $VBoxContainer/DebugButton

# Called when the node enters the scene tree for the first time.
func _ready():
	# --- Debug Button Visibility/Availability ---
	# This flag checks if the game is running inside the Godot editor.
	# When exported, Engine.is_editor_hint() will be false.
	# OS.is_debug_build() is true for debug exports, false for release exports.
	# Choose the one that best fits your "local testing/dev" definition.
	# For simplicity, Engine.is_editor_hint() is often good for "dev only" features.
	if OS.is_debug_build(): # This works for both editor AND local debug builds
		debug_button.show() # Make the debug button visible
		debug_button.set_process_mode(Node.PROCESS_MODE_INHERIT) # Ensure it's active
		print("Debug button visible for editor build.")
	else:
		debug_button.hide() # Hide the debug button in exported builds
		debug_button.set_process_mode(Node.PROCESS_MODE_DISABLED) # Disable its processing
		print("Debug button hidden for exported build.")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func _on_play_button_pressed():
#	print("Play button pressed! Loading Level 1...")
#	get_tree().change_scene_to_file(LEVEL_1_SCENE_PATH)
	
func _on_play_button_pressed():
	print("Play button pressed! Starting game flow...")
	# Tell the global GameFlow singleton to load the first level
	GameFlow.start_new_game() # Load the level at index 0 (Level1.tscn)

func _on_settings_button_pressed():
	print("Settings button pressed! (Implement settings menu here)")
	# You would typically load a settings scene here:
	# get_tree().change_scene_to_file("res://Scenes/UI/SettingsMenu.tscn")

func _on_debug_button_pressed():
	print("Debug button pressed! (Implement debug options here)")
	# Example: Toggle a debug overlay, print game state, etc.
	# This code will only run if the button is visible/active.
	# Load the debug menu scene as an overlay
	var debug_menu_scene = preload("res://scenes/ui/DebugMenu.tscn")
	var debug_menu_instance = debug_menu_scene.instantiate()
	
	# Add it as a child of the current scene (overlay)
	get_tree().current_scene.add_child(debug_menu_instance)
	
	# Optional: Pause the main menu or dim the background
	# get_tree().paused = true
	# modulate = Color(0.5, 0.5, 0.5, 1.0)  # Dim the main menu

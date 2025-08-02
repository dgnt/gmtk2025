# main_menu.gd
extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var debug_button = $VBoxContainer/DebugButton
@onready var skeleton = $Skeleton2D

# Hula hoop effect
var hula_hoop: HulaHoop
var current_hovered_button: Button = null
var hoop_phase: float = 0.0

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
	
	# Set up hula hoop effect
	setup_hula_hoop_effect()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if hula_hoop and hula_hoop.visible:
		# Update hoop rotation phase
		hoop_phase += delta * 8 * hula_hoop.get_speed_multiplier()
		if hoop_phase > TAU:
			hoop_phase -= TAU
		hula_hoop.current_phase = hoop_phase

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

func setup_hula_hoop_effect():
	# Create hula hoop using the factory
	hula_hoop = HulaHoopFactory.create_basic_hoop(skeleton)
	hula_hoop.name = "MenuHulaHoop"
	
	# Customize for menu use
	#hula_hoop.set_path_dimensions(50.0, 30.0)  # Smaller path for menu buttons
	#hula_hoop.set_hoop_dimensions(100.0, 60.0)  # Visual hoop size
	#hula_hoop.line_width = 12.0
	hula_hoop.visible = false
	
	add_child(hula_hoop)
	
	# Connect hover signals for all buttons
	play_button.mouse_entered.connect(_on_button_hover.bind(play_button, "PlayBone"))
	play_button.mouse_exited.connect(_on_button_unhover.bind(play_button))
	
	settings_button.mouse_entered.connect(_on_button_hover.bind(settings_button, "SettingsBone"))
	settings_button.mouse_exited.connect(_on_button_unhover.bind(settings_button))
	
	if debug_button.visible:
		debug_button.mouse_entered.connect(_on_button_hover.bind(debug_button, "DebugBone"))
		debug_button.mouse_exited.connect(_on_button_unhover.bind(debug_button))

func _on_button_hover(button: Button, bone_name: String):
	current_hovered_button = button
	
	# Update the hoop's target bone
	hula_hoop.set_target_bone(bone_name)
	hula_hoop.visible = true

func _on_button_unhover(button: Button):
	# Only hide if this is the currently hovered button
	if current_hovered_button == button:
		current_hovered_button = null
		
		# Small delay to allow for button-to-button transitions
		await get_tree().create_timer(0.1).timeout
		
		# Hide only if no button is hovered
		if current_hovered_button == null:
			hula_hoop.visible = false

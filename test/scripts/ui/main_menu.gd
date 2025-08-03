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
	if OS.is_debug_build():
		debug_button.show()
		debug_button.set_process_mode(Node.PROCESS_MODE_INHERIT)
		print("Debug button visible for editor build.")
	else:
		debug_button.hide()
		debug_button.set_process_mode(Node.PROCESS_MODE_DISABLED)
		print("Debug button hidden for exported build.")
	
	# Set up hula hoop effect FIRST
	setup_hula_hoop_effect()
	
	# Set up controller/keyboard navigation AFTER hula hoop is ready
	setup_focus_navigation()
	
	# Show hoop for initially focused button
	_on_button_focus_entered(play_button, "PlayBone")
	
	# Start menu music
	AudioManager.play_music("res://assets/audio/music/HoopDogMenu.ogg", -6.0, 0.5)

func setup_focus_navigation():
	# Ensure all buttons can receive focus
	play_button.focus_mode = Control.FOCUS_ALL
	settings_button.focus_mode = Control.FOCUS_ALL
	
	if debug_button.visible:
		debug_button.focus_mode = Control.FOCUS_ALL
		
		# Set up focus neighbors manually for reliable navigation
		play_button.focus_neighbor_top = play_button.get_path()  # Wrap to self at top
		play_button.focus_neighbor_bottom = settings_button.get_path()
		
		settings_button.focus_neighbor_top = play_button.get_path()
		settings_button.focus_neighbor_bottom = debug_button.get_path()
		
		debug_button.focus_neighbor_top = settings_button.get_path()
		debug_button.focus_neighbor_bottom = debug_button.get_path()  # Wrap to self at bottom
	else:
		# Only two buttons when debug is hidden
		play_button.focus_neighbor_top = play_button.get_path()
		play_button.focus_neighbor_bottom = settings_button.get_path()
		
		settings_button.focus_neighbor_top = play_button.get_path()
		settings_button.focus_neighbor_bottom = settings_button.get_path()
	
	# Set initial focus to play button
	play_button.grab_focus()
	
	# Connect focus signals to integrate with hula hoop effect
	play_button.focus_entered.connect(_on_button_focus_entered.bind(play_button, "PlayBone"))
	play_button.focus_exited.connect(_on_button_focus_exited.bind(play_button))
	
	settings_button.focus_entered.connect(_on_button_focus_entered.bind(settings_button, "SettingsBone"))
	settings_button.focus_exited.connect(_on_button_focus_exited.bind(settings_button))
	
	if debug_button.visible:
		debug_button.focus_entered.connect(_on_button_focus_entered.bind(debug_button, "DebugBone"))
		debug_button.focus_exited.connect(_on_button_focus_exited.bind(debug_button))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if hula_hoop and hula_hoop.visible:
		# Update hoop rotation phase
		hoop_phase += delta * 8 * hula_hoop.get_speed_multiplier()
		if hoop_phase > TAU:
			hoop_phase -= TAU
		hula_hoop.current_phase = hoop_phase

func _on_play_button_pressed():
	print("Play button pressed! Starting game flow...")
	# Stop menu music before transitioning
	AudioManager.stop_music(0.3)
	# Tell the global GameFlow singleton to load the first level
	GameFlow.start_new_game()

func _on_settings_button_pressed():
	print("Settings button pressed! (Implement settings menu here)")

func _on_debug_button_pressed():
	print("Debug button pressed! Loading debug menu...")
	var debug_menu_scene = preload("res://scenes/ui/DebugMenu.tscn")
	var debug_menu_instance = debug_menu_scene.instantiate()
	get_tree().current_scene.add_child(debug_menu_instance)

func _exit_tree():
	AudioManager.stop_music(0.2)

func setup_hula_hoop_effect():
	# Create hula hoop using the factory
	hula_hoop = HulaHoopFactory.create_basic_hoop(skeleton)
	hula_hoop.name = "MenuHulaHoop"
	hula_hoop.visible = false
	add_child(hula_hoop)
	
	# Connect hover signals for mouse users
	play_button.mouse_entered.connect(_on_button_hover.bind(play_button, "PlayBone"))
	play_button.mouse_exited.connect(_on_button_unhover.bind(play_button))
	
	settings_button.mouse_entered.connect(_on_button_hover.bind(settings_button, "SettingsBone"))
	settings_button.mouse_exited.connect(_on_button_unhover.bind(settings_button))
	
	if debug_button.visible:
		debug_button.mouse_entered.connect(_on_button_hover.bind(debug_button, "DebugBone"))
		debug_button.mouse_exited.connect(_on_button_unhover.bind(debug_button))

# Mouse hover handlers (existing)
func _on_button_hover(button: Button, bone_name: String):
	current_hovered_button = button
	hula_hoop.set_target_bone(bone_name)
	hula_hoop.visible = true

func _on_button_unhover(button: Button):
	if current_hovered_button == button:
		current_hovered_button = null
		await get_tree().create_timer(0.1).timeout
		if current_hovered_button == null:
			hula_hoop.visible = false

# Focus handlers for controller/keyboard navigation
func _on_button_focus_entered(button: Button, bone_name: String):
	# Show hula hoop when button gets focus via keyboard/controller
	if current_hovered_button == null:  # Only if not already shown by mouse
		current_hovered_button = button
		hula_hoop.set_target_bone(bone_name)
		hula_hoop.visible = true

func _on_button_focus_exited(button: Button):
	# Hide hula hoop when button loses focus (if it was the focused one)
	if current_hovered_button == button:
		current_hovered_button = null
		# Small delay to handle focus transitions
		await get_tree().create_timer(0.05).timeout
		if current_hovered_button == null:
			hula_hoop.visible = false

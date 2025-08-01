# debug_menu.gd
extends Control

@onready var level_button_container = $VBoxContainer/ScrollContainer/LevelButtonContainer
@onready var close_button = $VBoxContainer/CloseButton

func _ready():
	# Set the debug menu size and position
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(300, 400)
	size = Vector2(300, 400)
	
	# Generate level buttons based on GameFlow's level paths
	create_level_buttons()
	
	# Connect close button
	close_button.pressed.connect(_on_close_button_pressed)

func create_level_buttons():
	# Clear any existing buttons
	for child in level_button_container.get_children():
		child.queue_free()
	
	# Wait a frame to ensure old buttons are removed
	await get_tree().process_frame
	
	# Create a button for each level in GameFlow
	for i in range(GameFlow.get_total_levels()):
		var button = Button.new()
		button.text = "Level " + str(i + 1)
		button.custom_minimum_size = Vector2(200, 40)  # Set minimum button size
		button.pressed.connect(_on_level_button_pressed.bind(i))
		level_button_container.add_child(button)
		print("Created button for level ", i + 1)  # Debug print
	
	# Add a button to go to main menu
	var main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.custom_minimum_size = Vector2(200, 40)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	level_button_container.add_child(main_menu_button)

func _on_level_button_pressed(level_index: int):
	print("Debug: Loading level ", level_index + 1)
	GameFlow.load_level(level_index)

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_close_button_pressed():
	queue_free()

# Allow ESC key to close the debug menu
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_button_pressed()

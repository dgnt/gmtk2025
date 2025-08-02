# game_complete.gd
extends Control

@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var message_label = $CenterContainer/VBoxContainer/MessageLabel
@onready var play_again_button = $CenterContainer/VBoxContainer/ButtonContainer/PlayAgainButton
@onready var main_menu_button = $CenterContainer/VBoxContainer/ButtonContainer/MainMenuButton

# Path to your main menu scene
const MAIN_MENU_SCENE_PATH = "res://scenes/ui/MainMenu.tscn"

func _ready():
	# Set up the UI text
	title_label.text = "Congratulations!"
	message_label.text = "You have completed all " + str(GameFlow.get_total_levels()) + " levels!\nThanks for playing!"
	
	# Connect button signals
	play_again_button.pressed.connect(_on_play_again_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Optional: Add some celebration effects
	celebrate()
	
	print("GameComplete: Scene loaded successfully")

func celebrate():
	# Optional: Add some visual flair
	# You could add particle effects, animations, etc. here
	
	# Simple example: Make the title label pulse
	var tween = create_tween()
	tween.set_loops() # Loop forever
	tween.tween_property(title_label, "modulate:a", 0.7, 1.0)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)

func _on_play_again_pressed():
	print("GameComplete: Play Again pressed - starting new game")
	GameFlow.start_new_game()

func _on_main_menu_pressed():
	print("GameComplete: Main Menu pressed - returning to main menu")
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

# Optional: Handle input for keyboard/gamepad users
func _input(event):
	if event.is_action_pressed("ui_accept"): # Usually Enter or gamepad A
		_on_play_again_pressed()
	elif event.is_action_pressed("ui_cancel"): # Usually Escape or gamepad B
		_on_main_menu_pressed()

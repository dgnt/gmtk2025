# splash_screen.gd
extends Control # Or Node2D if you didn't change the root

@onready var animation_player = $AnimationPlayer
@onready var canvas_modulate = $CanvasModulate

# Define the path to your main game scene (Level1.tscn or MainMenu.tscn)
const NEXT_SCENE_PATH = "res://Scenes/Level.tscn" # CHANGE THIS to your actual first game scene!

# Called when the node enters the scene tree for the first time.
func _ready():
	# --- Local Testing/Dev Flag ---
	# Engine.is_editor_hint() is true when running in the Godot editor.
	# OS.is_debug_build() is true when exported as a debug build.
	# Use whichever makes more sense for your workflow.
	if Engine.is_editor_hint(): # Skips splash screen when running from editor
		print("Skipping splash screen for editor run.")
		# Immediately load the next scene
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
		return # Exit _ready function early

	# If not in editor, play the splash animation
	canvas_modulate.color.a = 0.0 # Start fully transparent
	animation_player.play("fade_logo")

func _on_animation_player_animation_finished(anim_name):
	# This function is called when the "fade_logo" animation finishes
	if anim_name == "fade_logo":
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)

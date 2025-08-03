extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D):
	# Check if the entered body is our player
	# You can use 'is_in_group("player")' if your player is in a "player" group
	# Or check its class_name if you've defined one (e.g., 'if body is Player:')
	# For now, let's assume anything that enters triggers it, or check its name.
	if body.name == "Dachshund": # Assuming your player node is named "Dachshund"
		body.hoop_control_allowed = true
		hide()
		queue_free()
		
		UIOverlay.display_overlay_text_message("Up tilt unlocked!", 8)

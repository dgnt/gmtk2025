# win_zone.gd
extends Area2D

# Define a signal that this WinZone will emit when the level is completed
# The GameFlow autoload will listen for this signal.
signal level_completed

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the body_entered signal to our custom function
	body_entered.connect(_on_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D):
	# Check if the entered body is our player
	# You can use 'is_in_group("player")' if your player is in a "player" group
	# Or check its class_name if you've defined one (e.g., 'if body is Player:')
	# For now, let's assume anything that enters triggers it, or check its name.
	if body.name == "Dachshund": # Assuming your player node is named "Dachshund"
		print("WinZone: Player entered! Level completed.")
		level_completed.emit() # Emit the signal
		# To prevent multiple triggers, you might want to disable the WinZone
		# or remove it after it's been triggered once.
		set_deferred("monitoring", false) # Disable monitoring after first trigger
		set_deferred("process_mode", Node.PROCESS_MODE_DISABLED) # Disable script processing

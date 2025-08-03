extends "res://scripts/levels/generic_level.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	var dachshund = find_child("Dachshund", true, false)

	dachshund.hypercharge_allowed = false
	dachshund.helicopter_allowed = false
	dachshund.snap_allowed = false
	dachshund.hoop_control_allowed = true
	dachshund.hoop_on = true
	
	$Level5Ring/Ring.color = Color(1.0, 1.0, 0.0)
	
	var canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.3, 0.3, 0.4, 1)  # Dark blue-ish night
	add_child(canvas_modulate)
	
	# Make sure hoop light starts OFF in Level 5
	# It will be turned on when the ring is collected
	if dachshund:
		var hoop = dachshund.hoop_instance
		if hoop:
			hoop.set_light_enabled(false)  # Start with light OFF
			print("Level 5: Hoop light disabled - will enable when ring collected")
		else:
			print("Level 5: No hoop instance found on Dachshund")
	else:
		print("Level 5: No Dachshund found")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

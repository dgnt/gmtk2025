extends "res://scripts/levels/generic_level.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	
	var canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.3, 0.3, 0.4, 1)  # Dark blue-ish night
	add_child(canvas_modulate)
	
	# Enable hoop light for this level
	var dachshund = find_child("Dachshund", true, false)
	if dachshund:
		var hoop = dachshund.hoop_instance
		if hoop:
			hoop.set_light_enabled(true)
			# Optional: customize light properties for this level
			hoop.set_light_energy(1.5)
			hoop.set_light_texture_scale(20)
			hoop.set_light_color(Color(1, 0.7, 0.4, 1))  # Warmer glow
			print("Level 6: Enabled hoop light")
		else:
			print("Level 6: No hoop instance found on Dachshund")
	else:
		print("Level 6: No Dachshund found or no hoop_instance property")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

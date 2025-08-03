extends "res://scripts/levels/generic_level.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	$Dachshund.hypercharge_allowed = false
	$Dachshund.helicopter_allowed = false
	$Dachshund.snap_allowed = false
	$Dachshund.hoop_control_allowed = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

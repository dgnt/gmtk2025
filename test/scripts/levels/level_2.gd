extends "res://scripts/levels/generic_level.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	$Dachshund.hypercharge_allowed = false
	$Dachshund.helicopter_allowed = false
	$Dachshund.snap_allowed = false
	$Dachshund.hoop_control_allowed = false
	var zoom = 1.7
	$Dachshund/Camera.zoom = Vector2(zoom,zoom)
	$Dachshund/Camera.limit_right = $Dachshund/Camera.limit_left + int(Constants.GAMESIZE.x / zoom) + 1
	#$Dachshund/Camera.limit_top /= zoom
	for child in find_children("", "Parallax2D"):
		if child.name.begins_with("Clouds"):
			continue
		child.scroll_offset.y = (-Constants.GAMESIZE.y / 2 + 32) * child.scroll_scale.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

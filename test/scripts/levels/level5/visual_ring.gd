@tool
extends Node2D

@export var color: Color = Color.YELLOW

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _draw():
	var radius = 40 # Radius of the circle
	draw_circle(Vector2(0,0), radius, color, false, 5)
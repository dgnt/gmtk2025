extends Node2D

@export var width: float = 100.0
@export var target_bone: Bone2D

var time: float = 0.0
var duration: float = 3.0

func _ready():
	set_process(true)

func _process(delta):
	if not target_bone:
		return
		
	time += delta
	if time > duration:
		time -= duration
	
	# Calculate position on ellipse
	var t = (time / duration) * TAU
	var height = width / 5.0
	var x_offset = (width / 2.0) * cos(t)
	var y_offset = (height / 2.0) * sin(t)
	
	queue_redraw()

func _draw():
	if not target_bone:
		return
		
	# Draw the elliptical path centered on the bone
	var center = target_bone.global_position - global_position
	var height = width / 5.0
	
	# Draw ellipse outline
	var points = []
	for i in range(32):
		var angle = (i / 32.0) * TAU
		var x = center.x + (width / 2.0) * cos(angle)
		var y = center.y + (height / 2.0) * sin(angle)
		points.append(Vector2(x, y))
	
	for i in range(points.size()):
		var next = (i + 1) % points.size()
		draw_line(points[i], points[next], Color.CYAN, 2.0)
	
	# Draw current position
	var t = (time / duration) * TAU
	var current_x = center.x + (width / 2.0) * cos(t)
	var current_y = center.y + (height / 2.0) * sin(t)
	draw_circle(Vector2(current_x, current_y), 5.0, Color.RED)
	
	# Draw center
	draw_circle(center, 3.0, Color.GREEN)
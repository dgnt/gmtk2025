extends Area2D

@export var move_distance: float = 200.0
@export var move_duration: float = 2.0

var start_position: Vector2
var tween: Tween
var path_follow: PathFollow2D
var direction: int = 1  # 1 for forward, -1 for backward
@export var speed: float = 150.0


func _ready():
	pass
	#body_entered.connect(_on_body_entered)
	#get_parent().autoscroll = true
#	start_position = global_position
#	start_movement()

func _process(delta):
	var parent = get_parent()
	if parent is PathFollow2D:
		path_follow = get_parent() as PathFollow2D
		#get_parent().progress += delta*50
		path_follow.progress += speed * delta * direction
		# Check if we've reached the end or beginning
		if path_follow.progress_ratio >= 1.0:
			direction = -1  # Go backward
		elif path_follow.progress_ratio <= 0.0:
			direction = 1   # Go forward

func start_movement():
	tween = create_tween()
	tween.set_loops()  # Loop forever
	
	# Move to the right
	tween.tween_property(self, "global_position:x", start_position.x + move_distance, move_duration)
	# Move back to the left
	tween.tween_property(self, "global_position:x", start_position.x, move_duration)

func _on_body_entered(body):
	if body.has_method("die"):
		body.die()

extends CharacterBody2D

@export var speed = 100.0
@export var jump_velocity = -400.0
const REV_TIME = 800  # ms
const HOOP_SPEED = 90
var rev = 0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		rev += delta * 1000 / REV_TIME * 2 * PI
		while rev > 2 * PI:
			rev -= 2 * PI
		

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed + sin(rev) * HOOP_SPEED 
	else:
		velocity.x = move_toward(velocity.x, sin(rev) * HOOP_SPEED, speed)

	move_and_slide()

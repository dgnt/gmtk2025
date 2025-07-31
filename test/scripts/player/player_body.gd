extends CharacterBody2D

@export var speed = 200.0
@export var jump_velocity = -400.0
const REV_TIME = 800  # ms
const HOOP_SPEED = 200
const STABILITY = 150
var rev = 0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		rev += delta * 1000 / REV_TIME * 2 * PI
		while rev > 2 * PI:
			rev -= 2 * PI
	var hoop_v = sin(rev) * HOOP_SPEED
	if is_on_floor():
		if abs(hoop_v) < STABILITY:
			hoop_v = 0
		elif hoop_v > 0:
			hoop_v -= STABILITY
		else:
			hoop_v += STABILITY
		

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed + hoop_v
	else:
		velocity.x = move_toward(velocity.x, hoop_v, speed)

	move_and_slide()

extends Bone2D

# Physics properties
@export var gravity_scale: float = 0.4
@export var air_damping: float = 0.92
@export var spring_strength: float = 35.0
@export var spring_damping: float = 4.0
@export var max_angle: float = 60.0  # Maximum rotation in degrees
@export var float_impulse: float = 25.0  # Upward force when falling
@export var bounce_impulse: float = 30.0  # Downward force on landing
@export var horizontal_influence: float = 0.3  # How much horizontal movement affects ears
@export var is_left_ear: bool = true  # Set to false for right ear

# Internal state
var angular_velocity: float = 0.0
var rest_rotation: float = 0.0
var character_body: CharacterBody2D = null
var was_on_floor: bool = true
var current_angle: float = 0.0
var dachshund_script = null

func _ready() -> void:
	rest_rotation = rotation
	print("Floppy ear script ready! Is left ear: ", is_left_ear)
	# Find the CharacterBody2D parent
	var parent = get_parent()
	while parent != null:
		if parent is CharacterBody2D:
			character_body = parent
			dachshund_script = parent
			print("Found character body!")
			break
		parent = parent.get_parent()

func _physics_process(delta: float) -> void:
	if not character_body:
		return
		
	# Get velocity and floor state
	var velocity_y = character_body.velocity.y
	var velocity_x = character_body.velocity.x
	var on_floor = character_body.is_on_floor()
	
	# Check for special states
	var is_helicoptering = dachshund_script.helicoptering if dachshund_script else false
	var hypercharge_level = dachshund_script.hypercharge if dachshund_script else 0.0
	
	# Special behavior for helicopter mode
	if is_helicoptering:
		# Ears spin outward during helicopter
		var spin_force = 50.0
		if is_left_ear:
			angular_velocity -= spin_force * delta
		else:
			angular_velocity += spin_force * delta
		# Reduce spring strength during helicopter
		var angle_diff = rest_rotation - current_angle
		var spring_force = angle_diff * (spring_strength * 0.2) - angular_velocity * spring_damping
		angular_velocity += spring_force * delta
	# Special behavior for hypercharge
	elif hypercharge_level > 0:
		# Ears vibrate during charge
		var vibration = sin(Time.get_ticks_msec() * 0.02) * hypercharge_level * 10.0
		angular_velocity += vibration * delta
		# Normal spring force
		var angle_diff = rest_rotation - current_angle
		var spring_force = angle_diff * spring_strength - angular_velocity * spring_damping
		angular_velocity += spring_force * delta
	# Normal physics
	else:
		# Apply floating effect when falling
		if velocity_y > 0:  # Falling down
			# Apply upward impulse scaled by fall speed
			var float_force = min(velocity_y * 0.001, 1.0) * float_impulse
			angular_velocity -= float_force * delta
		
		# Add horizontal movement influence
		var horizontal_force = velocity_x * horizontal_influence * 0.001
		if is_left_ear:
			angular_velocity += horizontal_force * delta
		else:
			angular_velocity -= horizontal_force * delta
		
		# Detect landing for bounce effect
		if on_floor and not was_on_floor and velocity_y >= 0:
			# Apply downward bounce impulse
			angular_velocity += bounce_impulse * delta
			# Add some randomness to make it more natural
			angular_velocity += randf_range(-5.0, 5.0)
		
		# Spring force to return to rest position
		var angle_diff = rest_rotation - current_angle
		var spring_force = angle_diff * spring_strength - angular_velocity * spring_damping
		angular_velocity += spring_force * delta
	
	# Apply gravity (for all modes)
	angular_velocity += gravity_scale * 9.8 * sin(current_angle) * delta
	
	# Apply air damping
	angular_velocity *= air_damping
	
	# Update angle
	current_angle += angular_velocity * delta
	
	# Clamp to maximum angle
	var max_angle_rad = deg_to_rad(max_angle)
	current_angle = clamp(current_angle, -max_angle_rad, max_angle_rad)
	
	# Apply rotation
	rotation = current_angle
	
	# Debug output every 60 frames (approximately once per second)
	if Engine.get_physics_frames() % 60 == 0 and is_left_ear:
		print("Ear physics - velocity_y: ", velocity_y, " angle: ", rad_to_deg(current_angle), " angular_vel: ", angular_velocity)
	
	# Store floor state for next frame
	was_on_floor = on_floor
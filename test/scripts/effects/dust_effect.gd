extends CPUParticles2D

const MIN_VELOCITY_THRESHOLD = 300.0
const MAX_PARTICLES = 50
const BASE_PARTICLES = 10
const VELOCITY_TO_PARTICLE_SCALE = 0.02
const HORIZONTAL_SPREAD_SCALE = 0.1

func emit_dust(landing_velocity: Vector2, collision_point: Vector2 = Vector2.ZERO) -> void:
	var velocity_magnitude = landing_velocity.length()
	
	print("Dust effect - Velocity magnitude: ", velocity_magnitude, " Threshold: ", MIN_VELOCITY_THRESHOLD)
	
	if velocity_magnitude < MIN_VELOCITY_THRESHOLD:
		print("Velocity too low, not emitting dust")
		return
	
	global_position = collision_point
	
	var normalized_velocity = (velocity_magnitude - MIN_VELOCITY_THRESHOLD) / 1000.0
	normalized_velocity = clamp(normalized_velocity, 0.0, 1.0)
	
	amount = int(BASE_PARTICLES + (MAX_PARTICLES - BASE_PARTICLES) * normalized_velocity)
	
	initial_velocity_min = 50.0 + 100.0 * normalized_velocity
	initial_velocity_max = 100.0 + 200.0 * normalized_velocity
	
	var horizontal_influence = abs(landing_velocity.x) * HORIZONTAL_SPREAD_SCALE
	emission_rect_extents.x = 20.0 + horizontal_influence
	
	if landing_velocity.x != 0:
		var horizontal_angle = -sign(landing_velocity.x) * min(abs(landing_velocity.x) / 500.0, 0.3)
		direction = Vector2(horizontal_angle, -1).normalized()
	else:
		direction = Vector2(0, -1)
	
	spread = 30.0 + 30.0 * normalized_velocity
	
	scale_amount_min = 0.3 + 0.3 * normalized_velocity
	scale_amount_max = 0.8 + 0.7 * normalized_velocity
	
	print("Emitting ", amount, " particles at position ", global_position)
	print("Initial velocity range: ", initial_velocity_min, " to ", initial_velocity_max)
	
	restart()
	emitting = true
	
	await finished
	queue_free()
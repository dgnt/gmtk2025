extends Area2D

@export var ring_color: Color = Color.YELLOW
@export var light_energy_min: float = 0.1
@export var light_energy_max: float = 2.0
@export var pulse_speed: float = 1.3

var ring_light: PointLight2D
var time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Create pulsing light
	setup_ring_light()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	
	# Pulse the light
	if ring_light:
		var pulse_value = (sin(time * pulse_speed) + 1.0) / 2.0  # 0 to 1
		ring_light.energy = lerp(light_energy_min, light_energy_max, pulse_value)


func setup_ring_light():
	ring_light = PointLight2D.new()
	ring_light.name = "RingLight"
	ring_light.color = Color(1, 1, 0.5, 1)  # Bright yellow
	ring_light.energy = light_energy_max
	ring_light.texture_scale = 3.0
	ring_light.z_index = -1  # Behind the ring visual
	
	# Use default gradient texture
	var light_texture = preload("res://assets/images/City/light-medium.png") if ResourceLoader.exists("res://assets/images/City/light-medium.png") else null
	if light_texture:
		ring_light.texture = light_texture
	
	add_child(ring_light)


func _on_body_entered(body: Node2D):
	# Check if the entered body is our player
	# You can use 'is_in_group("player")' if your player is in a "player" group
	# Or check its class_name if you've defined one (e.g., 'if body is Player:')
	# For now, let's assume anything that enters triggers it, or check its name.
	if body.name == "Dachshund": # Assuming your player node is named "Dachshund"
		body.hoop_on = true
		
		# Change hoop color to yellow and enable light
		if body.hoop_instance:
			# Set colors to yellow
			body.hoop_instance.set_colors(Color.YELLOW, Color(0.8, 0.8, 0, 1))  # Yellow front, darker yellow back
			
			# Enable the light
			body.hoop_instance.set_light_enabled(true)
			body.hoop_instance.set_light_energy(1.5)
			body.hoop_instance.set_light_color(Color(1, 1, 0.5, 1))  # Bright yellow light
			body.hoop_instance.set_light_texture_scale(10)
			
			print("Level 5: Ring collected - Rubber Band Double Jump Enabled")
			body.snap_allowed = true
		
		hide()
		queue_free()

extends Object
class_name HulaHoopFactory

# Factory method to create hula hoops
static func create_hoop(skeleton: Skeleton2D, params: Dictionary = {}) -> HulaHoop:
	# Load the HulaHoop scene
	var hoop_scene = preload("res://scenes/objects/HulaHoop.tscn")
	var hoop_instance = hoop_scene.instantiate() as HulaHoop
	
	# Apply parameters
	if params.has("radius"):
		hoop_instance.radius = params.radius
	
	if params.has("speed"):
		hoop_instance.speed = params.speed
	
	if params.has("target_bone_path"):
		hoop_instance.target_bone_path = params.target_bone_path
	
	if params.has("tilt_angle"):
		hoop_instance.tilt_angle = clamp(params.tilt_angle, -45.0, 45.0)
	
	if params.has("ellipse_ratio"):
		hoop_instance.ellipse_ratio = params.ellipse_ratio
	
	if params.has("color_front"):
		hoop_instance.color_front = params.color_front
	
	if params.has("color_back"):
		hoop_instance.color_back = params.color_back
	
	if params.has("line_width"):
		hoop_instance.line_width = params.line_width
	
	# Initialize with skeleton
	hoop_instance.initialize(skeleton)
	
	return hoop_instance

# Preset factory methods for common hoop types
static func create_basic_hoop(skeleton: Skeleton2D) -> HulaHoop:
	return create_hoop(skeleton, {
		"radius": 80.0,
		"speed": 1.0,
		"color_front": Color.RED,
		"color_back": Color.DARK_RED
	})

static func create_large_hoop(skeleton: Skeleton2D) -> HulaHoop:
	return create_hoop(skeleton, {
		"radius": 120.0,
		"speed": 0.8,
		"color_front": Color.BLUE,
		"color_back": Color.DARK_BLUE,
		"line_width": 10.0
	})

static func create_small_fast_hoop(skeleton: Skeleton2D) -> HulaHoop:
	return create_hoop(skeleton, {
		"radius": 60.0,
		"speed": 2.0,
		"color_front": Color.YELLOW,
		"color_back": Color.ORANGE,
		"line_width": 6.0
	})

static func create_tilted_hoop(skeleton: Skeleton2D, tilt: float = 20.0) -> HulaHoop:
	return create_hoop(skeleton, {
		"radius": 90.0,
		"speed": 1.2,
		"tilt_angle": tilt,
		"color_front": Color.MAGENTA,
		"color_back": Color.PURPLE
	})

# Create multiple hoops at once
static func create_hoop_set(skeleton: Skeleton2D, count: int = 3, spacing: float = 30.0) -> Array:
	var hoops = []
	var base_radius = 70.0
	var speed_increment = 0.2
	
	for i in range(count):
		var hoop = create_hoop(skeleton, {
			"radius": base_radius + (i * spacing),
			"speed": 1.0 + (i * speed_increment),
			"color_front": Color.from_hsv(float(i) / count, 1.0, 1.0),
			"color_back": Color.from_hsv(float(i) / count, 1.0, 0.5)
		})
		hoops.append(hoop)
	
	return hoops

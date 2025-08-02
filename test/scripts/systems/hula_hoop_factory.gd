extends Object
class_name HulaHoopFactory

# Factory method to create hula hoops
static func create_hoop(skeleton: Skeleton2D, params: Dictionary = {}) -> HulaHoop:
	# Load the HulaHoop scene
	var hoop_scene = preload("res://scenes/objects/HulaHoop.tscn")
	var hoop_instance = hoop_scene.instantiate() as HulaHoop
	
	# Apply parameters
	if params.has("path_width"):
		hoop_instance.path_width = params.path_width
	
	if params.has("path_height"):
		hoop_instance.path_height = params.path_height
	
	if params.has("hoop_width"):
		hoop_instance.hoop_width = params.hoop_width
	
	if params.has("hoop_height"):
		hoop_instance.hoop_height = params.hoop_height
	
	if params.has("speed_multiplier"):
		hoop_instance.speed_multiplier = params.speed_multiplier
	
	if params.has("target_bone_path"):
		hoop_instance.target_bone_path = params.target_bone_path
	
	if params.has("tilt_angle"):
		hoop_instance.tilt_angle = clamp(params.tilt_angle, -89.0, 89.0)
	
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
		"path_width": 60.0,
		"path_height": 6.0,
		"hoop_width": 600.0,
		"hoop_height": 60.0,
		"speed_multiplier": 1.0,
		"color_front": Color.RED,
		"color_back": Color.DARK_RED,
		"target_bone_path": ""  # No target bone for menu
	})

static func create_large_hoop(skeleton: Skeleton2D) -> HulaHoop:
	return create_hoop(skeleton, {
		"path_width": 120.0,
		"path_height": 72.0,
		"hoop_width": 30.0,
		"hoop_height": 18.0,
		"speed_multiplier": 0.8,
		"color_front": Color.BLUE,
		"color_back": Color.DARK_BLUE,
		"line_width": 10.0
	})

static func create_small_fast_hoop(skeleton: Skeleton2D) -> HulaHoop:
	return create_hoop(skeleton, {
		"path_width": 60.0,
		"path_height": 36.0,
		"hoop_width": 15.0,
		"hoop_height": 9.0,
		"speed_multiplier": 2.0,
		"color_front": Color.YELLOW,
		"color_back": Color.ORANGE,
		"line_width": 6.0
	})

static func create_tilted_hoop(skeleton: Skeleton2D, tilt: float = 20.0) -> HulaHoop:
	return create_hoop(skeleton, {
		"path_width": 90.0,
		"path_height": 54.0,
		"hoop_width": 22.0,
		"hoop_height": 13.0,
		"speed_multiplier": 1.2,
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
		var width = base_radius + (i * spacing)
		var hoop = create_hoop(skeleton, {
			"path_width": width,
			"path_height": width * 0.6,
			"hoop_width": 20.0,
			"hoop_height": 12.0,
			"speed_multiplier": 1.0 + (i * speed_increment),
			"color_front": Color.from_hsv(float(i) / count, 1.0, 1.0),
			"color_back": Color.from_hsv(float(i) / count, 1.0, 0.5)
		})
		hoops.append(hoop)
	
	return hoops

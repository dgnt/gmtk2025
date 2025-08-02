extends Node2D
class_name HulaHoop

const HulaHoopResource = preload("res://scripts/systems/hula_hoop.gd")

# Core properties
@export var radius: float = 80.0
@export var speed: float = 1.0  # Revolutions per second
@export var target_bone_path: String = "CenterBone/LowerSpine"
@export var tilt_angle: float = 0.0  # Degrees, -45 to 45
@export var ellipse_ratio: float = 0.6  # Width/height ratio for perspective

# Visual properties
@export var color_front: Color = Color(1, 0.109804, 0.0588235, 1)  # Bright red
@export var color_back: Color = Color(0.556863, 0.121569, 0.141176, 1)  # Dark red
@export var line_width: float = 8.0

# References
var skeleton_ref: Skeleton2D
var target_bone: Bone2D
var hoop_system: HulaHoopSystem
var visual_node: Node2D
var path_2d: Path2D
var path_follow: PathFollow2D
var front_line: Line2D
var back_line: Line2D

# Internal state
var current_phase: float = 0.0
var bone_data: Dictionary = {}
var all_bones: Array = []

func _ready():
	# Set up visual components
	setup_visual_components()
	
	# Create hoop system for bone manipulation
	setup_hoop_system()

func setup_visual_components():
	# Create visual container
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	add_child(visual_node)
	
	# Create Path2D with elliptical curve
	path_2d = Path2D.new()
	path_2d.name = "Path2D"
	visual_node.add_child(path_2d)
	
	# Create PathFollow2D
	path_follow = PathFollow2D.new()
	path_follow.name = "PathFollow2D"
	path_follow.rotates = false
	path_2d.add_child(path_follow)
	
	# Create hoop mesh container
	var hoop_mesh = Node2D.new()
	hoop_mesh.name = "HoopMesh"
	path_follow.add_child(hoop_mesh)
	
	# Create back half line
	back_line = Line2D.new()
	back_line.name = "BackHalf"
	back_line.z_index = -2
	back_line.width = line_width
	back_line.default_color = color_back
	hoop_mesh.add_child(back_line)
	
	# Create front half line
	front_line = Line2D.new()
	front_line.name = "FrontHalf"
	front_line.z_index = 4
	front_line.width = line_width
	front_line.default_color = color_front
	hoop_mesh.add_child(front_line)
	
	# Update the visual
	update_hoop_visual()

func setup_hoop_system():
	# Create HulaHoopSystem node
	hoop_system = HulaHoopSystem.new()
	hoop_system.name = "BoneManipulator"
	add_child(hoop_system)
	
	# Create HulaHoop resource
	var hoop_resource = HulaHoopResource.new()
	hoop_resource.radius = radius
	hoop_resource.speed = speed * TAU  # Convert to radians/second
	hoop_resource.ellipse_ratio = ellipse_ratio
	
	hoop_system.hoop = hoop_resource
	hoop_system.target_bone_path = target_bone_path
	hoop_system.enabled = true
	hoop_system.max_distance = 1  # Only affect target bone and immediate neighbors

func initialize(skeleton: Skeleton2D):
	skeleton_ref = skeleton
	
	# Ensure visual components are set up
	if not visual_node:
		setup_visual_components()
	
	# Ensure hoop system is created if not already
	if not hoop_system:
		setup_hoop_system()
	
	# Initialize hoop system with skeleton
	if hoop_system:
		hoop_system.initialize(skeleton)
		
	# Find and set target bone
	if target_bone_path and skeleton:
		target_bone = skeleton.get_node(target_bone_path) as Bone2D
		if target_bone:
			cache_bone_data()

func cache_bone_data():
	# This mirrors the logic from HulaHoopSystem
	bone_data.clear()
	all_bones.clear()
	
	all_bones = get_all_bones(skeleton_ref)
	
	for bone in all_bones:
		var distance = calculate_bone_distance(bone, target_bone)
		bone_data[bone] = {
			"rest_position": bone.position,
			"distance": distance,
			"affected": distance <= hoop_system.max_distance
		}

func get_all_bones(node: Node) -> Array:
	var bones = []
	for child in node.get_children():
		if child is Bone2D:
			bones.append(child)
			bones.append_array(get_all_bones(child))
		else:
			bones.append_array(get_all_bones(child))
	return bones

func calculate_bone_distance(bone: Bone2D, target: Bone2D) -> int:
	if bone == target:
		return 0
	
	# Check if bone is ancestor of target
	var current = target.get_parent()
	var distance = 1
	while current != null:
		if current == bone:
			return distance
		if current is Bone2D:
			distance += 1
		current = current.get_parent()
	
	# Check if bone is descendant of target
	var ancestors_of_bone = []
	current = bone.get_parent()
	while current != null:
		if current == target:
			return count_bone_steps(target, bone)
		ancestors_of_bone.append(current)
		current = current.get_parent()
	
	# Find common ancestor
	var ancestors_of_target = []
	current = target.get_parent()
	while current != null:
		if current in ancestors_of_bone:
			var dist_to_target = count_bone_steps(current, target)
			var dist_to_bone = count_bone_steps(current, bone)
			return dist_to_target + dist_to_bone
		ancestors_of_target.append(current)
		current = current.get_parent()
	
	return 999

func count_bone_steps(ancestor: Node, descendant: Node) -> int:
	var steps = 0
	var current = descendant
	while current != ancestor and current != null:
		if current is Bone2D:
			steps += 1
		current = current.get_parent()
	return steps

func update_hoop_visual():
	if not path_2d:
		return
	
	# Create elliptical curve with tilt
	var curve = Curve2D.new()
	var points = []
	var segments = 4  # For smooth ellipse with bezier handles
	
	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		var x = cos(angle) * radius
		var y = sin(angle) * radius * ellipse_ratio
		
		# Apply tilt rotation
		var tilted = rotate_point(Vector2(x, y), deg_to_rad(tilt_angle))
		points.append(tilted)
	
	# Add points with bezier handles for smooth curve
	var handle_length = radius * 0.55  # Magic number for circular bezier
	
	# Right
	curve.add_point(points[0], Vector2(0, -handle_length * ellipse_ratio).rotated(deg_to_rad(tilt_angle)), 
					Vector2(0, handle_length * ellipse_ratio).rotated(deg_to_rad(tilt_angle)))
	# Bottom
	curve.add_point(points[1], Vector2(handle_length, 0).rotated(deg_to_rad(tilt_angle)), 
					Vector2(-handle_length, 0).rotated(deg_to_rad(tilt_angle)))
	# Left
	curve.add_point(points[2], Vector2(0, handle_length * ellipse_ratio).rotated(deg_to_rad(tilt_angle)), 
					Vector2(0, -handle_length * ellipse_ratio).rotated(deg_to_rad(tilt_angle)))
	# Top
	curve.add_point(points[3], Vector2(-handle_length, 0).rotated(deg_to_rad(tilt_angle)), 
					Vector2(handle_length, 0).rotated(deg_to_rad(tilt_angle)))
	# Close the loop
	curve.add_point(points[0], Vector2(0, -handle_length * ellipse_ratio).rotated(deg_to_rad(tilt_angle)), 
					Vector2(0, 0))
	
	path_2d.curve = curve
	
	# Update line visuals for the hoop appearance
	update_hoop_lines()

func update_hoop_lines():
	if not front_line or not back_line:
		return
	
	# Create points for front and back halves
	var half_width = radius * 0.5
	var half_height = radius * ellipse_ratio * 0.2
	
	# Front half (bottom arc)
	var front_points = []
	for i in range(5):
		var t = i / 4.0
		var x = lerp(-half_width, half_width, t)
		var y = half_height * (1.0 - 4.0 * pow(t - 0.5, 2))
		front_points.append(rotate_point(Vector2(x, y), deg_to_rad(tilt_angle)))
	
	# Back half (top arc)
	var back_points = []
	for i in range(5):
		var t = i / 4.0
		var x = lerp(-half_width, half_width, t)
		var y = -half_height * (1.0 - 4.0 * pow(t - 0.5, 2))
		back_points.append(rotate_point(Vector2(x, y), deg_to_rad(tilt_angle)))
	
	front_line.points = front_points
	back_line.points = back_points
	
	# Update colors
	front_line.default_color = color_front
	back_line.default_color = color_back
	front_line.width = line_width
	back_line.width = line_width

func rotate_point(point: Vector2, angle: float) -> Vector2:
	return point.rotated(angle)

func _process(delta: float):
	if not skeleton_ref or not target_bone:
		return
	
	# Update phase
	current_phase += speed * TAU * delta
	current_phase = fmod(current_phase, TAU)
	
	# Update hoop system phase
	if hoop_system and hoop_system.hoop:
		hoop_system.hoop.phase = current_phase
	
	# Update visual position
	if path_follow:
		path_follow.progress_ratio = current_phase / TAU
	
	# Position hoop at target bone
	if target_bone:
		global_position = target_bone.global_position

# Public API methods
func set_radius(new_radius: float):
	radius = new_radius
	if hoop_system and hoop_system.hoop:
		hoop_system.hoop.radius = radius
	update_hoop_visual()

func set_speed(new_speed: float):
	speed = new_speed
	if hoop_system and hoop_system.hoop:
		hoop_system.hoop.speed = speed * TAU

func set_target_bone(bone_path: String):
	target_bone_path = bone_path
	if skeleton_ref and bone_path:
		target_bone = skeleton_ref.get_node(bone_path) as Bone2D
		if target_bone:
			if hoop_system:
				hoop_system.target_bone_path = bone_path
			cache_bone_data()

func set_tilt_angle(angle: float):
	tilt_angle = clamp(angle, -45.0, 45.0)
	update_hoop_visual()

func set_colors(front: Color, back: Color):
	color_front = front
	color_back = back
	if front_line:
		front_line.default_color = color_front
	if back_line:
		back_line.default_color = color_back

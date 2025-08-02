extends Node2D
class_name HulaHoop

# HulaHoopResource is a global class, no need to preload

# Core properties
@export_group("Hoop Size")
@export var hoop_width: float = 20.0  # Width of the hoop itself
@export var hoop_height: float = 12.0  # Height of the hoop itself (for ellipse)

@export_group("Path Dimensions")
@export var path_width: float = 80.0  # Width of the elliptical path
@export var path_height: float = 48.0  # Height of the elliptical path

@export_group("Motion")
@export var speed_multiplier: float = 1.0  # Multiplier for base rotation speed
@export var target_bone_path: String = "CenterBone/LowerSpine"
@export var tilt_angle: float = 0.0  # Degrees, -45 to 45

# Visual properties
@export var color_front: Color = Color(1, 0.109804, 0.0588235, 1)  # Bright red
@export var color_back: Color = Color(0.556863, 0.121569, 0.141176, 1)  # Dark red
@export var line_width: float = 25.0

# References
var skeleton_ref: Skeleton2D
var target_bone: Bone2D
var hoop_system: HulaHoopSystem
var visual_node: Node2D
var front_line: Line2D
var back_line: Line2D
var left_distortion: ColorRect
var right_distortion: ColorRect

# Internal state
var current_phase: float = 0.0
var bone_data: Dictionary = {}
var all_bones: Array = []

# Stretch animation state
var is_stretching: bool = false
var stretch_factor: float = 1.0  # 1.0 = normal, >1.0 = stretched
var stretch_direction: Vector2 = Vector2.RIGHT
var stretch_time: float = 0.0
var max_stretch: float = 3.0  # Maximum stretch multiplier
var stretch_animation_speed: float = 8.0  # How fast the stretch animates

func _ready():
	# Don't set up components here since we need skeleton reference
	# Everything will be set up in initialize()
	pass

func setup_visual_components():
	# Prevent duplicate visual nodes
	if visual_node:
		push_warning("Visual components already set up")
		return
		
	# Create visual container
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	add_child(visual_node)
	
	# Create distortion effects for left and right edges
	setup_distortion_effects()
	
	# Create back half line
	back_line = Line2D.new()
	back_line.name = "BackHalf"
	back_line.z_index = -2
	back_line.width = line_width
	back_line.default_color = color_back
	visual_node.add_child(back_line)
	
	# Create front half line
	front_line = Line2D.new()
	front_line.name = "FrontHalf"
	front_line.z_index = 4
	front_line.width = line_width
	front_line.default_color = color_front
	visual_node.add_child(front_line)
	
	# Update the visual
	update_hoop_visual()

func setup_distortion_effects():
	# Load the air distortion material
	var distortion_material = load("res://assets/materials/air_distortion_material.tres")
	
	# Create left edge distortion
	left_distortion = ColorRect.new()
	left_distortion.name = "LeftDistortion"
	left_distortion.material = distortion_material
	left_distortion.size = Vector2(200, 200)
	left_distortion.position = Vector2(-100, -100)
	left_distortion.z_index = -3
	left_distortion.color = Color(1, 1, 1, 0)  # Transparent
	visual_node.add_child(left_distortion)
	
	# Create right edge distortion
	right_distortion = ColorRect.new()
	right_distortion.name = "RightDistortion"
	right_distortion.material = distortion_material.duplicate()
	right_distortion.size = Vector2(200, 200)
	right_distortion.position = Vector2(-100, -100)
	right_distortion.z_index = -3
	right_distortion.color = Color(1, 1, 1, 0)  # Transparent
	visual_node.add_child(right_distortion)

func setup_hoop_system():
	# Prevent duplicate hoop system
	if hoop_system:
		push_warning("Hoop system already set up")
		return
		
	# Create HulaHoopSystem node
	hoop_system = HulaHoopSystem.new()
	hoop_system.name = "BoneManipulator"
	add_child(hoop_system)
	
	# Create HulaHoop resource
	var hoop_resource = HulaHoopResource.new()
	hoop_resource.radius = path_width / 2.0  # Convert diameter to radius
	hoop_resource.ellipse_ratio = path_height / path_width  # Calculate ratio
	
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
	# Update line visuals for the hoop appearance
	update_hoop_lines()

func update_hoop_lines():
	if not front_line or not back_line:
		return
	
	# Clear existing points
	front_line.clear_points()
	back_line.clear_points()
	
	# Create points for front and back halves
	var half_width = hoop_width / 2.0
	var half_height = hoop_height / 2.0
	
	# Apply stretch deformation
	var stretch_along = abs(stretch_direction.normalized().x)  # How much stretch is horizontal
	var stretch_perp = abs(stretch_direction.normalized().y)   # How much stretch is vertical
	
	# Stretch horizontally based on direction, compress perpendicular
	var width_factor = 1.0 + (stretch_factor - 1.0) * stretch_along
	var height_factor = 1.0 / (1.0 + (stretch_factor - 1.0) * 0.5)  # Compress height when stretching
	
	# If stretching vertically, swap the factors
	if stretch_perp > stretch_along:
		var temp = width_factor
		width_factor = height_factor
		height_factor = 1.0 + (stretch_factor - 1.0) * stretch_perp
	
	var stretched_width = half_width * width_factor
	var stretched_height = half_height * height_factor
	
	# Front half (bottom arc)
	var front_points = []
	for i in range(9):  # More points for smoother deformation
		var t = i / 8.0
		var x = lerp(-stretched_width, stretched_width, t)
		var y = stretched_height * (1.0 - 4.0 * pow(t - 0.5, 2))
		
		# Apply directional stretch offset
		if is_stretching:
			var offset = stretch_direction.normalized() * (stretch_factor - 1.0) * 10.0
			x += offset.x * (1.0 - abs(t - 0.5) * 2.0)  # Less offset at edges
			y += offset.y * (1.0 - abs(t - 0.5) * 2.0)
		
		front_points.append(Vector2(x, y))
	
	# Back half (top arc)
	var back_points = []
	for i in range(9):  # More points for smoother deformation
		var t = i / 8.0
		var x = lerp(-stretched_width, stretched_width, t)
		var y = -stretched_height * (1.0 - 4.0 * pow(t - 0.5, 2))
		
		# Apply directional stretch offset
		if is_stretching:
			var offset = stretch_direction.normalized() * (stretch_factor - 1.0) * 10.0
			x += offset.x * (1.0 - abs(t - 0.5) * 2.0)  # Less offset at edges
			y += offset.y * (1.0 - abs(t - 0.5) * 2.0)
		
		back_points.append(Vector2(x, y))
	
	front_line.points = front_points
	back_line.points = back_points
	
	# Update colors
	front_line.default_color = color_front
	back_line.default_color = color_back
	front_line.width = line_width
	back_line.width = line_width
	
	# Update distortion effect positions and strength
	if left_distortion and right_distortion:
		# Position distortions at the leftmost and rightmost points
		var left_pos = Vector2(-stretched_width, 0)
		var right_pos = Vector2(stretched_width, 0)
		
		left_distortion.position = left_pos - left_distortion.size / 2.0
		right_distortion.position = right_pos - right_distortion.size / 2.0
		
		# Increase distortion strength when stretching
		if is_stretching and left_distortion.material and right_distortion.material:
			var distortion_strength = 0.01 + (stretch_factor - 1.0) * 0.02
			left_distortion.material.set_shader_parameter("distortion_strength", distortion_strength)
			right_distortion.material.set_shader_parameter("distortion_strength", distortion_strength)

func rotate_point(point: Vector2, angle: float) -> Vector2:
	return point.rotated(angle)

func _process(delta: float):
	# Phase is controlled by character script
	if not skeleton_ref or not target_bone:
		return
	
	# Update hoop system phase
	if hoop_system and hoop_system.hoop:
		hoop_system.hoop.phase = current_phase
	
	# Update stretch animation
	if is_stretching:
		update_stretch_animation(delta)
	
	# Position hoop at target bone with circular motion
	if target_bone:
		var x_offset = cos(current_phase) * (path_width / 2.0)
		var y_offset = sin(current_phase) * (path_height / 2.0)
		# No need to rotate offset since visual_node handles rotation
		global_position = target_bone.global_position + Vector2(x_offset, y_offset).rotated(rotation)
		

# Public API methods
func set_path_dimensions(width: float, height: float):
	path_width = width
	path_height = height
	if hoop_system and hoop_system.hoop:
		hoop_system.hoop.radius = path_width / 2.0
		hoop_system.hoop.ellipse_ratio = path_height / path_width
	update_hoop_visual()

func set_hoop_dimensions(width: float, height: float):
	hoop_width = width
	hoop_height = height
	update_hoop_visual()

func set_speed_multiplier(multiplier: float):
	speed_multiplier = multiplier

func get_speed_multiplier() -> float:
	return speed_multiplier

func set_target_bone(bone_path: String):
	target_bone_path = bone_path
	if skeleton_ref and bone_path:
		# Reset bones to rest before changing target
		if hoop_system and hoop_system.has_method("reset_bones_to_rest"):
			hoop_system.reset_bones_to_rest()
		
		target_bone = skeleton_ref.get_node(bone_path) as Bone2D
		if target_bone:
			if hoop_system:
				hoop_system.target_bone_path = bone_path
				# Re-initialize the hoop system to find the new target bone
				hoop_system.initialize(skeleton_ref)
			cache_bone_data()

func set_tilt_angle(angle: float):
	tilt_angle = clamp(angle, -45.0, 45.0)
	if visual_node:
		visual_node.rotation = deg_to_rad(tilt_angle)
	update_hoop_visual()

func set_colors(front: Color, back: Color):
	color_front = front
	color_back = back
	if front_line:
		front_line.default_color = color_front
	if back_line:
		back_line.default_color = color_back

# Stretch animation methods
func start_stretch(direction: Vector2, duration: float = 0.2):
	is_stretching = true
	stretch_direction = direction.normalized()
	stretch_time = 0.0
	stretch_factor = 1.0
	
	# Don't override the rotation set by hoop_directing
	# The visual node rotation should be controlled by tilt_angle

func update_stretch_animation(delta: float):
	if not is_stretching:
		return
	
	stretch_time += delta
	
	# Match the SNAP_TIME phases: 0.2s pause, 0.2s movement
	# Total duration is 0.4s (SNAP_TIME)
	var half_time = 0.2  # Half of SNAP_TIME
	
	if stretch_time < half_time:
		# First phase: stretch out during pause (0 to 0.2s)
		var progress = stretch_time / half_time
		stretch_factor = 1.0 + (max_stretch - 1.0) * ease(progress, -2.0)
	elif stretch_time < half_time * 2:
		# Second phase: snap back during movement (0.2s to 0.4s)
		var progress = (stretch_time - half_time) / half_time
		# Quick snap back with overshoot
		if progress < 0.5:
			# Snap back quickly
			stretch_factor = max_stretch - (max_stretch - 0.7) * ease(progress * 2, 2.0)
		else:
			# Settle to normal with bounce
			var bounce_progress = (progress - 0.5) * 2
			stretch_factor = 0.7 + 0.3 * ease(bounce_progress, -1.5)
	else:
		# Animation complete
		end_stretch()
	
	# Update visual
	update_hoop_visual()

func end_stretch():
	is_stretching = false
	stretch_factor = 1.0
	stretch_time = 0.0
	
	# Reset distortion strength
	if left_distortion and left_distortion.material:
		left_distortion.material.set_shader_parameter("distortion_strength", 0.01)
	if right_distortion and right_distortion.material:
		right_distortion.material.set_shader_parameter("distortion_strength", 0.01)
	
	update_hoop_visual()

func set_stretch_direction(direction: Vector2):
	stretch_direction = direction.normalized()
	if is_stretching and visual_node:
		visual_node.rotation = stretch_direction.angle()

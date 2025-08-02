extends Node2D
class_name HulaHoopSystem

const HulaHoopResource = preload("res://scripts/systems/hula_hoop_resource.gd")

@export var hoop: HulaHoopResource
@export var target_bone_path: String = "CenterBone"
@export var enabled: bool = true
@export var decay_rate: float = 0.8  # How much influence decays per bone distance
@export var max_distance: int = 0  # Maximum bone distance to affect

var skeleton: Skeleton2D
var target_bone: Bone2D
var bone_data: Dictionary = {}  # Bone2D -> {rest_position, distance, affected}
var all_bones: Array = []

func _ready():
	# Skeleton should be set via initialize() method
	pass

func initialize(skeleton_ref: Skeleton2D):
	skeleton = skeleton_ref
	if not skeleton:
		push_error("HulaHoopSystem: No skeleton provided")
		return
	
	# Find the target bone
	if target_bone_path:
		target_bone = skeleton.get_node(target_bone_path) as Bone2D
		if not target_bone:
			push_error("HulaHoopSystem: Could not find bone at path: " + target_bone_path)
			return
		
		# Cache all bones and calculate distances
		cache_bone_data()

func cache_bone_data():
	# Clear existing data
	bone_data.clear()
	all_bones.clear()
	
	# Get all bones in the skeleton
	all_bones = get_all_bones(skeleton)
	
	# Calculate distance from target bone for each bone
	for bone in all_bones:
		var distance = calculate_bone_distance(bone, target_bone)
		bone_data[bone] = {
			"rest_position": bone.position,
			"distance": distance,
			"affected": distance <= max_distance
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
			# Count bone steps from target to bone
			return count_bone_steps(target, bone)
		ancestors_of_bone.append(current)
		current = current.get_parent()
	
	# Find common ancestor and calculate distance
	var ancestors_of_target = []
	current = target.get_parent()
	while current != null:
		if current in ancestors_of_bone:
			# Found common ancestor
			var dist_to_target = count_bone_steps(current, target)
			var dist_to_bone = count_bone_steps(current, bone)
			return dist_to_target + dist_to_bone
		ancestors_of_target.append(current)
		current = current.get_parent()
	
	return 999  # No relationship found

func count_bone_steps(ancestor: Node, descendant: Node) -> int:
	var steps = 0
	var current = descendant
	while current != ancestor and current != null:
		if current is Bone2D:
			steps += 1
		current = current.get_parent()
	return steps

func _process(delta):
	if not enabled or not target_bone or not hoop:
		print("HulaHoopSystem disabled - enabled:", enabled, " target_bone:", target_bone != null, " hoop:", hoop != null)
		return
	
	# Phase is now controlled by the character script
	# hoop.phase = wrapf(hoop.phase + hoop.speed * delta, 0, TAU)
	
	# Calculate base deformation - NEGATED X for counter-movement
	var x_offset = cos(hoop.phase) * hoop.radius
	var y_offset = sin(hoop.phase) * hoop.radius * hoop.ellipse_ratio
	var base_deformation = Vector2(-x_offset, y_offset)
	
	# Debug prints
	print("HulaHoopSystem - phase:", hoop.phase, " deformation:", base_deformation, " max_dist:", max_distance)
	
	# Process bones from root to leaves to handle inheritance properly
	# First, reset all bones to rest position
	for bone in all_bones:
		var data = bone_data[bone]
		bone.position = data.rest_position
	
	# Count affected bones for debugging
	var affected_count = 0
	for bone in all_bones:
		if bone_data[bone].affected:
			affected_count += 1
	print("Affected bones:", affected_count, " out of ", all_bones.size())
	
	# Apply deformation to affected bones only
	for bone in all_bones:
		var data = bone_data[bone]
		if data.affected:
			var distance = data.distance
			# decay_rate represents how much is lost per step
			# so remaining influence = (1 - decay_rate)^distance
			var influence = pow(1.0 - decay_rate, distance)
			
			# Apply deformation as offset from rest position
			bone.position = data.rest_position + base_deformation * influence
			print("Moving bone:", bone.name, " dist:", distance, " influence:", influence)
	
	# For unaffected bones that are children of affected bones,
	# we need to compensate for their parent's movement
	for bone in all_bones:
		var data = bone_data[bone]
		if not data.affected:
			var parent = bone.get_parent()
			if parent is Bone2D and bone_data.has(parent):
				var parent_data = bone_data[parent]
				if parent_data.affected:
					# This unaffected bone has an affected parent
					# Calculate how much the parent moved
					var parent_distance = parent_data.distance
					var parent_influence = pow(1.0 - decay_rate, parent_distance)
					var parent_movement = base_deformation * parent_influence
					
					# Apply inverse movement to keep this bone still relative to the skeleton
					bone.position = data.rest_position - parent_movement

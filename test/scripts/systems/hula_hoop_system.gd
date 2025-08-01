extends Node2D
class_name HulaHoopSystem

@export var hoop: HulaHoop
@export var target_bone_path: String = "CenterBone/LowerSpine"
@export var enabled: bool = true

var skeleton: Skeleton2D
var target_bone: Bone2D
var rest_position: Vector2

func _ready():
	# Find the skeleton in the parent
	skeleton = get_node("../Skeleton2D") as Skeleton2D
	if not skeleton:
		push_error("HulaHoopSystem: Could not find Skeleton2D in parent")
		return
	
	# Find the target bone
	if target_bone_path:
		target_bone = skeleton.get_node(target_bone_path) as Bone2D
		if not target_bone:
			push_error("HulaHoopSystem: Could not find bone at path: " + target_bone_path)
			return
		
		# Store the rest position
		rest_position = target_bone.position
	
	# Create default hoop if none provided
	if not hoop:
		hoop = HulaHoop.new()
		hoop.position = 0.5
		hoop.radius = 30.0
		hoop.speed = 3.0
		hoop.ellipse_ratio = 0.6

func _process(delta):
	if not enabled or not target_bone or not hoop:
		return
	
	# Update hoop phase
	hoop.phase = wrapf(hoop.phase + hoop.speed * delta, 0, TAU)
	
	# Calculate deformation
	var x_offset = cos(hoop.phase) * hoop.radius * hoop.intensity
	var y_offset = sin(hoop.phase) * hoop.radius * hoop.ellipse_ratio * hoop.intensity
	
	# Apply deformation to bone position
	target_bone.position = rest_position + Vector2(x_offset, y_offset)
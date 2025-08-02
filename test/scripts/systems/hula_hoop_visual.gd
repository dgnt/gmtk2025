extends Node2D
class_name HulaHoopVisual

@export var hoop_system_path: NodePath = "../HulaHoopSystem"
@export var skeleton_path: NodePath = "../Skeleton2D"
@export var hoop_height_offset: float = -20.0
@export var hoop_scale_multiplier: float = 2.0

var hoop_system: HulaHoopSystem
var skeleton: Skeleton2D
var hoop_sprite: Sprite2D
var hoop_outline: Line2D
var target_bone: Bone2D

func _ready():
	hoop_system = get_node(hoop_system_path) as HulaHoopSystem
	skeleton = get_node(skeleton_path) as Skeleton2D
	hoop_sprite = $HoopSprite
	hoop_outline = $HoopOutline
	
	if not hoop_system or not skeleton:
		push_error("HulaHoopVisual: Could not find HulaHoopSystem or Skeleton2D")
		return
	
	# Wait for hoop system to initialize
	await get_tree().process_frame
	target_bone = hoop_system.target_bone
	
	# Initialize hoop outline as a circle
	create_hoop_outline()

func create_hoop_outline():
	if not hoop_system or not hoop_system.hoop:
		return
		
	var points = []
	var segments = 32
	var radius = hoop_system.hoop.radius * hoop_scale_multiplier
	
	for i in range(segments + 1):
		var angle = (i / float(segments)) * TAU
		var x = cos(angle) * radius
		var y = sin(angle) * radius * hoop_system.hoop.ellipse_ratio
		points.append(Vector2(x, y))
	
	hoop_outline.points = points

func _process(_delta):
	if not hoop_system or not target_bone or not hoop_system.hoop:
		return
	
	# Get the global position of the target bone
	var bone_global_pos = target_bone.global_position
	
	# Calculate hoop position based on the hoop's current phase
	var hoop = hoop_system.hoop
	var x_offset = cos(hoop.phase) * hoop.radius
	var y_offset = sin(hoop.phase) * hoop.radius * hoop.ellipse_ratio
	
	# Position the hoop visual
	global_position = bone_global_pos + Vector2(x_offset, y_offset + hoop_height_offset)
	
	# Rotate the hoop based on phase
	rotation = hoop.phase * 0.2  # Slight rotation for visual interest
	
	# Update particle position if exists
	var particles = get_node_or_null("../ParticleEffects/Sparkles")
	if particles:
		particles.global_position = global_position
		particles.emitting = true
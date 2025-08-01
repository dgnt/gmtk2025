extends Resource
class_name SwirlAnimation

static func create_swirl_animation(skeleton: Skeleton2D, bone_path: String, width: float, duration: float = 2.0, num_points: int = 16) -> Animation:
	var animation = Animation.new()
	animation.length = duration
	animation.loop_mode = Animation.LOOP_LINEAR
	
	# Calculate ellipse dimensions
	var height = width / 5.0
	
	# Get the bone's rest position
	var bone_node_path = "../Skeleton2D/" + bone_path
	var bone = skeleton.get_node(bone_path) as Bone2D
	if not bone:
		push_error("Bone not found: " + bone_path)
		return animation
	
	var rest_position = bone.position
	
	# Create a single position track (Vector2)
	var pos_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(pos_track, NodePath(bone_node_path + ":position"))
	animation.track_set_interpolation_type(pos_track, Animation.INTERPOLATION_CUBIC)
	
	# Generate keyframes for elliptical motion
	for i in range(num_points + 1):  # +1 to close the loop smoothly
		var t = float(i) / float(num_points) * TAU  # TAU = 2 * PI
		var time = float(i) / float(num_points) * duration
		
		# Parametric ellipse equations
		var x_offset = (width / 2.0) * cos(t)
		var y_offset = (height / 2.0) * sin(t)
		
		# Create position vector with offsets
		var pos = Vector2(
			rest_position.x + x_offset,
			rest_position.y + y_offset
		)
		
		# Insert keyframe
		animation.track_insert_key(pos_track, time, pos)
	
	return animation

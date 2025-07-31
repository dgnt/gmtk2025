extends Node2D

@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var time: float = 0.0
var is_walking: bool = false
var move_speed: float = 200.0
var direction: Vector2 = Vector2.ZERO

func _ready():
	setup_skeleton()
	create_idle_animation()
	create_walk_animation()
	if animation_player.has_animation("idle"):
		animation_player.play("idle")

func setup_skeleton():
	# Skeleton2D bones are enabled by default in Godot 4
	pass

func create_idle_animation():
	var animation = Animation.new()
	animation.length = 2.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	var torso_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(torso_track, NodePath("Skeleton2D/Hip/Torso:rotation"))
	animation.track_insert_key(torso_track, 0.0, 0.0)
	animation.track_insert_key(torso_track, 0.5, 0.03)
	animation.track_insert_key(torso_track, 1.0, 0.0)
	animation.track_insert_key(torso_track, 1.5, -0.03)
	animation.track_insert_key(torso_track, 2.0, 0.0)
	
	var head_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(head_track, NodePath("Skeleton2D/Hip/Torso/Head:rotation"))
	animation.track_insert_key(head_track, 0.0, 0.0)
	animation.track_insert_key(head_track, 0.25, -0.02)
	animation.track_insert_key(head_track, 0.75, 0.02)
	animation.track_insert_key(head_track, 1.25, -0.02)
	animation.track_insert_key(head_track, 1.75, 0.02)
	animation.track_insert_key(head_track, 2.0, 0.0)
	
	var left_arm_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(left_arm_track, NodePath("Skeleton2D/Hip/Torso/LeftArmSprite:rotation"))
	animation.track_insert_key(left_arm_track, 0.0, 0.523)
	animation.track_insert_key(left_arm_track, 1.0, 0.423)
	animation.track_insert_key(left_arm_track, 2.0, 0.523)
	
	var right_arm_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(right_arm_track, NodePath("Skeleton2D/Hip/Torso/RightArmSprite:rotation"))
	animation.track_insert_key(right_arm_track, 0.0, -0.523)
	animation.track_insert_key(right_arm_track, 1.0, -0.423)
	animation.track_insert_key(right_arm_track, 2.0, -0.523)
	
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("idle", animation)
	animation_player.add_animation_library("", anim_lib)

func create_walk_animation():
	var animation = Animation.new()
	animation.length = 0.8
	animation.loop_mode = Animation.LOOP_LINEAR
	
	# Hip vertical movement (bob)
	var hip_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(hip_track, NodePath("Skeleton2D/Hip:position:y"))
	animation.track_insert_key(hip_track, 0.0, 0.0)
	animation.track_insert_key(hip_track, 0.2, -5.0)
	animation.track_insert_key(hip_track, 0.4, 0.0)
	animation.track_insert_key(hip_track, 0.6, -5.0)
	animation.track_insert_key(hip_track, 0.8, 0.0)
	
	# Torso slight rotation (sway)
	var torso_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(torso_track, NodePath("Skeleton2D/Hip/Torso:rotation"))
	animation.track_insert_key(torso_track, 0.0, -0.05)
	animation.track_insert_key(torso_track, 0.2, 0.0)
	animation.track_insert_key(torso_track, 0.4, 0.05)
	animation.track_insert_key(torso_track, 0.6, 0.0)
	animation.track_insert_key(torso_track, 0.8, -0.05)
	
	# Left leg animation
	var left_leg_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(left_leg_track, NodePath("Skeleton2D/Hip/LeftLegSprite:rotation"))
	animation.track_insert_key(left_leg_track, 0.0, 0.4)
	animation.track_insert_key(left_leg_track, 0.2, 0.2)
	animation.track_insert_key(left_leg_track, 0.4, -0.4)
	animation.track_insert_key(left_leg_track, 0.6, -0.2)
	animation.track_insert_key(left_leg_track, 0.8, 0.4)
	
	# Right leg animation (opposite of left)
	var right_leg_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(right_leg_track, NodePath("Skeleton2D/Hip/RightLegSprite:rotation"))
	animation.track_insert_key(right_leg_track, 0.0, -0.4)
	animation.track_insert_key(right_leg_track, 0.2, -0.2)
	animation.track_insert_key(right_leg_track, 0.4, 0.4)
	animation.track_insert_key(right_leg_track, 0.6, 0.2)
	animation.track_insert_key(right_leg_track, 0.8, -0.4)
	
	# Left arm animation (opposite of left leg)
	var left_arm_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(left_arm_track, NodePath("Skeleton2D/Hip/Torso/LeftArmSprite:rotation"))
	animation.track_insert_key(left_arm_track, 0.0, 0.323)
	animation.track_insert_key(left_arm_track, 0.2, 0.423)
	animation.track_insert_key(left_arm_track, 0.4, 0.723)
	animation.track_insert_key(left_arm_track, 0.6, 0.623)
	animation.track_insert_key(left_arm_track, 0.8, 0.323)
	
	# Right arm animation (opposite of right leg)
	var right_arm_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(right_arm_track, NodePath("Skeleton2D/Hip/Torso/RightArmSprite:rotation"))
	animation.track_insert_key(right_arm_track, 0.0, -0.723)
	animation.track_insert_key(right_arm_track, 0.2, -0.623)
	animation.track_insert_key(right_arm_track, 0.4, -0.323)
	animation.track_insert_key(right_arm_track, 0.6, -0.423)
	animation.track_insert_key(right_arm_track, 0.8, -0.723)
	
	# Head slight bounce
	var head_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(head_track, NodePath("Skeleton2D/Hip/Torso/Head:position:y"))
	animation.track_insert_key(head_track, 0.0, -80)
	animation.track_insert_key(head_track, 0.2, -82)
	animation.track_insert_key(head_track, 0.4, -80)
	animation.track_insert_key(head_track, 0.6, -82)
	animation.track_insert_key(head_track, 0.8, -80)
	
	var anim_lib = animation_player.get_animation_library("")
	if anim_lib:
		anim_lib.add_animation("walk", animation)
	else:
		anim_lib = AnimationLibrary.new()
		anim_lib.add_animation("walk", animation)
		animation_player.add_animation_library("", anim_lib)

func _physics_process(delta):
	time += delta
	
	# Handle input
	direction = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		direction.x = -1
	elif Input.is_action_pressed("ui_right"):
		direction.x = 1
	if Input.is_action_pressed("ui_up"):
		direction.y = -1
	elif Input.is_action_pressed("ui_down"):
		direction.y = 1
	
	direction = direction.normalized()
	
	# Update walking state and animation
	if direction != Vector2.ZERO:
		if not is_walking:
			is_walking = true
			animation_player.play("walk")
		position += direction * move_speed * delta
		
		# Face the direction of movement
		if direction.x < 0:
			scale.x = abs(scale.x) * -1
		elif direction.x > 0:
			scale.x = abs(scale.x)
	else:
		if is_walking:
			is_walking = false
			animation_player.play("idle")
	
	# Only apply breathing when idle
	if not is_walking:
		var breathe_offset = sin(time * 2.0) * 1.5
		if skeleton.has_node("Hip/Torso"):
			var torso = skeleton.get_node("Hip/Torso")
			torso.position.y = -40 + breathe_offset

extends Node2D

@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var time: float = 0.0

func _ready():
	setup_skeleton()
	create_idle_animation()
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

func _physics_process(delta):
	time += delta
	
	var breathe_offset = sin(time * 2.0) * 1.5
	if skeleton.has_node("Hip/Torso"):
		var torso = skeleton.get_node("Hip/Torso")
		torso.position.y = -40 + breathe_offset

@tool
extends EditorScript

# Stage 4: Animation Setup
# This script creates basic animations for the dachshund

func _run():
	print("=== DACHSHUND BUILDER - STAGE 4: ANIMATION SETUP ===")
	print("Creating animations for dachshund...")
	
	# Load the stage 3 scene
	var scene_path = "res://scenes/characters/GeneratedDachshund_Stage3.tscn"
	if not FileAccess.file_exists(scene_path):
		print("ERROR: Stage 3 scene not found. Please run dachshund_builder_stage3.gd first.")
		return
	
	var packed_scene = load(scene_path) as PackedScene
	var root = packed_scene.instantiate()
	
	var skeleton = root.get_node("Skeleton2D")
	if not skeleton:
		print("ERROR: Could not find Skeleton2D")
		root.queue_free()
		return
	
	# Create AnimationPlayer
	var animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	root.add_child(animation_player)
	animation_player.owner = root
	
	# Create animations
	create_idle_animation(animation_player, skeleton)
	create_walk_animation(animation_player, skeleton)
	create_run_animation(animation_player, skeleton)
	create_jump_animation(animation_player, skeleton)
	create_tail_wag_animation(animation_player, skeleton)
	
	# Create AnimationTree for blending
	var animation_tree = AnimationTree.new()
	animation_tree.name = "AnimationTree"
	animation_tree.anim_player = NodePath("../AnimationPlayer")
	root.add_child(animation_tree)
	animation_tree.owner = root
	
	# Set default animation
	animation_player.current_animation = "idle"
	
	# Add script to root for controlling animations
	var control_script = """extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = -400.0

@onready var animation_player = $AnimationPlayer
@onready var skeleton = $Skeleton2D

func _ready():
	if animation_player:
		animation_player.play("idle")

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		if animation_player:
			animation_player.play("jump")
	
	# Handle movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
		# Flip character
		if direction < 0:
			scale.x = -abs(scale.x)
		else:
			scale.x = abs(scale.x)
		# Play walk or run animation
		if abs(velocity.x) > speed * 0.8:
			if animation_player and animation_player.current_animation != "run":
				animation_player.play("run")
		else:
			if animation_player and animation_player.current_animation != "walk":
				animation_player.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		if is_on_floor() and animation_player and animation_player.current_animation != "idle":
			animation_player.play("idle")
	
	move_and_slide()
"""
	
	# Save the control script
	var script_path = "res://scripts/characters/generated_dachshund.gd"
	var script_file = FileAccess.open(script_path, FileAccess.WRITE)
	script_file.store_string(control_script)
	script_file.close()
	
	# Attach script to root
	root.set_script(load(script_path))
	
	# Save the final scene
	var new_packed_scene = PackedScene.new()
	new_packed_scene.pack(root)
	var save_path = "res://scenes/characters/GeneratedDachshund.tscn"
	var error = ResourceSaver.save(new_packed_scene, save_path)
	
	if error == OK:
		print("\n✓ Stage 4 Complete!")
		print("Created animations:")
		print("  • idle - Breathing and subtle movement")
		print("  • walk - Walking cycle")
		print("  • run - Running cycle")
		print("  • jump - Jump animation")
		print("  • tail_wag - Tail wagging")
		print("\nFinal scene saved to: " + save_path)
		print("Control script saved to: " + script_path)
		print("\n=== FINAL STEPS ===")
		print("1. Open the final scene: " + save_path)
		print("2. Test animations using AnimationPlayer")
		print("3. Add the character to your game scene")
		print("4. Controls:")
		print("   - Arrow keys: Move left/right")
		print("   - Space/Enter: Jump")
		print("\n✓ DACHSHUND BUILDER COMPLETE!")
	else:
		print("ERROR: Failed to save scene")
	
	# Clean up
	root.queue_free()

func create_idle_animation(player: AnimationPlayer, skeleton: Skeleton2D):
	var anim = Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Subtle breathing motion on spine bones
	for bone_name in ["Spine1", "Spine2", "Spine3", "Chest"]:
		var bone = find_bone_by_name(skeleton, bone_name)
		if not bone:
			continue
		var track_idx = anim.add_track(Animation.TYPE_ROTATION_2D)
		anim.track_set_path(track_idx, skeleton.get_path_to(bone))
		anim.rotation_track_insert_key(track_idx, 0.0, 0.0)
		anim.rotation_track_insert_key(track_idx, 1.0, deg_to_rad(2.0))
		anim.rotation_track_insert_key(track_idx, 2.0, 0.0)
	
	# Head bob
	var head = find_bone_by_name(skeleton, "Head")
	if head:
		var track_idx = anim.add_track(Animation.TYPE_ROTATION_2D)
		anim.track_set_path(track_idx, skeleton.get_path_to(head))
		anim.rotation_track_insert_key(track_idx, 0.0, 0.0)
		anim.rotation_track_insert_key(track_idx, 0.5, deg_to_rad(-3.0))
		anim.rotation_track_insert_key(track_idx, 1.5, deg_to_rad(3.0))
		anim.rotation_track_insert_key(track_idx, 2.0, 0.0)
	
	player.add_animation_library("", AnimationLibrary.new())
	player.get_animation_library("").add_animation("idle", anim)

func create_walk_animation(player: AnimationPlayer, skeleton: Skeleton2D):
	var anim = Animation.new()
	anim.length = 0.8
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Leg movement
	var leg_bones = {
		"FrontLegL": {"offset": 0.0, "angle": 25.0},
		"FrontLegR": {"offset": 0.4, "angle": 25.0},
		"BackLegL": {"offset": 0.2, "angle": 20.0},
		"BackLegR": {"offset": 0.6, "angle": 20.0}
	}
	
	for bone_name in leg_bones:
		var bone = find_bone_by_name(skeleton, bone_name)
		if not bone:
			continue
		var config = leg_bones[bone_name]
		var track_idx = anim.add_track(Animation.TYPE_ROTATION_2D)
		anim.track_set_path(track_idx, skeleton.get_path_to(bone))
		
		var t1 = config["offset"]
		var t2 = fmod(t1 + 0.2, anim.length)
		var t3 = fmod(t1 + 0.4, anim.length)
		var t4 = fmod(t1 + 0.6, anim.length)
		
		anim.rotation_track_insert_key(track_idx, t1, deg_to_rad(-config["angle"]))
		anim.rotation_track_insert_key(track_idx, t2, 0.0)
		anim.rotation_track_insert_key(track_idx, t3, deg_to_rad(config["angle"]))
		anim.rotation_track_insert_key(track_idx, t4, 0.0)
	
	# Body sway
	var spine2 = find_bone_by_name(skeleton, "Spine2")
	if spine2:
		var track_idx = anim.add_track(Animation.TYPE_ROTATION_2D)
		anim.track_set_path(track_idx, skeleton.get_path_to(spine2))
		anim.rotation_track_insert_key(track_idx, 0.0, deg_to_rad(-3.0))
		anim.rotation_track_insert_key(track_idx, 0.4, deg_to_rad(3.0))
		anim.rotation_track_insert_key(track_idx, 0.8, deg_to_rad(-3.0))
	
	player.get_animation_library("").add_animation("walk", anim)

func create_run_animation(player: AnimationPlayer, skeleton: Skeleton2D):
	var anim = Animation.new()
	anim.length = 0.4
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Faster, more exaggerated leg movement
	var leg_bones = {
		"FrontLegL": {"offset": 0.0, "angle": 40.0},
		"FrontLegR": {"offset": 0.2, "angle": 40.0},
		"BackLegL": {"offset": 0.1, "angle": 35.0},
		"BackLegR": {"offset": 0.3, "angle": 35.0}
	}
	
	for bone_name in leg_bones:
		var bone = find_bone_by_name(skeleton, bone_name)
		if not bone:
			continue
		var config = leg_bones[bone_name]
		var track_idx = anim.add_track(Animation.TYPE_ROTATION_2D)
		anim.track_set_path(track_idx, skeleton.get_path_to(bone))
		
		var t1 = config["offset"]
		var t2 = fmod(t1 + 0.2, anim.length)
		
		anim.rotation_track_insert_key(track_idx, t1, deg_to_rad(-config["angle"]))
		anim.rotation_track_insert_key(track_idx, t2, deg_to_rad(config["angle"]))
	
	player.get_animation_library("").add_animation("run", anim)

func create_jump_animation(player: AnimationPlayer, skeleton: Skeleton2D):
	var anim = Animation.new()
	anim.length = 0.6
	anim.loop_mode = Animation.LOOP_NONE
	
	# Compress body on takeoff
	var spine_bones = ["Spine1", "Spine2", "Spine3"]
	for i in range(spine_bones.size()):
		var bone = find_bone_by_name(skeleton, spine_bones[i])
		if not bone:
			continue
		var track_idx = anim.add_track(Animation.TYPE_ROTATION_2D)
		anim.track_set_path(track_idx, skeleton.get_path_to(bone))
		anim.rotation_track_insert_key(track_idx, 0.0, 0.0)
		anim.rotation_track_insert_key(track_idx, 0.1, deg_to_rad(10.0))
		anim.rotation_track_insert_key(track_idx, 0.3, deg_to_rad(-5.0))
		anim.rotation_track_insert_key(track_idx, 0.6, 0.0)
	
	# Legs extend
	for leg in ["FrontLegL", "FrontLegR", "BackLegL", "BackLegR"]:
		var bone = find_bone_by_name(skeleton, leg)
		if not bone:
			continue
		var track_idx = anim.add_track(Animation.TYPE_ROTATION_2D)
		anim.track_set_path(track_idx, skeleton.get_path_to(bone))
		anim.rotation_track_insert_key(track_idx, 0.0, 0.0)
		anim.rotation_track_insert_key(track_idx, 0.1, deg_to_rad(30.0))
		anim.rotation_track_insert_key(track_idx, 0.3, deg_to_rad(-20.0))
		anim.rotation_track_insert_key(track_idx, 0.6, 0.0)
	
	player.get_animation_library("").add_animation("jump", anim)

func create_tail_wag_animation(player: AnimationPlayer, skeleton: Skeleton2D):
	var anim = Animation.new()
	anim.length = 0.5
	anim.loop_mode = Animation.LOOP_LINEAR
	
	var tail_bones = ["TailBase", "TailMid", "TailTip"]
	for i in range(tail_bones.size()):
		var bone = find_bone_by_name(skeleton, tail_bones[i])
		if not bone:
			continue
		var track_idx = anim.add_track(Animation.TYPE_ROTATION_2D)
		anim.track_set_path(track_idx, skeleton.get_path_to(bone))
		var amplitude = 30.0 + i * 10.0  # Tip wags more
		anim.rotation_track_insert_key(track_idx, 0.0, deg_to_rad(-amplitude))
		anim.rotation_track_insert_key(track_idx, 0.25, deg_to_rad(amplitude))
		anim.rotation_track_insert_key(track_idx, 0.5, deg_to_rad(-amplitude))
	
	player.get_animation_library("").add_animation("tail_wag", anim)

func find_bone_by_name(skeleton: Skeleton2D, bone_name: String) -> Bone2D:
	for i in range(skeleton.get_bone_count()):
		var bone = skeleton.get_bone(i)
		if bone.name == bone_name:
			return bone
	return null
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
	
	# Create AnimationLibrary (required in Godot 4)
	var animation_library = AnimationLibrary.new()
	
	# Create animations and add to library
	var idle_anim = create_idle_animation(animation_player, skeleton)
	if idle_anim:
		animation_library.add_animation("idle", idle_anim)
	
	var walk_anim = create_walk_animation(animation_player, skeleton)
	if walk_anim:
		animation_library.add_animation("walk", walk_anim)
	
	var run_anim = create_run_animation(animation_player, skeleton)
	if run_anim:
		animation_library.add_animation("run", run_anim)
	
	var jump_anim = create_jump_animation(animation_player, skeleton)
	if jump_anim:
		animation_library.add_animation("jump", jump_anim)
	
	var tail_wag_anim = create_tail_wag_animation(animation_player, skeleton)
	if tail_wag_anim:
		animation_library.add_animation("tail_wag", tail_wag_anim)
	
	# Add the library to the AnimationPlayer with empty name for default library
	animation_player.add_animation_library("", animation_library)
	
	# Set default animation
	animation_player.assigned_animation = "idle"
	
	# Add control script
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
	var script_dir = "res://scripts/characters/"
	if not DirAccess.dir_exists_absolute(script_dir):
		DirAccess.make_dir_recursive_absolute(script_dir)
	
	var script_path = script_dir + "generated_dachshund.gd"
	var script_file = FileAccess.open(script_path, FileAccess.WRITE)
	script_file.store_string(control_script)
	script_file.close()
	
	# Attach script to root
	root.set_script(load(script_path))
	
	# Save the final scene
	var new_packed_scene = PackedScene.new()
	new_packed_scene.pack(root)
	var save_path = "res://scenes/characters/GeneratedDachshund_Final.tscn"
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

func create_idle_animation(player: AnimationPlayer, skeleton: Skeleton2D) -> Animation:
	var anim = Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Add body sway left to right
	var body_sway_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(body_sway_track, NodePath("Skeleton2D:CenterBone:rotation"))
	anim.track_insert_key(body_sway_track, 0.0, 0.0)
	anim.track_insert_key(body_sway_track, 0.5, deg_to_rad(-3.0))  # Sway left
	anim.track_insert_key(body_sway_track, 1.0, 0.0)
	anim.track_insert_key(body_sway_track, 1.5, deg_to_rad(3.0))   # Sway right
	anim.track_insert_key(body_sway_track, 2.0, 0.0)
	
	# Get actual bone names from skeleton
	var bone_names = ["CenterBone/LowerSpine", "CenterBone/LowerChest", "CenterBone/LowerChest/Chest", "CenterBone/LowerChest/Chest/Neck/Head"]
	
	# Subtle breathing motion on spine bones
	for bone_name in bone_names:
		var bone_idx = skeleton.find_bone(bone_name)
		if bone_idx == -1:
			continue
			
		var bone = skeleton.get_bone(bone_idx)
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath("Skeleton2D:" + bone_name + ":rotation"))
		anim.track_insert_key(track_idx, 0.0, 0.0)
		anim.track_insert_key(track_idx, 1.0, deg_to_rad(2.0))
		anim.track_insert_key(track_idx, 2.0, 0.0)
	
	print("Created idle animation with " + str(anim.get_track_count()) + " tracks")
	return anim

func create_walk_animation(player: AnimationPlayer, skeleton: Skeleton2D) -> Animation:
	var anim = Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Animate legs for walking
	var leg_bones = [
		"CenterBone/LowerSpine/RearTailbone/RearHip",
		"CenterBone/LowerSpine/RearTailbone/RearHip/RearAnkle",
		"CenterBone/LowerSpine/RearTailbone/FrontHip",
		"CenterBone/LowerSpine/RearTailbone/FrontHip/FrontAnkle"
	]
	
	for i in range(leg_bones.size()):
		var bone_name = leg_bones[i]
		var bone_idx = skeleton.find_bone(bone_name)
		if bone_idx == -1:
			continue
			
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath("Skeleton2D:" + bone_name + ":rotation"))
		
		# Offset for alternating leg movement
		var offset = 0.5 if i % 2 == 0 else 0.0
		anim.track_insert_key(track_idx, 0.0 + offset, deg_to_rad(-15.0))
		anim.track_insert_key(track_idx, 0.25 + offset, deg_to_rad(15.0))
		anim.track_insert_key(track_idx, 0.5 + offset, deg_to_rad(-15.0))
		if offset > 0:
			anim.track_insert_key(track_idx, 0.0, deg_to_rad(15.0))
			anim.track_insert_key(track_idx, 1.0, deg_to_rad(-15.0))
	
	# Add subtle body movement
	var body_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(body_track, NodePath("Skeleton2D:CenterBone:position"))
	anim.track_insert_key(body_track, 0.0, Vector2(-17, 0))
	anim.track_insert_key(body_track, 0.5, Vector2(-17, -5))
	anim.track_insert_key(body_track, 1.0, Vector2(-17, 0))
	
	print("Created walk animation with " + str(anim.get_track_count()) + " tracks")
	return anim

func create_run_animation(player: AnimationPlayer, skeleton: Skeleton2D) -> Animation:
	var anim = Animation.new()
	anim.length = 0.5
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Similar to walk but faster and more pronounced
	var leg_bones = [
		"CenterBone/LowerSpine/RearTailbone/RearHip",
		"CenterBone/LowerSpine/RearTailbone/RearHip/RearAnkle",
		"CenterBone/LowerSpine/RearTailbone/FrontHip",
		"CenterBone/LowerSpine/RearTailbone/FrontHip/FrontAnkle"
	]
	
	for i in range(leg_bones.size()):
		var bone_name = leg_bones[i]
		var bone_idx = skeleton.find_bone(bone_name)
		if bone_idx == -1:
			continue
			
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath("Skeleton2D:" + bone_name + ":rotation"))
		
		var offset = 0.25 if i % 2 == 0 else 0.0
		anim.track_insert_key(track_idx, 0.0 + offset, deg_to_rad(-25.0))
		anim.track_insert_key(track_idx, 0.125 + offset, deg_to_rad(25.0))
		anim.track_insert_key(track_idx, 0.25 + offset, deg_to_rad(-25.0))
		if offset > 0:
			anim.track_insert_key(track_idx, 0.0, deg_to_rad(25.0))
			anim.track_insert_key(track_idx, 0.5, deg_to_rad(-25.0))
	
	# More pronounced body movement
	var body_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(body_track, NodePath("Skeleton2D:CenterBone:position"))
	anim.track_insert_key(body_track, 0.0, Vector2(-17, 0))
	anim.track_insert_key(body_track, 0.25, Vector2(-17, -10))
	anim.track_insert_key(body_track, 0.5, Vector2(-17, 0))
	
	print("Created run animation with " + str(anim.get_track_count()) + " tracks")
	return anim

func create_jump_animation(player: AnimationPlayer, skeleton: Skeleton2D) -> Animation:
	var anim = Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_NONE
	
	# Compress body for jump preparation
	var body_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(body_track, NodePath("Skeleton2D:CenterBone:scale"))
	anim.track_insert_key(body_track, 0.0, Vector2(1, 1))
	anim.track_insert_key(body_track, 0.2, Vector2(1.1, 0.8))
	anim.track_insert_key(body_track, 0.4, Vector2(0.9, 1.2))
	anim.track_insert_key(body_track, 1.0, Vector2(1, 1))
	
	# Leg extension
	var leg_bones = [
		"CenterBone/LowerSpine/RearTailbone/RearHip",
		"CenterBone/LowerSpine/RearTailbone/FrontHip"
	]
	
	for bone_name in leg_bones:
		var bone_idx = skeleton.find_bone(bone_name)
		if bone_idx == -1:
			continue
			
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath("Skeleton2D:" + bone_name + ":rotation"))
		anim.track_insert_key(track_idx, 0.0, 0.0)
		anim.track_insert_key(track_idx, 0.2, deg_to_rad(20.0))
		anim.track_insert_key(track_idx, 0.4, deg_to_rad(-30.0))
		anim.track_insert_key(track_idx, 1.0, 0.0)
	
	print("Created jump animation with " + str(anim.get_track_count()) + " tracks")
	return anim

func create_tail_wag_animation(player: AnimationPlayer, skeleton: Skeleton2D) -> Animation:
	var anim = Animation.new()
	anim.length = 0.5
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Find tail polygon (it might not have a dedicated bone)
	var tail_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tail_track, NodePath("Polygons/tail:rotation"))
	anim.track_insert_key(tail_track, 0.0, deg_to_rad(-15.0))
	anim.track_insert_key(tail_track, 0.25, deg_to_rad(15.0))
	anim.track_insert_key(tail_track, 0.5, deg_to_rad(-15.0))
	
	print("Created tail wag animation with " + str(anim.get_track_count()) + " tracks")
	return anim

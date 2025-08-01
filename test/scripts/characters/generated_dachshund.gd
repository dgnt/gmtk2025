extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = -400.0

@onready var animation_player = $AnimationPlayer
@onready var skeleton = $Skeleton2D

func _ready():
	if animation_player:
		setup_animations()
	
	# If running scene in isolation, setup test environment
	if get_tree().current_scene == self:
		setup_test_environment()

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
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	move_and_slide()
	
func setup_animations():
	# Find the AnimationPlayer
	var animation_player = get_node("AnimationPlayer")
	
	# Create the idle animation
	var idle_anim = Animation.new()
	idle_anim.length = 2.0
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	
	# CenterBone rotation sway - increased for visibility
	var center_bone_track = idle_anim.add_track(Animation.TYPE_VALUE)
	idle_anim.track_set_path(center_bone_track, NodePath("Skeleton2D:CenterBone:rotation"))
	idle_anim.track_set_interpolation_type(center_bone_track, Animation.INTERPOLATION_CUBIC)
	idle_anim.track_insert_key(center_bone_track, 0.0, 0.0)
	idle_anim.track_insert_key(center_bone_track, 0.5, 0.5)  # Increased from 0.05 to 0.5
	idle_anim.track_insert_key(center_bone_track, 1.0, 0.0)
	idle_anim.track_insert_key(center_bone_track, 1.5, -0.5)  # Increased from -0.05 to -0.5
	idle_anim.track_insert_key(center_bone_track, 2.0, 0.0)
	
	# LowerSpine rotation sway
	var lower_spine_track = idle_anim.add_track(Animation.TYPE_VALUE)
	idle_anim.track_set_path(lower_spine_track, NodePath("Skeleton2D:CenterBone/LowerSpine:rotation"))
	idle_anim.track_set_interpolation_type(lower_spine_track, Animation.INTERPOLATION_CUBIC)
	idle_anim.track_insert_key(lower_spine_track, 0.0, 0.0)
	idle_anim.track_insert_key(lower_spine_track, 0.5, -0.03)
	idle_anim.track_insert_key(lower_spine_track, 1.0, 0.0)
	idle_anim.track_insert_key(lower_spine_track, 1.5, 0.03)
	idle_anim.track_insert_key(lower_spine_track, 2.0, 0.0)
	
	# LowerChest rotation sway
	var lower_chest_track = idle_anim.add_track(Animation.TYPE_VALUE)
	idle_anim.track_set_path(lower_chest_track, NodePath("Skeleton2D:CenterBone/LowerChest:rotation"))
	idle_anim.track_set_interpolation_type(lower_chest_track, Animation.INTERPOLATION_CUBIC)
	idle_anim.track_insert_key(lower_chest_track, 0.0, 0.0)
	idle_anim.track_insert_key(lower_chest_track, 0.5, -0.04)
	idle_anim.track_insert_key(lower_chest_track, 1.0, 0.0)
	idle_anim.track_insert_key(lower_chest_track, 1.5, 0.04)
	idle_anim.track_insert_key(lower_chest_track, 2.0, 0.0)
	
	# Chest rotation sway
	var chest_track = idle_anim.add_track(Animation.TYPE_VALUE)
	idle_anim.track_set_path(chest_track, NodePath("Skeleton2D:CenterBone/LowerChest/Chest:rotation"))
	idle_anim.track_set_interpolation_type(chest_track, Animation.INTERPOLATION_CUBIC)
	idle_anim.track_insert_key(chest_track, 0.0, 0.0)
	idle_anim.track_insert_key(chest_track, 0.5, 0.02)
	idle_anim.track_insert_key(chest_track, 1.0, 0.0)
	idle_anim.track_insert_key(chest_track, 1.5, -0.02)
	idle_anim.track_insert_key(chest_track, 2.0, 0.0)
	
	# Neck rotation sway
	var neck_track = idle_anim.add_track(Animation.TYPE_VALUE)
	idle_anim.track_set_path(neck_track, NodePath("Skeleton2D:CenterBone/LowerChest/Chest/Neck:rotation"))
	idle_anim.track_set_interpolation_type(neck_track, Animation.INTERPOLATION_CUBIC)
	idle_anim.track_insert_key(neck_track, 0.0, 0.0)
	idle_anim.track_insert_key(neck_track, 0.5, 0.03)
	idle_anim.track_insert_key(neck_track, 1.0, 0.0)
	idle_anim.track_insert_key(neck_track, 1.5, -0.03)
	idle_anim.track_insert_key(neck_track, 2.0, 0.0)
	
	# Add the animation to the library
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("idle", idle_anim)
	animation_player.add_animation_library("", anim_library)
	
	# Play the idle animation
	animation_player.play("idle")

func setup_test_environment():
	# Get viewport size for debugging
	var viewport_size = get_viewport().size
	print("Viewport size: ", viewport_size)
	
	# Create a floor
	var floor = StaticBody2D.new()
	floor.name = "TestFloor"
	
	# Add collision shape
	var floor_shape = CollisionShape2D.new()
	var floor_rect = RectangleShape2D.new()
	floor_rect.size = Vector2(3000, 100)  # Make it thicker and wider
	floor_shape.shape = floor_rect
	floor.add_child(floor_shape)
	
	# Add visual representation of floor
	var floor_visual = ColorRect.new()
	floor_visual.size = Vector2(3000, 100)
	floor_visual.position = Vector2(-1500, 50)  # Center the visual on the collision
	floor_visual.color = Color(0.2, 0.5, 0.2)  # Green color for visibility
	floor.add_child(floor_visual)
	
	# Position the floor at bottom of visible area
	var floor_y = 400  # Fixed position that should be visible
	floor.position = Vector2(viewport_size.x / 2, floor_y)
	print("Floor position: ", floor.position)
	
	# Add floor to the scene root
	get_tree().current_scene.add_child(floor)
	
	# Center the character above the floor
	var char_y = floor_y - 300  # Much higher above floor to avoid collision
	position = Vector2(viewport_size.x / 2, char_y)
	print("Character position: ", position)
	print("Floor Y: ", floor_y, " Character Y: ", char_y)
	
	# Add camera centered on character
	var camera = Camera2D.new()
	camera.enabled = true
	camera.position = Vector2.ZERO  # Local to character
	camera.zoom = Vector2(0.5, 0.5)  # Zoom out to see more
	add_child(camera)
	
	# Add background for reference
	var background = ColorRect.new()
	background.size = Vector2(3000, 2000)
	background.position = Vector2(-1500, -1000)
	background.color = Color(0.9, 0.9, 0.95)  # Light blue
	background.z_index = -10
	get_tree().current_scene.add_child(background)

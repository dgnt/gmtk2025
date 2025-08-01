@tool
extends EditorScript

# Stage 2: Smart Skeleton Creation
# This script analyzes sprite shapes to automatically place bones

var polygon_data_path = "res://sprite_polygons.json"
var common_offset = Vector2(400, 500)  # Same offset used in stage 1

func _run():
	print("=== DACHSHUND BUILDER - STAGE 2: SMART SKELETON CREATION ===")
	print("Analyzing sprite shapes for intelligent bone placement...")
	
	# Load the stage 1 scene
	var scene_path = "res://scenes/characters/GeneratedDachshund_Stage1.tscn"
	if not FileAccess.file_exists(scene_path):
		print("ERROR: Stage 1 scene not found. Please run dachshund_builder_stage1.gd first.")
		return
	
	# Load polygon data for analysis
	var file = FileAccess.open(polygon_data_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("ERROR: Failed to parse polygon data")
		return
	var polygon_data = json.data
	
	var packed_scene = load(scene_path) as PackedScene
	var root = packed_scene.instantiate()
	
	# Create Skeleton2D
	var skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	root.add_child(skeleton)
	skeleton.owner = root
	
	# Analyze sprite positions and shapes
	var sprite_info = analyze_sprites(polygon_data)
	
	# Build smart skeletal hierarchy based on sprite analysis
	
	# Find body center as hip position - for standing character, hip is at bottom of body
	var body_bounds = sprite_info["body"]
	var hip_pos = Vector2(body_bounds["center"].x - common_offset.x, 
						 body_bounds["y"] + body_bounds["height"] * 0.8 - common_offset.y)  # Hip near bottom of body
	var hip = create_bone(skeleton, "Hip", hip_pos)
	
	# Create spine along body length
	var spine_bones = create_spine_chain(hip, body_bounds, sprite_info)
	var chest = spine_bones[-1]  # Last spine bone is chest
	
	# Create tail based on tail sprite
	if sprite_info.has("tail"):
		create_tail_chain(hip, sprite_info["tail"])
	
	# Create legs based on leg sprites
	# For standing dachshund, all legs connect near the bottom of the body
	if sprite_info.has("legs") and sprite_info.has("arms"):
		# Both front and back legs connect near hip for standing pose
		print("Creating legs at hip position: " + str(hip.position))
		create_leg_bones(hip, sprite_info["legs"], "back")
		create_leg_bones(hip, sprite_info["arms"], "front")
	
	# Create neck and head based on head position
	if sprite_info.has("head"):
		create_head_chain(chest, sprite_info["head"], sprite_info)
	
	# Set owners for all bones
	set_owner_recursive(skeleton, root)
	
	# Set up modification stack for IK (optional for later)
	var modification_stack = SkeletonModificationStack2D.new()
	modification_stack.enabled = true
	modification_stack.modification_count = 0
	skeleton.set_modification_stack(modification_stack)
	
	# Link polygons to skeleton
	var polygons_container = root.get_node("Polygons")
	if polygons_container:
		for polygon in polygons_container.get_children():
			if polygon is Polygon2D:
				polygon.skeleton = NodePath("../../Skeleton2D")
				print("Linked polygon '" + polygon.name + "' to skeleton")
	
	# Save the scene
	var new_packed_scene = PackedScene.new()
	new_packed_scene.pack(root)
	var save_path = "res://scenes/characters/GeneratedDachshund_Stage2.tscn"
	var error = ResourceSaver.save(new_packed_scene, save_path)
	
	if error == OK:
		print("\n✓ Stage 2 Complete!")
		print("Created skeletal hierarchy with " + str(skeleton.get_bone_count()) + " bones")
		print("Scene saved to: " + save_path)
		print("\n=== SMART BONE PLACEMENT ===")
		print("• Bones automatically positioned based on sprite shapes")
		print("• Joint positions calculated from sprite boundaries")
		print("• Bone lengths matched to sprite dimensions")
		print("\n=== NEXT STEPS ===")
		print("1. Open the scene in the editor: " + save_path)
		print("2. Select Skeleton2D and enable 'Visible' to see bones")
		print("3. Fine-tune bone positions if needed")
		print("4. Save any manual adjustments")
		print("5. Run dachshund_builder_stage3.gd for weight painting setup")
	else:
		print("ERROR: Failed to save scene")
	
	# Clean up
	root.queue_free()

func create_bone(parent: Node, bone_name: String, offset: Vector2) -> Bone2D:
	var bone = Bone2D.new()
	bone.name = bone_name
	bone.position = offset
	bone.rest = Transform2D.IDENTITY
	bone.rest.origin = offset
	parent.add_child(bone)
	# Owner will be set later after all bones are created
	return bone

func set_owner_recursive(node: Node, owner: Node):
	for child in node.get_children():
		child.owner = owner
		set_owner_recursive(child, owner)

func analyze_sprites(polygon_data: Dictionary) -> Dictionary:
	var sprite_info = {}
	
	for sprite_name in polygon_data:
		var data = polygon_data[sprite_name]
		if not data.has("bounds"):
			continue
			
		var bounds = data["bounds"]
		var info = {}
		info["center"] = Vector2(bounds["center"][0], bounds["center"][1])
		info["width"] = bounds["width"]
		info["height"] = bounds["height"]
		info["x"] = bounds["x"]
		info["y"] = bounds["y"]
		info["aspect_ratio"] = bounds["width"] / bounds["height"] if bounds["height"] > 0 else 1.0
		info["polygon"] = data["polygon"]
		
		# Clean sprite name (remove .png)
		var clean_name = sprite_name.get_basename()
		sprite_info[clean_name] = info
		print("Analyzed " + clean_name + ": " + str(info["width"]) + "x" + str(info["height"]) + 
			  " at (" + str(info["x"]) + ", " + str(info["y"]) + ")")
	
	return sprite_info

func create_spine_chain(hip: Bone2D, body_bounds: Dictionary, sprite_info: Dictionary) -> Array:
	var spine_bones = []
	var spine_count = 4  # Number of spine bones
	
	# For standing character, spine goes vertically from hip upward
	var body_bottom = Vector2(body_bounds["center"].x - common_offset.x, 
							 body_bounds["y"] + body_bounds["height"] * 0.8 - common_offset.y)
	var body_top = Vector2(body_bounds["center"].x - common_offset.x,
						  body_bounds["y"] + body_bounds["height"] * 0.2 - common_offset.y)
	
	# Create spine bones going upward
	var prev_bone = hip
	var prev_global_pos = hip.position
	for i in range(spine_count):
		var t = (i + 1.0) / spine_count
		var spine_global_pos = body_bottom.lerp(body_top, t)
		var local_pos = spine_global_pos - prev_global_pos
		
		var spine_name = "Spine" + str(i + 1) if i < spine_count - 1 else "Chest"
		var spine_bone = create_bone(prev_bone, spine_name, local_pos)
		spine_bones.append(spine_bone)
		prev_bone = spine_bone
		prev_global_pos = spine_global_pos
		
	return spine_bones

func create_tail_chain(hip: Bone2D, tail_bounds: Dictionary):
	var tail_segments = 3
	
	# For standing character, tail extends down and curves
	var tail_start = Vector2(tail_bounds["center"].x - common_offset.x,
							tail_bounds["y"] - common_offset.y)  # Top of tail
	var tail_end = Vector2(tail_bounds["center"].x - common_offset.x - tail_bounds["width"] * 0.3,
						  tail_bounds["y"] + tail_bounds["height"] - common_offset.y)  # Bottom left of tail
	
	# First tail bone connects to hip
	var tail_base_pos = tail_start - hip.position
	var tail_base = create_bone(hip, "TailBase", tail_base_pos)
	
	# Create remaining tail segments
	var prev_bone = tail_base
	var prev_global_pos = tail_start
	for i in range(1, tail_segments):
		var t = float(i) / (tail_segments - 1)
		var tail_global_pos = tail_start.lerp(tail_end, t)
		var local_pos = tail_global_pos - prev_global_pos
		
		var bone_name = "TailMid" if i == 1 else "TailTip"
		var tail_bone = create_bone(prev_bone, bone_name, local_pos)
		prev_bone = tail_bone
		prev_global_pos = tail_global_pos

func create_leg_bones(parent: Bone2D, leg_bounds: Dictionary, leg_type: String):
	# For standing character, legs extend downward from body
	var parent_global = get_bone_global_position(parent)
	
	# Legs start at parent position and go down
	var leg_top = parent_global
	var leg_bottom = Vector2(leg_bounds["center"].x - common_offset.x,
							leg_bounds["y"] + leg_bounds["height"] - common_offset.y)
	
	# For front/back legs, offset left and right from center
	var offset_x = 20
	
	for side in ["L", "R"]:
		var x_offset = -offset_x if side == "L" else offset_x
		
		# Upper leg bone starts from parent
		var leg_start_pos = Vector2(x_offset, 0)  # Offset from parent
		var leg_name = "FrontLeg" + side if leg_type == "front" else "BackLeg" + side
		var leg_bone = create_bone(parent, leg_name, leg_start_pos)
		
		# Calculate leg length to reach bottom
		var leg_length = leg_bottom.y - leg_top.y
		
		# Lower leg bone (shin for back legs)
		var shin_length = leg_length * 0.6
		var shin_name = "FrontFoot" + side if leg_type == "front" else "BackShin" + side
		var shin_bone = create_bone(leg_bone, shin_name, Vector2(0, shin_length))
		
		# Foot bone for back legs
		if leg_type == "back":
			var foot_length = leg_length * 0.4
			var foot_bone = create_bone(shin_bone, "BackFoot" + side, Vector2(0, foot_length))

func create_head_chain(chest: Bone2D, head_bounds: Dictionary, sprite_info: Dictionary):
	# Calculate neck position - between chest and head
	var head_center = Vector2(head_bounds["center"].x - common_offset.x,
							 head_bounds["center"].y - common_offset.y)
	
	# Get chest global position by accumulating parent transforms
	var chest_global_pos = get_bone_global_position(chest)
	
	# Neck connects chest to head
	var neck_global_pos = chest_global_pos.lerp(head_center, 0.3)
	var neck_local_pos = neck_global_pos - chest_global_pos
	var neck = create_bone(chest, "Neck", neck_local_pos)
	
	# Head bone at head center
	var head_local_pos = head_center - neck_global_pos
	var head = create_bone(neck, "Head", head_local_pos)
	
	# Nose bone if we have nose sprite
	if sprite_info.has("nose"):
		var nose_bounds = sprite_info["nose"]
		var nose_global_pos = Vector2(nose_bounds["center"].x - common_offset.x,
									 nose_bounds["center"].y - common_offset.y)
		var nose_local_pos = nose_global_pos - head_center
		create_bone(head, "Nose", nose_local_pos)
	
	# Ear bones
	for ear_type in ["ear-front", "back-ear"]:
		if sprite_info.has(ear_type):
			var ear_bounds = sprite_info[ear_type]
			var ear_tip = Vector2(ear_bounds["center"].x - common_offset.x,
								 ear_bounds["y"] - common_offset.y)
			var ear_local_pos = ear_tip - head_center
			var ear_name = "EarFront" if ear_type == "ear-front" else "EarBack"
			create_bone(head, ear_name, ear_local_pos)

func get_bone_global_position(bone: Bone2D) -> Vector2:
	var global_pos = bone.position
	var parent = bone.get_parent()
	while parent and parent is Bone2D:
		global_pos += parent.position
		parent = parent.get_parent()
	return global_pos

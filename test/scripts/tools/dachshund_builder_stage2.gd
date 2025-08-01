@tool
extends EditorScript

# Stage 2: Automatic Shape-Based Skeleton Creation
# This script analyzes sprite shapes and automatically creates bones

var polygon_data_path = "res://sprite_polygons.json"
var common_offset = Vector2(400, 500)  # Same offset used in stage 1

# Bone generation parameters
var MIN_BONE_LENGTH = 20.0
var CONNECTION_THRESHOLD = 100.0  # Max distance to consider sprites connected

func _run():
	print("=== DACHSHUND BUILDER - STAGE 2: AUTOMATIC SKELETON CREATION ===")
	print("Analyzing sprite shapes for automatic bone generation...")
	
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
	
	# Analyze all sprites
	var sprite_info = analyze_sprites(polygon_data)
	var sprite_bones = {}  # Maps sprite name to its primary bone
	
	# Step 1: Create primary bones for each sprite based on shape
	print("\n--- Creating Primary Bones ---")
	for sprite_name in sprite_info:
		var info = sprite_info[sprite_name]
		var primary_bone = create_bone_for_shape(skeleton, sprite_name, info)
		if primary_bone:
			sprite_bones[sprite_name] = primary_bone
			print("Created bone for " + sprite_name + " along " + info["primary_axis"])
	
	# Step 2: Find connections between sprites and create connection bones
	print("\n--- Finding Connections ---")
	var connections = find_sprite_connections(sprite_info)
	
	# Step 3: Build hierarchy based on connections
	print("\n--- Building Hierarchy ---")
	build_bone_hierarchy(sprite_bones, connections, sprite_info)
	
	# Set owners for all bones
	set_owner_recursive(skeleton, root)
	
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
		print("Automatically created " + str(skeleton.get_bone_count()) + " bones")
		print("Scene saved to: " + save_path)
		print("\n=== AUTOMATIC BONE GENERATION ===")
		print("• Bones created along major axes of sprites")
		print("• Connections found between nearby sprites")
		print("• Hierarchy built based on proximity and size")
		print("\n=== NEXT STEPS ===")
		print("1. Open the scene in the editor: " + save_path)
		print("2. Review the automatic bone placement")
		print("3. Fine-tune if needed")
		print("4. Run dachshund_builder_stage3.gd for weight painting")
	else:
		print("ERROR: Failed to save scene")
	
	# Clean up
	root.queue_free()

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
		info["polygon"] = data["polygon"]
		
		# Analyze shape to determine primary axis
		var aspect_ratio = bounds["width"] / bounds["height"] if bounds["height"] > 0 else 1.0
		info["aspect_ratio"] = aspect_ratio
		
		if aspect_ratio > 1.5:
			info["shape_type"] = "horizontal"
			info["primary_axis"] = "horizontal"
		elif aspect_ratio < 0.67:
			info["shape_type"] = "vertical"
			info["primary_axis"] = "vertical"
		else:
			info["shape_type"] = "square"
			info["primary_axis"] = "diagonal"
		
		# Calculate axis endpoints for bone placement
		if info["primary_axis"] == "horizontal":
			info["axis_start"] = Vector2(info["x"], info["center"].y)
			info["axis_end"] = Vector2(info["x"] + info["width"], info["center"].y)
		elif info["primary_axis"] == "vertical":
			info["axis_start"] = Vector2(info["center"].x, info["y"])
			info["axis_end"] = Vector2(info["center"].x, info["y"] + info["height"])
		else:  # diagonal
			info["axis_start"] = Vector2(info["x"], info["y"])
			info["axis_end"] = Vector2(info["x"] + info["width"], info["y"] + info["height"])
		
		var clean_name = sprite_name.get_basename()
		sprite_info[clean_name] = info
		print("Analyzed " + clean_name + ": " + info["shape_type"] + " shape (" + 
			  str(int(info["width"])) + "x" + str(int(info["height"])) + ")")
	
	return sprite_info

func create_bone_for_shape(skeleton: Skeleton2D, sprite_name: String, info: Dictionary) -> Bone2D:
	# Create a bone along the major axis of the shape
	var start_pos = Vector2(info["axis_start"].x - common_offset.x, 
						   info["axis_start"].y - common_offset.y)
	var end_pos = Vector2(info["axis_end"].x - common_offset.x,
						 info["axis_end"].y - common_offset.y)
	
	var bone_length = start_pos.distance_to(end_pos)
	if bone_length < MIN_BONE_LENGTH:
		print("  Skipping " + sprite_name + " - too small")
		return null
	
	# Create bone at start position
	var bone = Bone2D.new()
	bone.name = sprite_name + "_bone"
	bone.position = start_pos
	bone.rest = Transform2D.IDENTITY
	bone.rest.origin = start_pos
	
	# Calculate rotation to point toward end
	var direction = (end_pos - start_pos).normalized()
	bone.rotation = direction.angle()
	
	# Add to skeleton temporarily (will reorganize hierarchy later)
	skeleton.add_child(bone)
	
	return bone

func find_sprite_connections(sprite_info: Dictionary) -> Array:
	var connections = []
	var sprites = sprite_info.keys()
	
	# Check each pair of sprites for proximity
	for i in range(sprites.size()):
		for j in range(i + 1, sprites.size()):
			var sprite1 = sprites[i]
			var sprite2 = sprites[j]
			var info1 = sprite_info[sprite1]
			var info2 = sprite_info[sprite2]
			
			# Calculate distance between sprite centers
			var dist = info1["center"].distance_to(info2["center"])
			
			# Also check distance between closest edges
			var edge_dist = get_min_edge_distance(info1, info2)
			
			if edge_dist < CONNECTION_THRESHOLD:
				connections.append({
					"from": sprite1,
					"to": sprite2,
					"distance": edge_dist,
					"center_distance": dist
				})
				print("Found connection: " + sprite1 + " <-> " + sprite2 + 
					  " (edge dist: " + str(int(edge_dist)) + ")")
	
	# Sort connections by distance (closest first)
	connections.sort_custom(func(a, b): return a["distance"] < b["distance"])
	
	return connections

func get_min_edge_distance(info1: Dictionary, info2: Dictionary) -> float:
	# Simple approximation using bounding boxes
	var rect1 = Rect2(info1["x"], info1["y"], info1["width"], info1["height"])
	var rect2 = Rect2(info2["x"], info2["y"], info2["width"], info2["height"])
	
	# Check if rectangles overlap
	if rect1.intersects(rect2):
		return 0.0
	
	# Calculate minimum distance between edges
	var x_dist = 0.0
	var y_dist = 0.0
	
	if rect1.position.x + rect1.size.x < rect2.position.x:
		x_dist = rect2.position.x - (rect1.position.x + rect1.size.x)
	elif rect2.position.x + rect2.size.x < rect1.position.x:
		x_dist = rect1.position.x - (rect2.position.x + rect2.size.x)
	
	if rect1.position.y + rect1.size.y < rect2.position.y:
		y_dist = rect2.position.y - (rect1.position.y + rect1.size.y)
	elif rect2.position.y + rect2.size.y < rect1.position.y:
		y_dist = rect1.position.y - (rect2.position.y + rect2.size.y)
	
	return sqrt(x_dist * x_dist + y_dist * y_dist)

func build_bone_hierarchy(sprite_bones: Dictionary, connections: Array, sprite_info: Dictionary):
	var connected_sprites = {}
	var root_bone = null
	
	# Find the largest sprite to use as root (usually the body)
	var largest_sprite = ""
	var largest_area = 0.0
	for sprite_name in sprite_bones:
		var info = sprite_info[sprite_name]
		var area = info["width"] * info["height"]
		if area > largest_area:
			largest_area = area
			largest_sprite = sprite_name
	
	if largest_sprite != "":
		root_bone = sprite_bones[largest_sprite]
		connected_sprites[largest_sprite] = true
		print("Root bone: " + largest_sprite)
	
	# Build hierarchy based on connections
	var iterations = 0
	while connected_sprites.size() < sprite_bones.size() and iterations < 10:
		iterations += 1
		
		for connection in connections:
			var from_sprite = connection["from"]
			var to_sprite = connection["to"]
			
			# Check if one is connected and the other isn't
			if connected_sprites.has(from_sprite) and not connected_sprites.has(to_sprite):
				# Connect to_sprite to from_sprite
				if sprite_bones.has(to_sprite) and sprite_bones.has(from_sprite):
					var parent_bone = sprite_bones[from_sprite]
					var child_bone = sprite_bones[to_sprite]
					reparent_bone(child_bone, parent_bone, sprite_info[to_sprite], sprite_info[from_sprite])
					connected_sprites[to_sprite] = true
					print("Connected " + to_sprite + " to " + from_sprite)
					
			elif connected_sprites.has(to_sprite) and not connected_sprites.has(from_sprite):
				# Connect from_sprite to to_sprite
				if sprite_bones.has(to_sprite) and sprite_bones.has(from_sprite):
					var parent_bone = sprite_bones[to_sprite]
					var child_bone = sprite_bones[from_sprite]
					reparent_bone(child_bone, parent_bone, sprite_info[from_sprite], sprite_info[to_sprite])
					connected_sprites[from_sprite] = true
					print("Connected " + from_sprite + " to " + to_sprite)
	
	# Handle any unconnected bones
	for sprite_name in sprite_bones:
		if not connected_sprites.has(sprite_name) and root_bone:
			var bone = sprite_bones[sprite_name]
			if bone.get_parent() == bone.get_tree().edited_scene_root:
				print("Warning: " + sprite_name + " not connected, attaching to root")
				reparent_bone(bone, root_bone, sprite_info[sprite_name], sprite_info[largest_sprite])

func reparent_bone(child: Bone2D, parent: Bone2D, child_info: Dictionary, parent_info: Dictionary):
	# Calculate connection point between sprites
	var child_center = Vector2(child_info["center"].x - common_offset.x,
							  child_info["center"].y - common_offset.y)
	var parent_center = Vector2(parent_info["center"].x - common_offset.x,
							   parent_info["center"].y - common_offset.y)
	
	# Get current positions
	var child_global = child.position
	var parent_global = parent.position
	
	# Remove from current parent
	var old_parent = child.get_parent()
	old_parent.remove_child(child)
	
	# Add to new parent
	parent.add_child(child)
	
	# Calculate local position relative to new parent
	child.position = child_global - parent_global
	child.rest.origin = child.position

func create_bone(parent: Node, bone_name: String, offset: Vector2) -> Bone2D:
	var bone = Bone2D.new()
	bone.name = bone_name
	bone.position = offset
	bone.rest = Transform2D.IDENTITY
	bone.rest.origin = offset
	parent.add_child(bone)
	return bone

func set_owner_recursive(node: Node, owner: Node):
	for child in node.get_children():
		child.owner = owner
		set_owner_recursive(child, owner)

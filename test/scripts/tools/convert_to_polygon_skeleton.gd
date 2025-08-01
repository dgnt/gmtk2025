@tool
extends EditorScript

func _run():
	# Load polygon data
	var importer = preload("res://scripts/tools/polygon_importer.gd")
	var polygon_data = importer.load_polygon_data("res://sprite_polygons.json")
	
	# Create new scene structure
	var root = CharacterBody2D.new()
	root.name = "DachshundPolygon"
	
	# Create Skeleton2D
	var skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	root.add_child(skeleton)
	skeleton.owner = root
	
	# Create bone hierarchy for standing dog
	# Start at the center of the body (roughly the hips)
	var hip_bone = create_bone(skeleton, "Hip", Vector2(0, 300))
	
	# Spine goes up from hip
	var spine_bone = create_bone(hip_bone, "Spine", Vector2(0, -150))
	
	# Chest/shoulders at top of spine
	var chest_bone = create_bone(spine_bone, "Chest", Vector2(0, -100))
	
	# Head extends up from chest
	var neck_bone = create_bone(chest_bone, "Neck", Vector2(0, -80))
	var head_bone = create_bone(neck_bone, "Head", Vector2(0, -100))
	var head_tip = create_bone(head_bone, "HeadTip", Vector2(50, -50))  # Nose direction
	
	# Front legs down from chest
	var front_leg_l = create_bone(chest_bone, "FrontLegL", Vector2(-30, 50))
	var front_foot_l = create_bone(front_leg_l, "FrontFootL", Vector2(0, 150))
	
	var front_leg_r = create_bone(chest_bone, "FrontLegR", Vector2(30, 50))
	var front_foot_r = create_bone(front_leg_r, "FrontFootR", Vector2(0, 150))
	
	# Back legs down from hip
	var back_leg_l = create_bone(hip_bone, "BackLegL", Vector2(-30, 50))
	var back_foot_l = create_bone(back_leg_l, "BackFootL", Vector2(0, 150))
	
	var back_leg_r = create_bone(hip_bone, "BackLegR", Vector2(30, 50))
	var back_foot_r = create_bone(back_leg_r, "BackFootR", Vector2(0, 150))
	
	# Tail extends back/down from hip
	var tail_base = create_bone(hip_bone, "TailBase", Vector2(-50, 50))
	var tail_mid = create_bone(tail_base, "TailMid", Vector2(-50, 30))
	var tail_tip = create_bone(tail_mid, "TailTip", Vector2(-30, 10))
	
	# Set owners for all bones recursively
	set_owner_recursive(skeleton, root)
	
	# Create polygons container
	var polygons_node = Node2D.new()
	polygons_node.name = "Polygons"
	root.add_child(polygons_node)
	polygons_node.owner = root
	
	# Map sprite files to polygon creation
	var sprite_configs = {
		"body.png": {
			"texture_path": "res://assets/sprites/dachshund/body.png",
			"z_index": 0
		},
		"body-light.png": {
			"texture_path": "res://assets/sprites/dachshund/body-light.png", 
			"z_index": 1
		},
		"tail.png": {
			"texture_path": "res://assets/sprites/dachshund/tail.png",
			"z_index": -1
		},
		"legs.png": {
			"texture_path": "res://assets/sprites/dachshund/legs.png",
			"z_index": -1
		},
		"arms.png": {
			"texture_path": "res://assets/sprites/dachshund/arms.png",
			"z_index": 1
		},
		"head.png": {
			"texture_path": "res://assets/sprites/dachshund/head.png",
			"z_index": 2
		},
		"back-ear.png": {
			"texture_path": "res://assets/sprites/dachshund/back-ear.png",
			"z_index": 1
		},
		"ear-front.png": {
			"texture_path": "res://assets/sprites/dachshund/ear-front.png",
			"z_index": 3
		},
		"face.png": {
			"texture_path": "res://assets/sprites/dachshund/face.png",
			"z_index": 4
		},
		"nose.png": {
			"texture_path": "res://assets/sprites/dachshund/nose.png",
			"z_index": 5
		}
	}
	
	# Create Polygon2D for each sprite
	for sprite_name in sprite_configs:
		if polygon_data.has(sprite_name):
			var config = sprite_configs[sprite_name]
			var data = polygon_data[sprite_name]
			
			# Create Polygon2D
			var poly = create_polygon_from_data(
				data, 
				config["texture_path"],
				sprite_name.get_basename()
			)
			
			poly.z_index = config["z_index"]
			
			polygons_node.add_child(poly)
			poly.owner = root
			
			# Set skeleton path after adding to tree
			poly.skeleton = NodePath("../../Skeleton2D")
			
			print("Created polygon: ", sprite_name)
	
	# Save the new scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	ResourceSaver.save(packed_scene, "res://scenes/characters/DachshundPolygon.tscn")
	
	print("\nNew scene saved to: res://scenes/characters/DachshundPolygon.tscn")
	print("Next steps:")
	print("1. Open the new scene")
	print("2. Select each Polygon2D and enter UV editor")
	print("3. Go to Bones → Paint mode")
	print("4. Click 'Sync Bones to Polygon'")
	print("5. Paint bone weights (white = full influence)")
	
	# Clean up
	root.queue_free()

func set_owner_recursive(node: Node, owner: Node):
	for child in node.get_children():
		child.owner = owner
		set_owner_recursive(child, owner)

func create_bone(parent: Node, bone_name: String, offset: Vector2) -> Bone2D:
	var bone = Bone2D.new()
	bone.name = bone_name
	bone.position = offset
	bone.rest = Transform2D.IDENTITY
	bone.rest.origin = offset
	parent.add_child(bone)
	# Owner will be set later when we have the root
	return bone

func create_polygon_from_data(data: Dictionary, texture_path: String, poly_name: String) -> Polygon2D:
	var poly = Polygon2D.new()
	poly.name = poly_name
	
	# Load texture
	var texture = load(texture_path) as Texture2D
	poly.texture = texture
	
	# Convert polygon points
	var points = PackedVector2Array()
	for point in data["polygon"]:
		points.append(Vector2(point[0], point[1]))
	
	poly.polygon = points
	
	# Set UV to match polygon (identity mapping)
	poly.uv = points
	
	# Position polygons appropriately for standing dog
	if data.has("bounds"):
		var bounds = data["bounds"]
		
		# Position based on which body part this is
		match poly_name:
			"body":
				poly.position = Vector2(0, 200)  # Center body
			"body-light":
				poly.position = Vector2(0, 200)  # Same as body
			"head":
				poly.position = Vector2(0, -50)  # Head up high
			"face":
				poly.position = Vector2(20, -50)  # Face forward
			"nose":
				poly.position = Vector2(50, -50)  # Nose forward
			"ear-front":
				poly.position = Vector2(10, -100)  # Ears on head
			"back-ear":
				poly.position = Vector2(-10, -100)
			"arms":
				poly.position = Vector2(0, 250)  # Front legs
			"legs":
				poly.position = Vector2(0, 350)  # Back legs
			"tail":
				poly.position = Vector2(-100, 300)  # Tail back
			_:
				poly.position = Vector2.ZERO
		
		# Center the polygon points around origin
		var offset = Vector2(bounds["center"][0], bounds["center"][1])
		var centered_points = PackedVector2Array()
		for point in points:
			centered_points.append(point - offset)
		poly.polygon = centered_points
		poly.uv = centered_points
	
	return poly

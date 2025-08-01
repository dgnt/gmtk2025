@tool
extends EditorScript

# Stage 1: Polygon Detection & Creation
# This script creates Polygon2D nodes from dachshund sprites with proper layering

var sprite_dir = "res://assets/sprites/dachshund/"
var polygon_data_path = "res://sprite_polygons.json"

# Common offset - using body center as reference point
var common_offset = Vector2(332.5, 490.5)  # Body sprite center

# Z-index configuration for proper layering
# Using actual positions from the polygon data JSON
var sprite_configs = {
	"tail.png": { "z_index": -2 },
	"back-ear.png": { "z_index": -1 },
	"leg-back.png": { "z_index": 0 },
	"leg-front.png": { "z_index": 0 },
	"body.png": { "z_index": 1 },
	"arm-back.png": { "z_index": 2 },
	"arm-front.png": { "z_index": 2 },
	"body-light.png": { "z_index": 3 },
	"head.png": { "z_index": 4 },
	"ear-front.png": { "z_index": 5 },
	"face.png": { "z_index": 6 },
	"nose.png": { "z_index": 7 }
}

func _run():
	print("=== DACHSHUND BUILDER - STAGE 1: POLYGON CREATION ===")
	print("Creating polygon structure from sprites...")
	
	# First, ensure polygon data exists
	if not FileAccess.file_exists(polygon_data_path):
		print("ERROR: Polygon data not found. Please run detect_sprite_polygons.py first.")
		print("Run: python detect_sprite_polygons.py")
		return
	
	# Load polygon data
	var file = FileAccess.open(polygon_data_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("ERROR: Failed to parse polygon data")
		return
		
	var polygon_data = json.data
	
	# Create root CharacterBody2D
	var root = CharacterBody2D.new()
	root.name = "GeneratedDachshund"
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CapsuleShape2D.new()
	shape.radius = 40
	shape.height = 200
	collision.shape = shape
	collision.rotation_degrees = 90
	root.add_child(collision)
	collision.owner = root
	
	# Create polygons container
	var polygons_container = Node2D.new()
	polygons_container.name = "Polygons"
	root.add_child(polygons_container)
	polygons_container.owner = root
	
	# Create sprites container
	var sprites_container = Node2D.new()
	sprites_container.name = "Sprites"
	root.add_child(sprites_container)
	sprites_container.owner = root
	
	# Create Sprite2D nodes from the same sprite files
	print("Creating Sprite2D nodes...")
	var sprite_count = 0
	for sprite_name in sprite_configs:
		var texture_path = sprite_dir + sprite_name
		var texture = load(texture_path) as Texture2D
		if texture:
			var sprite = Sprite2D.new()
			sprite.name = sprite_name.get_basename().capitalize().replace("-", "")
			sprite.texture = texture
			
			# Center the sprite and position it at origin
			sprite.centered = true  # This centers the texture at the sprite's position
			sprite.position = Vector2(0, 0)  # All sprites at origin
			
			sprites_container.add_child(sprite)
			sprite.owner = root
			sprite_count += 1
		
	print("Created " + str(sprite_count) + " Sprite2D nodes")
	
	# Process each sprite
	var created_count = 0
	for sprite_name in sprite_configs:
		if not polygon_data.has(sprite_name):
			print("WARNING: No polygon data for " + sprite_name)
			continue
			
		var config = sprite_configs[sprite_name]
		var data = polygon_data[sprite_name]
		
		# Create Polygon2D
		var poly = Polygon2D.new()
		poly.name = sprite_name.get_basename()
		
		# Load and set texture
		var texture_path = sprite_dir + sprite_name
		var texture = load(texture_path) as Texture2D
		if not texture:
			print("ERROR: Could not load texture " + texture_path)
			continue
		poly.texture = texture
		
		# Convert polygon points
		var points = PackedVector2Array()
		for point in data["polygon"]:
			points.append(Vector2(point[0], point[1]))
		
		# Center the polygon around its bounds center
		if data.has("bounds"):
			var bounds = data["bounds"]
			var center = Vector2(bounds["center"][0], bounds["center"][1])
			var centered_points = PackedVector2Array()
			for point in points:
				centered_points.append(point - center)
			poly.polygon = centered_points
			poly.uv = centered_points
		else:
			poly.polygon = points
			poly.uv = points
		
		# Use the actual sprite positions from the polygon data
		if data.has("bounds"):
			var bounds = data["bounds"]
			# Position relative to body center
			poly.position = Vector2(bounds["center"][0] - common_offset.x, bounds["center"][1] - common_offset.y)
		else:
			print("WARNING: No bounds data for " + sprite_name)
			poly.position = Vector2.ZERO
		
		poly.z_index = config["z_index"]
		
		# Add to container
		polygons_container.add_child(poly)
		poly.owner = root
		
		created_count += 1
		print("Created polygon: " + sprite_name + " (z-index: " + str(config["z_index"]) + ")")
	
	# Save the scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	var save_path = "res://scenes/characters/GeneratedDachshund_Stage1.tscn"
	var error = ResourceSaver.save(packed_scene, save_path)
	
	if error == OK:
		print("\n✓ Stage 1 Complete!")
		print("Created " + str(created_count) + " polygon layers")
		print("Scene saved to: " + save_path)
		print("\n=== NEXT STEPS ===")
		print("1. Open the scene in the editor: " + save_path)
		print("2. Review the polygon layering (use Scene panel)")
		print("3. Adjust polygon positions if needed")
		print("4. Save any manual adjustments")
		print("5. Run dachshund_builder_stage2.gd to create the skeleton")
	else:
		print("ERROR: Failed to save scene")
	
	# Clean up
	root.queue_free()

func set_owner_recursive(node: Node, owner: Node):
	for child in node.get_children():
		child.owner = owner
		set_owner_recursive(child, owner)

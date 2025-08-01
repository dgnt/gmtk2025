@tool
extends EditorScript

class_name PolygonImporter

static func load_polygon_data(json_path: String) -> Dictionary:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Cannot open file: " + json_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Error parsing JSON: " + json.get_error_message())
		return {}
	
	return json.data

static func apply_polygon_to_sprite(sprite: Sprite2D, polygon_data: Dictionary):
	if not polygon_data.has("polygon"):
		return
	
	# Create collision polygon as sibling
	var collision_parent = sprite.get_parent()
	if collision_parent is CharacterBody2D or collision_parent is RigidBody2D:
		var collision_poly = CollisionPolygon2D.new()
		collision_poly.name = sprite.name + "_collision"
		
		# Convert polygon points
		var points = PackedVector2Array()
		for point in polygon_data["polygon"]:
			points.append(Vector2(point[0], point[1]))
		
		collision_poly.polygon = points
		collision_parent.add_child(collision_poly)
		collision_poly.owner = collision_parent.get_tree().edited_scene_root

static func create_polygon2d_from_data(polygon_data: Dictionary, texture: Texture2D) -> Polygon2D:
	var poly2d = Polygon2D.new()
	
	if polygon_data.has("polygon"):
		var points = PackedVector2Array()
		for point in polygon_data["polygon"]:
			points.append(Vector2(point[0], point[1]))
		
		poly2d.polygon = points
		poly2d.texture = texture
		
		# Set UV to match polygon for proper texture mapping
		poly2d.uv = points
	
	return poly2d

static func setup_bone_from_bounds(bone: Bone2D, bounds: Dictionary):
	if not bounds:
		return
	
	# Set bone position to sprite center
	var center = Vector2(bounds["center"][0], bounds["center"][1])
	bone.position = center
	
	# Calculate bone length from sprite size
	var length = max(bounds["width"], bounds["height"])
	bone.set_length(length)

# Example usage in a scene
func import_all_polygons():
	var data = load_polygon_data("res://sprite_polygons.json")
	
	for sprite_name in data:
		var sprite_data = data[sprite_name]
		print("Importing polygon for: ", sprite_name)
		
		# You can access the data like this:
		var polygon_points = sprite_data["polygon"]
		var bounds = sprite_data["bounds"]
		var center = Vector2(bounds["center"][0], bounds["center"][1])
		var size = Vector2(bounds["width"], bounds["height"])
		
		print("  Center: ", center)
		print("  Size: ", size)

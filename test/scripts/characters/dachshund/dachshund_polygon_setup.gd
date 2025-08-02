@tool
extends EditorScript

func _run():
	# Load the polygon data
	var importer = preload("res://scripts/tools/polygon_importer.gd")
	var polygon_data = importer.load_polygon_data("res://sprite_polygons.json")
	
	# Get the current scene
	var scene_path = "res://scenes/characters/Dachshund.tscn"
	var scene = load(scene_path) as PackedScene
	var root = scene.instantiate()
	
	# Find the skeleton
	var skeleton = root.get_node("Body/Skeleton2D")
	
	# Map sprite names to bone/sprite paths
	var sprite_mappings = {
		"body.png": "Body/Sprite2D",
		"head.png": "Head/HeadBase",
		"tail.png": "Tail/Sprite2D",
		"legs.png": "BackLegs/Sprite2D",
		"arms.png": "FrontArms/Sprite2D",
		"face.png": "Head/Face",
		"nose.png": "Head/Nose",
		"ear-front.png": "Head/FrontEar",
		"back-ear.png": "Head/BackEar"
	}
	
	# Update bone positions based on sprite bounds
	for sprite_file in sprite_mappings:
		if polygon_data.has(sprite_file):
			var data = polygon_data[sprite_file]
			var bounds = data["bounds"]
			var sprite_path = sprite_mappings[sprite_file]
			
			# Get the bone (parent of sprite)
			var sprite_node = skeleton.get_node(sprite_path)
			if sprite_node:
				var bone = sprite_node.get_parent() as Bone2D
				if bone and bounds:
					# Update bone position based on sprite center
					var center = Vector2(bounds["center"][0], bounds["center"][1])
					
					# For now, just print what we would do
					print("Bone: ", bone.name)
					print("  Current position: ", bone.position)
					print("  Sprite center: ", center)
					print("  Sprite size: ", bounds["width"], " x ", bounds["height"])
					
					# For bones, position them at a logical joint point
					# This depends on the bone type
					match bone.name:
						"Body":
							# Body stays at origin
							bone.position = Vector2.ZERO
						"Head":
							# Head connects at neck (top of body)
							bone.position = Vector2(50, -100)
						"Tail":
							# Tail connects at rear of body
							bone.position = Vector2(-100, 50)
						"BackLegs":
							# Back legs connect under rear body
							bone.position = Vector2(-50, 100)
						"FrontArms":
							# Front arms connect under front body
							bone.position = Vector2(50, 80)
					
					# With auto-calculate enabled, Godot will set the length
					# based on child bone positions automatically
					
					# Update rest pose to match
					bone.rest = Transform2D.IDENTITY
					bone.rest.origin = bone.position
	# Clean up
	root.queue_free()

	print("\nTo apply changes, uncomment the bone.position line in the script!")

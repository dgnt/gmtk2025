@tool
extends EditorScript

# Stage 3: Bone Weight Painting Assistant
# This script helps set up initial bone weights based on proximity

func _run():
	print("=== DACHSHUND BUILDER - STAGE 3: WEIGHT PAINTING ASSISTANT ===")
	print("Setting up bone weight templates...")
	
	# Load the stage 2 scene
	var scene_path = "res://scenes/characters/GeneratedDachshund_Stage2.tscn"
	if not FileAccess.file_exists(scene_path):
		print("ERROR: Stage 2 scene not found. Please run dachshund_builder_stage2.gd first.")
		return
	
	var packed_scene = load(scene_path) as PackedScene
	var root = packed_scene.instantiate()
	
	var skeleton = root.get_node("Skeleton2D")
	var polygons_container = root.get_node("Polygons")
	
	if not skeleton or not polygons_container:
		print("ERROR: Could not find Skeleton2D or Polygons node")
		root.queue_free()
		return
	
	# Define bone influence mappings for each sprite
	var weight_mappings = {
		"body": ["Hip", "Spine1", "Spine2", "Spine3"],
		"body-light": ["Hip", "Spine1", "Spine2", "Spine3", "Chest"],
		"tail": ["TailBase", "TailMid", "TailTip"],
		"legs": ["BackLegL", "BackShinL", "BackFootL", "BackLegR", "BackShinR", "BackFootR"],
		"arms": ["FrontLegL", "FrontFootL", "FrontLegR", "FrontFootR"],
		"head": ["Head", "Neck"],
		"face": ["Head"],
		"nose": ["Nose", "Head"],
		"ear-front": ["EarFront", "Head"],
		"back-ear": ["EarBack", "Head"]
	}
	
	# Process each polygon
	for polygon in polygons_container.get_children():
		if not polygon is Polygon2D:
			continue
			
		var poly_name = polygon.name
		if not weight_mappings.has(poly_name):
			print("WARNING: No weight mapping defined for " + poly_name)
			continue
		
		# Get the bones that should influence this polygon
		var influencing_bones = weight_mappings[poly_name]
		print("\nProcessing '" + poly_name + "' - Influenced by: " + str(influencing_bones))
		
		# Create initial bone weights array
		var bone_count = skeleton.get_bone_count()
		var weights_per_bone = {}
		
		# Initialize all weights to 0
		for i in range(bone_count):
			var bone = skeleton.get_bone(i)
			var bone_name = bone.name
			weights_per_bone[bone_name] = PackedFloat32Array()
			
			# Create array with weight for each vertex
			var vertex_count = polygon.polygon.size()
			for j in range(vertex_count):
				weights_per_bone[bone_name].append(0.0)
		
		# Set up basic proximity-based weights
		var vertex_count = polygon.polygon.size()
		for vertex_idx in range(vertex_count):
			var vertex_pos = polygon.to_global(polygon.polygon[vertex_idx])
			var total_weight = 0.0
			var bone_distances = {}
			
			# Calculate distance to each influencing bone
			for bone_name in influencing_bones:
				var bone = find_bone_by_name(skeleton, bone_name)
				if bone:
					var bone_pos = bone.global_position
					var distance = vertex_pos.distance_to(bone_pos)
					# Inverse distance for weight (closer = higher weight)
					bone_distances[bone_name] = 1.0 / (distance + 1.0)
					total_weight += bone_distances[bone_name]
			
			# Normalize weights
			for bone_name in bone_distances:
				if total_weight > 0:
					var normalized_weight = bone_distances[bone_name] / total_weight
					weights_per_bone[bone_name][vertex_idx] = normalized_weight
		
		# Apply weights to polygon
		var bones_array = []
		var weights_array = []
		
		for bone_name in weights_per_bone:
			if weights_per_bone[bone_name].max() > 0.0:  # Only add bones that have influence
				bones_array.append(bone_name)
				weights_array.append(weights_per_bone[bone_name])
				print("  Added bone '" + bone_name + "' with " + str(weights_per_bone[bone_name].size()) + " vertex weights")
		
		# Set the bones property
		polygon.bones = bones_array
		# Note: The actual weight painting needs to be done in the editor
		
	# Save weight painting guide
	var guide_text = "=== WEIGHT PAINTING GUIDE ===\n\n"
	guide_text += "For each polygon, select it and:\n"
	guide_text += "1. Click on the polygon in the scene\n"
	guide_text += "2. In the toolbar above the viewport, click 'UV'\n"
	guide_text += "3. In the UV editor, go to 'Bones' tab\n"
	guide_text += "4. Click 'Sync Bones to Polygon'\n"
	guide_text += "5. Select a bone from the list\n"
	guide_text += "6. Use the paint tool to paint weights:\n"
	guide_text += "   - White = Full influence (1.0)\n"
	guide_text += "   - Black = No influence (0.0)\n"
	guide_text += "   - Gray = Partial influence\n\n"
	guide_text += "Recommended weight painting:\n"
	for poly_name in weight_mappings:
		guide_text += "\n" + poly_name + ":\n"
		for bone in weight_mappings[poly_name]:
			guide_text += "  - " + bone + "\n"
	
	var guide_file = FileAccess.open("res://dachshund_weight_painting_guide.txt", FileAccess.WRITE)
	guide_file.store_string(guide_text)
	guide_file.close()
	
	# Save the scene
	var new_packed_scene = PackedScene.new()
	new_packed_scene.pack(root)
	var save_path = "res://scenes/characters/GeneratedDachshund_Stage3.tscn"
	var error = ResourceSaver.save(new_packed_scene, save_path)
	
	if error == OK:
		print("\n✓ Stage 3 Complete!")
		print("Initial bone assignments created")
		print("Scene saved to: " + save_path)
		print("Weight painting guide saved to: res://dachshund_weight_painting_guide.txt")
		print("\n=== NEXT STEPS - MANUAL WEIGHT PAINTING ===")
		print("1. Open the scene in the editor: " + save_path)
		print("2. For each Polygon2D in the Polygons node:")
		print("   a. Select the polygon")
		print("   b. Click 'UV' in the toolbar")
		print("   c. Go to 'Bones' tab")
		print("   d. Click 'Sync Bones to Polygon'")
		print("   e. Paint weights for each bone (see guide)")
		print("3. Test deformations by rotating bones")
		print("4. Save the scene when satisfied")
		print("5. Run dachshund_builder_stage4.gd for animations")
	else:
		print("ERROR: Failed to save scene")
	
	# Clean up
	root.queue_free()

func find_bone_by_name(skeleton: Skeleton2D, bone_name: String) -> Bone2D:
	for i in range(skeleton.get_bone_count()):
		var bone = skeleton.get_bone(i)
		if bone.name == bone_name:
			return bone
	return null

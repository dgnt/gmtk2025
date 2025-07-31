@tool
extends EditorScript

func _run():
	var sprite_dir = "res://assets/sprites/dachshund/"
	var sprites = [
		"body.png", "body-light.png", "head.png", "face.png", 
		"nose.png", "ear-front.png", "back-ear.png", 
		"arms.png", "legs.png", "tail.png"
	]
	
	for sprite_path in sprites:
		var full_path = sprite_dir + sprite_path
		var texture = load(full_path) as Texture2D
		if texture:
			print("\n=== Processing: ", sprite_path, " ===")
			var image = texture.get_image()
			var polygon = detect_polygon_from_alpha(image)
			print("Polygon points (", polygon.size(), "): ", polygon)
			
			var bounds = calculate_bounds(polygon)
			print("Bounds: ", bounds)
			print("Width: ", bounds.size.x, ", Height: ", bounds.size.y)
			print("Center: ", bounds.get_center())

func detect_polygon_from_alpha(image: Image, threshold: float = 0.1, simplify_epsilon: float = 2.0) -> PackedVector2Array:
	var width = image.get_width()
	var height = image.get_height()
	var points = []
	
	# Find edge pixels by checking alpha channel
	var edge_pixels = []
	for y in range(height):
		for x in range(width):
			var pixel = image.get_pixel(x, y)
			if pixel.a > threshold:
				# Check if it's an edge pixel (has transparent neighbor)
				var is_edge = false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < width and ny >= 0 and ny < height:
							var neighbor = image.get_pixel(nx, ny)
							if neighbor.a <= threshold:
								is_edge = true
								break
					if is_edge:
						break
				
				if is_edge:
					edge_pixels.append(Vector2(x, y))
	
	if edge_pixels.is_empty():
		return PackedVector2Array()
	
	# Sort edge pixels to create a continuous outline
	var sorted_points = sort_edge_pixels(edge_pixels)
	
	# Simplify the polygon using Douglas-Peucker algorithm
	var simplified = simplify_polygon(sorted_points, simplify_epsilon)
	
	return PackedVector2Array(simplified)

func sort_edge_pixels(pixels: Array) -> Array:
	if pixels.is_empty():
		return []
	
	var sorted = []
	var remaining = pixels.duplicate()
	var current = remaining.pop_front()
	sorted.append(current)
	
	# Simple nearest neighbor sorting
	while not remaining.is_empty():
		var nearest_idx = 0
		var nearest_dist = current.distance_squared_to(remaining[0])
		
		for i in range(1, remaining.size()):
			var dist = current.distance_squared_to(remaining[i])
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_idx = i
		
		current = remaining[nearest_idx]
		remaining.remove_at(nearest_idx)
		sorted.append(current)
	
	return sorted

func simplify_polygon(points: Array, epsilon: float) -> Array:
	if points.size() < 3:
		return points
	
	# Find the point with maximum distance from line between first and last
	var max_dist = 0.0
	var max_idx = 0
	var first = points[0]
	var last = points[-1]
	
	for i in range(1, points.size() - 1):
		var dist = point_to_line_distance(points[i], first, last)
		if dist > max_dist:
			max_dist = dist
			max_idx = i
	
	# If max distance is greater than epsilon, recursively simplify
	if max_dist > epsilon:
		var left = simplify_polygon(points.slice(0, max_idx + 1), epsilon)
		var right = simplify_polygon(points.slice(max_idx), epsilon)
		
		# Combine results (remove duplicate point)
		left.remove_at(left.size() - 1)
		return left + right
	else:
		return [first, last]

func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	
	if line_len == 0:
		return point_vec.length()
	
	var line_unitvec = line_vec.normalized()
	var point_vec_scaled = point_vec * (1.0 / line_len)
	
	var t = clamp(line_vec.normalized().dot(point_vec), 0.0, line_len)
	var nearest = line_start + line_unitvec * t
	
	return (point - nearest).length()

func calculate_bounds(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	
	var min_pos = polygon[0]
	var max_pos = polygon[0]
	
	for point in polygon:
		min_pos.x = min(min_pos.x, point.x)
		min_pos.y = min(min_pos.y, point.y)
		max_pos.x = max(max_pos.x, point.x)
		max_pos.y = max(max_pos.y, point.y)
	
	return Rect2(min_pos, max_pos - min_pos)

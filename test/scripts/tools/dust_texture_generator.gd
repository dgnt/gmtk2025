@tool
extends EditorScript

func _run():
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var max_radius = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			if distance <= max_radius:
				var normalized_distance = distance / max_radius
				var alpha = 1.0 - normalized_distance
				alpha = pow(alpha, 2.0)
				
				var color = Color(0.8, 0.7, 0.5, alpha)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	image.save_png("res://assets/sprites/effects/dust_particle.png")
	print("Dust particle texture saved!")
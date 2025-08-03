extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	calc_camera_bounds()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func calc_camera_bounds():
	var tilemap: TileMap
	for _i in get_parent().get_parent().get_children():
		if _i is TileMap:
			tilemap = _i
			break
	if not tilemap:
		print("Cannot set camera limits, tilemap not found.")
		return
	var map_limits = tilemap.get_used_rect()
	var map_cellsize = tilemap.tile_set.tile_size
	limit_left = 0
	limit_right = Constants.GAMESIZE.x
	limit_top = 0
	limit_bottom = Constants.GAMESIZE.y
	
	for layer in tilemap.get_children():
		if layer is not TileMapLayer:
			continue
		if layer.name != "Ground":
			continue
		map_limits = layer.get_used_rect()
		map_cellsize = layer.tile_set.tile_size
		limit_left = min(limit_left, map_limits.position.x * map_cellsize.x)
		limit_right = max(limit_right, map_limits.end.x * map_cellsize.x)
		limit_top = min(limit_top, map_limits.position.y * map_cellsize.y)
		limit_bottom = max(limit_bottom, map_limits.end.y * map_cellsize.y)
	
	if Constants.GAMESIZE.x > (limit_right - limit_left):
		limit_left -= (Constants.GAMESIZE.x - (limit_right - limit_left))/2 + 1
		limit_right += (Constants.GAMESIZE.x - (limit_right - limit_left))/2 + 1
	if Constants.GAMESIZE.y > (limit_bottom - limit_top):
		limit_top -= (Constants.GAMESIZE.y - (limit_bottom - limit_top))/2 + 1
		limit_bottom += (Constants.GAMESIZE.y - (limit_bottom - limit_top))/2 + 1
	
	#print(limit_left)
	#print(limit_right)
	#print(limit_top)
	#print(limit_bottom)

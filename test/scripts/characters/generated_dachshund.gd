extends CharacterBody2D
signal level_failed

# B0 Ground: Hypercharge
# B0 Air: Ground-poundish
# B1 Ground: Jump
# B1 Air: Helicopter
# B2: Drop/Use Hooportal
# B3 Ground: Snap Attack
# B3 Air: Rubber Snap

@export var speed = 300.0
@export var jump_velocity = -600.0

@onready var skeleton = $Body/Skeleton2D
@onready var facing_forward = true
var hula_hoop: HulaHoop = null

const REV_TIME = 800
const HOOP_SPEED = 300
const STABILITY = 250
var rev = 200
var lookup = false
var forward = true
var hypercharge = 0
var hyperdirection = Vector2(0, -1)
var air_momentum = Vector2.ZERO
const MAX_FALL = 500
const CHARGE_TIME = 2000.0 # ms
const FULL_CHARGE = 2.0
const HELI_MAX = 1.5 # s
var heli_charges = 0
var heli_time = 0
const HELI_SPEED = 150
var air_snaps = 0
@onready var snap_target = position
var snap_direction = Vector2(0, -1)
const SNAP_TIME = .4
const SNAP_DISTANCE = 100
var snapping_time = 0
var locked_skills = []
const SKILLS = ["jump", "move_left", "move_right", "move_up", "move_down", "B0", "B1", "B2", "B3"]
var jump_processed = true
var charge_processed = true
var heli_processed = true
var helicoptering = false
const HELI_TRANSPOSE = Vector2(0, -360)
const HELI_REV_TIME = 0.15 # s
const HEIGHT = 256 #px
const WIDTH = 64 #px
const WAIST = 40
const SHOULDER = 190
const HEAD = 206
const TOP_HEAD = 251
const THICK_BODY = 35
const THICK_HEAD = 45

const HEAD_NAME = "Head"
const TORSO_NAME = "Torso"
const BELLY_NAME = "Belly"
const BODY_NAME = "Body"
var start_pos = Vector2(100,100)

		
func _physics_process(delta: float) -> void:
	var bod = get_node("Body")
	var pressed = []
	for action in SKILLS:
		if action not in locked_skills and Input.is_action_pressed(action):
			pressed.append(action)
	var direction := Input.get_axis("move_left", "move_right")
	control(delta)
	
	for i in range(get_slide_collision_count()):
		var collider = get_slide_collision(i).get_collider()
		if collider.name == "Spikes":
			die()
	return

func control(delta):
	var pressed = []
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	for action in SKILLS:
		if action not in locked_skills and Input.is_action_pressed(action):
			pressed.append(action)
	if "B1" not in pressed:
		jump_processed = true
	if "B0" not in pressed:
		charge_processed = true
	if is_on_floor():
		ground_control(delta, pressed, direction)
	else:
		air_control(delta, pressed, direction)
	move_and_slide()

func ground_control(delta, pressed, direction):
	air_momentum = Vector2.ZERO
	refresh_airskills()
	direct_player(direction, pressed)
	hoop_directing(direction)
	if hypercharging(delta, direction, "B0" in pressed):
		update_hoop()
		return
	walk(direction)
	if "B1" in pressed:
		jump(direction)
		return
	hoop_revving(delta)
	update_hoop()

func air_control(delta, pressed, direction):
	if "B3" in pressed: rubber_snap(direction)
	if snap_to(delta): return
	if "B1" in pressed and jump_processed: helicopter(direction)
	if helicopter_fall(delta, pressed, direction): return
	if hyper_airtime(delta): return
	air_momentum += get_gravity() * delta
	velocity = air_momentum
	if direction.x != 0:
		velocity.x += (1 if direction.x > 0 else -1) * speed

func update_hoop():
	if hula_hoop:
		hula_hoop.current_phase = rev * TAU

func hoop_directing(direction):
	if hula_hoop:
		var angle = 0.0
		if direction:
			angle = direction.angle()
		else:
			angle = (Vector2(1 if forward else -1,0)).angle()
		if angle > PI/2:
			angle -= PI
		elif angle < -PI/2:
			angle += PI
		hula_hoop.set_tilt_angle(angle)

func walk(direction):
	if direction.x:
		velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func direct_player(direction, pressed):
	if direction.x > 0:
		turn()
	elif direction.x < 0:
		turn(false)

func hoop_revving(delta):
	var speed_mult = hula_hoop.get_speed_multiplier() if hula_hoop else 1.0
	rev += delta * 1000.0 / REV_TIME * speed_mult
	rev -= int(rev)

func jump(direction):
	velocity.y = jump_velocity
	if Input.is_action_pressed("move_up"):
		velocity.y += cos(rev * 2 * PI) * HOOP_SPEED * $Body.transform.x.x
	air_momentum = velocity
	jump_processed = false

func turn(forward=true):
	self.forward = forward
	$Body.transform.x.x = 1 if forward else -1

func hypercharging(delta, direction, charging) -> bool:
	velocity.x = 0
	if charging:
		charge_processed = false
		hypercharge += delta * 1000.0
		var old_rev = rev
		var speed_mult = hula_hoop.get_speed_multiplier() if hula_hoop else 1.0
		rev += delta * 1000.0 / REV_TIME * (1+hypercharge/CHARGE_TIME*FULL_CHARGE) * speed_mult
		rev -= int(rev)
		if hypercharge >= CHARGE_TIME:
			if ($Body.transform.x.x > 0 and old_rev < 0.5 and rev > 0.5):
				rev = 0.5
				hyperdirection = direction
				velocity = hyperdirection * (1+FULL_CHARGE) * HOOP_SPEED
			elif ($Body.transform.x.x < 0 and rev < old_rev):
				rev = 0
				hyperdirection = direction
				velocity = hyperdirection * (1+FULL_CHARGE) * HOOP_SPEED
		return true
	else:
		hypercharge -= delta * 1000.0
		if hypercharge <= 0:
			hypercharge = 0
			return false
		var speed_mult = hula_hoop.get_speed_multiplier() if hula_hoop else 1.0
		rev += delta * 1000.0 / REV_TIME * (1+hypercharge/CHARGE_TIME*FULL_CHARGE) * speed_mult
		rev -= int(rev)
		return true
	return true

func refresh_airskills():
	air_snaps = 1
	heli_charges = 1

func rubber_snap(direction):
	if air_snaps <= 0: return
	air_snaps -= 1
	snapping_time = SNAP_TIME
	snap_target = position + direction * SNAP_DISTANCE
	snap_direction = direction
	hoop_directing(direction)
	if direction.x >= 0:
		rev = 0.5
	else:
		rev = 0
	air_momentum = Vector2.ZERO
	velocity = air_momentum
	clear_fall_type("airsnap")
	update_hoop()

func snap_to(delta) -> bool:
	if snap_target == null or snapping_time <= 0:
		return false
	snapping_time -= delta
	if snapping_time > 0.5 * SNAP_TIME:
		return true
	if snapping_time < 0:
		snapping_time = 0
		air_momentum = snap_direction * SNAP_DISTANCE / SNAP_TIME * 2
		position = snap_target
		return false
	var rdelta = min(delta, SNAP_TIME*0.5 - snapping_time)
	position += snap_direction * SNAP_DISTANCE / (SNAP_TIME / 2) * rdelta
	velocity = Vector2.ZERO
	return true

func hyper_airtime(delta) -> bool:
	if hypercharge > 0:
		air_momentum += get_gravity() * delta * (1 - hypercharge/CHARGE_TIME)
		velocity = air_momentum + hyperdirection * (1+hypercharge/CHARGE_TIME*FULL_CHARGE) * HOOP_SPEED
		hypercharge -= delta * 1000
		if hypercharge <= 0:
			hypercharge = 0
			return false
		return true
	return false

func start_heli():
	if helicoptering: return
	helicoptering = true
	if hula_hoop:
		hula_hoop.set_tilt_angle(0)
		hula_hoop.position = HELI_TRANSPOSE

func heli_rev(delta):
	if hula_hoop:
		hula_hoop.current_phase += delta * TAU / HELI_REV_TIME

func end_heli():
	if not helicoptering: return
	helicoptering = false
	if hula_hoop:
		hula_hoop.position = Vector2.ZERO

func helicopter(direction):
	if heli_charges <= 0: return
	start_heli()
	heli_charges -= 1
	heli_time = HELI_MAX
	air_momentum = Vector2.ZERO
	clear_fall_type("helicopter")
	heli_processed = false

func helicopter_fall(delta, pressed, direction) -> bool:
	if heli_time <= 0:
		end_heli()
		heli_processed = true
		return false
	if "B1" in pressed and heli_processed:
		end_heli()
		heli_time = 0
		return false
	if "B1" not in pressed:
		heli_processed = true
	heli_time -= delta
	air_momentum = Vector2.ZERO
	velocity = Vector2(direction.x * HELI_SPEED, 0)
	heli_rev(delta)
	return true

func clear_fall_type(except):
	if except != "helicopter" and heli_time < HELI_MAX:
		heli_time = 0
	if except != "airsnap" and snapping_time < SNAP_TIME:
		snapping_time = 0
		snap_target = null
	if except != "hypercharge":
		hypercharge = 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	start_pos = position
	# make_torso()
	# make_head()
	print("Hitbox size is ", get_hitbox_dimensions())
	
	# Create a hula hoop using the factory
	hula_hoop = HulaHoopFactory.create_hoop(skeleton, {
		"path_width": 18.0,
		"path_height": 1.8, 
		"hoop_width": 900.0, 
		"hoop_height": 90.0, 
		"speed_multiplier": 1.0,
		"tilt_angle": 0.0,
		"color_front": Color.MAGENTA,
		"color_back": Color.PURPLE
	})
	add_child(hula_hoop)
	
	#hula_hoop2 = HulaHoopFactory.create_hoop($Body/Skeleton2D/CenterBone/LowerSpine, {
		#"path_width": 18.0,
		#"path_height": 1.8, 
		#"hoop_width": 900.0, 
		#"hoop_height": 90.0, 
		#"speed_multiplier": 1.0,
		#"tilt_angle": 0.0,
		#"color_front": Color.RED,
		#"color_back": Color.DARK_RED
	#})
	#add_child(hula_hoop2)
	pass # Replace with function body.


func sane_coord(point: Vector2) -> Vector2:
	return Vector2(point.x, HEIGHT - point.y)

func sanify_pack(v2a: PackedVector2Array) -> void:
	for v2 in v2a:
		v2.y = HEIGHT - v2.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func die() -> void:
	level_failed.emit()
	set_deferred("monitoring", false) # Disable monitoring after first trigger
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED) # Disable script processing

func _on_body_entered(body: Node2D):
	print("Collision!")
	if body.get_collision_layer_bit(2):
		position = start_pos
	pass
	
func get_hitbox_dimensions():
	var top = $CollisionPolygon2D.polygon[0].y
	var bot = $CollisionPolygon2D.polygon[0].y
	var left = $CollisionPolygon2D.polygon[0].x
	var right = $CollisionPolygon2D.polygon[0].x
	for point in $CollisionPolygon2D.polygon:
		top = min(top, point.y)
		bot = max(bot, point.y)
		left = min(left, point.x)
		right = max(right, point.x)
	return Vector2($CollisionPolygon2D.scale.x*(bot-top), $CollisionPolygon2D.scale.y*(right-left))
	
func make_head() -> void:
	var top = HEIGHT/2 - TOP_HEAD
	var bot = HEIGHT/2 - HEAD
	var left = -THICK_HEAD/2
	var right = THICK_HEAD/2
	
	var head = Polygon2D.new()
	head.name = HEAD_NAME
	head.color = Color("#632b16")
	head.polygon = PackedVector2Array([
		Vector2(left,top),
		Vector2(left,bot),
		Vector2(right,bot),
		Vector2(right,top)
	])
	get_node("Body").add_child(head)

func make_torso() -> void:
	var top = HEIGHT/2 - SHOULDER
	var bot = HEIGHT/2 - WAIST
	var left = -THICK_BODY/2
	var right = THICK_BODY/2
	
	var torso = Polygon2D.new()
	torso.name = TORSO_NAME
	torso.color = Color("#632b16")
	torso.polygon = PackedVector2Array([
		Vector2(left,top),
		Vector2(left,bot),
		Vector2(right,bot),
		Vector2(right,top)
	])
	#sanify_pack(torso.polygon)
	torso.clip_children = Node2D.CLIP_CHILDREN_AND_DRAW
	get_node("Body").add_child(torso)
	
	var belly = Polygon2D.new()
	belly.name = BELLY_NAME
	belly.color = Color("#6e4f3d")
	belly.polygon = PackedVector2Array([
		Vector2((left + right) * 0.6, (top + bot) * 0.3),
		Vector2(right + 10, (top+bot) * 0.2),
		Vector2(right + 10, bot + 10),
		Vector2((left+right) * 0.5, bot - 10)
	])
	torso.add_child(belly)
	
	#self.get_node(TORSO_NAME).clip_children = Node2D.CLIP_CHILDREN_AND_DRAW


func make_belly() -> void:
	var top = -1000
	var left = -1000
	var right = 1000
	var bot = 1000
	var torso_points = PackedVector2Array([
		Vector2(left, bot), Vector2(right, bot), Vector2(right, top), Vector2(left, top)
	])
	var shape_color = Color("#6e4f3d")
	var torso = self.get_node(TORSO_NAME)

func create_polygon_node(node_name: String, points: PackedVector2Array, shape_color: Color) -> Polygon2D:
	# 1. Create a new Polygon2D instance in memory.
	var new_polygon = Polygon2D.new()
	
	# 2. Set its properties.
	new_polygon.name = node_name
	new_polygon.polygon = points
	new_polygon.color = shape_color
	
	# 3. Add it as a child to the specified parent node.
	#    This makes it part of the active scene tree.
	#parent_node.add_child(new_polygon)
	
	# 4. Return the new node instance in case you need a direct reference to it.
	return new_polygon

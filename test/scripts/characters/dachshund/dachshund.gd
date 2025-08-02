extends CharacterBody2D

signal level_failed

# HulaHoopFactory and HulaHoop are global classes, no need to preload

# Physics and control values
@export var speed = 300.0
@export var jump_velocity = -900.0
const REV_TIME = 800  # ms
const HOOP_SPEED = 300
const STABILITY = 250
var rev = .25 #[0,1)
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
var helicopter_sound_id: int = -1
const HELI_TRANSPOSE = Vector2(0, -360)
const HELI_REV_TIME = 0.15 # s

# Hoop instance
var hoop_instance: HulaHoop = null
var hoop_instance2: HulaHoop = null
const DEFAULT_HOOP_TARGET = "CenterBone/LowerSpine"
const HELICOPTER_HOOP_TARGET = "CenterBone/LowerChest/Chest/Neck/Head"

# B0 Ground: Hypercharge
# B0 Air: Ground-poundish
# B1 Ground: Jump
# B1 Air: Helicopter
# B2: Drop/Use Hooportal
# B3 Ground: Snap Attack
# B3 Air: Rubber Snap

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
	#print(position)
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
	update_hoop()
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

func air_control(delta, pressed, direction):
	if "B3" in pressed: rubber_snap(direction)
	#print("snapto")
	if snap_to(delta): return
	if "B1" in pressed and jump_processed: helicopter(direction)
	#print("helifall")
	if helicopter_fall(delta, pressed, direction): return
	#print("hyper")
	if hyper_airtime(delta): return
	#print("OMG")
	air_momentum += get_gravity() * delta
	velocity = air_momentum
	velocity.x += direction.x * speed

func update_hoop():
	if hoop_instance:
		hoop_instance.current_phase = rev * TAU

func hoop_directing(direction):
	if hoop_instance and hoop_instance:
		if direction:
			hoop_instance.rotation = direction.angle()
		else:
			hoop_instance.rotation = (Vector2(1 if forward else -1,0)).angle()
		if hoop_instance.rotation > PI/2:
			hoop_instance.rotation -= PI
		elif hoop_instance.rotation < -PI/2:
			hoop_instance.rotation += PI
	
func rubber_snap(direction):
	if air_snaps <= 0: return
	air_snaps -= 1
	snapping_time = SNAP_TIME
	snap_target = position + direction * SNAP_DISTANCE
	snap_direction = direction
	hoop_directing(direction)
	if direction.x < 0:
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
	if snap_direction.x < 0:
		rev = 0.5
	else:
		rev = 0
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
	
func hyper_airtime(delta) -> bool: # retval is skip rest of controls
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
	# Play helicopter sound with pitch variation
	helicopter_sound_id = AudioManager.play_helicopter_sound()
	if hoop_instance:
		# Change target bone to head for helicopter effect
		hoop_instance.set_target_bone(HELICOPTER_HOOP_TARGET)
		# Reset visual rotation and position - hoop will follow head automatically
		if hoop_instance:
			hoop_instance.rotation = 0
		hoop_instance.position = Vector2.ZERO

func heli_rev(delta):
	if hoop_instance:
		rev += delta / HELI_REV_TIME
		rev = fmod(rev, 1.0)
		hoop_instance.current_phase = rev * TAU

func end_heli():
	if not helicoptering: return
	helicoptering = false
	rev = 0.75
	# Stop helicopter sound
	if helicopter_sound_id != -1:
		AudioManager.stop_helicopter_sound(helicopter_sound_id)
		helicopter_sound_id = -1
	if hoop_instance:
		# Restore target bone back to lower spine
		hoop_instance.set_target_bone(DEFAULT_HOOP_TARGET)
		hoop_instance.position = Vector2.ZERO

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
	#TODO: Play Helicopter animations

func clear_fall_type(except):
	if except != "helicopter" and heli_time < HELI_MAX:
		heli_time = 0
		# Stop helicopter sound if clearing helicopter mode
		if helicoptering:
			end_heli()
	if except != "airsnap" and snapping_time < SNAP_TIME:
		snapping_time = 0
		snap_target = null
	if except != "hypercharge":
		hypercharge = 0

func refresh_airskills():
	air_snaps = 1
	heli_charges = 1
	
func hypercharging(delta, direction, charging) -> bool: # retval is pass rest of control
	velocity.x = 0
	if charging:
		charge_processed = false
		hypercharge += delta * 1000.0
		var old_rev = rev
		rev += delta * 1000.0 / REV_TIME * (1+hypercharge/CHARGE_TIME*FULL_CHARGE)
		rev -= int(rev)
		if hypercharge >= CHARGE_TIME:
			if ($Body.transform.x.x > 0 and rev < old_rev):
				rev = 0
				hyperdirection = direction
				velocity = hyperdirection * (1+FULL_CHARGE) * HOOP_SPEED
			elif ($Body.transform.x.x < 0 and old_rev < 0.5 and rev > 0.5):
				rev = 0.5
				hyperdirection = direction
				velocity = hyperdirection * (1+FULL_CHARGE) * HOOP_SPEED
				# TODO: Punish hypercharging into the ground
			else:
				hypercharge = CHARGE_TIME
		return true
	else:
		hypercharge -= delta * 1000.0
		if hypercharge <= 0:
			hypercharge = 0
			return false
		rev += delta * 1000.0 / REV_TIME * (1+hypercharge/CHARGE_TIME*FULL_CHARGE)
		rev -= int(rev)
		return true
	return true

func walk(direction):
	if true:
		walk_jerked(direction)
		return
	if direction.x:
		velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func walk_jerked(direction):
	if direction.x:
		velocity.x = direction.x * speed + abs(direction.x) * max(speed * 0.9, HOOP_SPEED) * cos(rev * TAU)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	
func direct_player(direction, pressed):
	if direction.x > 0:
		turn()
	elif direction.x < 0:
		turn(false)
	
func hoop_revving(delta):
	rev += delta * 1000.0 / REV_TIME
	rev -= int(rev)

func jump(direction):
	velocity.y = jump_velocity
	if Input.is_action_pressed("move_up"):
		velocity.y -= cos(rev * 2 * PI) * HOOP_SPEED * $Body.transform.x.x
	air_momentum = velocity
	air_momentum = get_hoop_force_vector() + Vector2(0, jump_velocity)
	velocity = air_momentum
	jump_processed = false
	# Play jump sound
	AudioManager.play_jump_sound()
	# Play jump animation
	if $AnimationPlayer.has_animation("jump"):
		$AnimationPlayer.play("jump")

func charge_process(delta, pressed):
	if "B0" in pressed:
		hypercharge += delta * 1000
		if hypercharge > CHARGE_TIME:
			hypercharge = CHARGE_TIME
	else:
		hypercharge = 0
		
func turn(forward=true):
	self.forward = forward
	$Body.transform.x.x = 1 if forward else -1

func get_hoop_force_vector():
	return HOOP_SPEED * get_hoop_force() * get_hoop_direction()
	
func get_hoop_force():
	# returns a force from -1 to 1
	return cos(rev * 2 * PI)

func get_hoop_direction():
	return Vector2(1,0).rotated(hoop_instance.rotation)

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
@onready var facing_forward = true
var start_pos = Vector2(100,100)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#locked_skills = get_parent().get_locked_skills()
	start_pos = position
	# make_torso()
	# make_head()
	print("Hitbox size is ", get_hitbox_dimensions())
	
	# Create hoop using factory
	var skeleton = $Body/Skeleton2D
	if skeleton:
		hoop_instance = HulaHoopFactory.create_basic_hoop(skeleton)
		# Customize the hoop for dachshund
		hoop_instance.set_colors(Color(1, 0.109804, 0.0588235, 1), Color(0.556863, 0.121569, 0.141176, 1))
		hoop_instance.set_target_bone(DEFAULT_HOOP_TARGET)
		add_child(hoop_instance)
		
		#hoop_instance2 = HulaHoopFactory.create_basic_hoop(skeleton)
		## Customize the hoop for dachshund
		#hoop_instance.set_colors(Color(1, 0.109804, 0.0588235, 1), Color(0.556863, 0.121569, 0.141176, 1))
		#hoop_instance.set_target_bone("Body/Skeleton2D/CenterBone/LowerChest")
		#add_child(hoop_instance2)

func sane_coord(point: Vector2) -> Vector2:
	return Vector2(point.x, HEIGHT - point.y)

func sanify_pack(v2a: PackedVector2Array) -> void:
	for v2 in v2a:
		v2.y = HEIGHT - v2.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func die() -> void:
	# Stop helicopter sound if playing
	if helicopter_sound_id != -1:
		AudioManager.stop_helicopter_sound(helicopter_sound_id)
		helicopter_sound_id = -1
	level_failed.emit()
	set_deferred("monitoring", false) # Disable monitoring after first trigger
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED) # Disable script processing
	
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

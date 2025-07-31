extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = -600.0
const REV_TIME = 800  # ms
const HOOP_SPEED = 300
const STABILITY = 250
var rev = 0
var lookup = false

func _physics_process(delta: float) -> void:
	var bod = get_node("Body")
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		rev += delta * 1000 / REV_TIME
		rev -= int(rev)
		lookup = Input.is_action_pressed("ui_up")
		$Path2D.rotation = 0 if not lookup else bod.transform.x.x * -45
	
	var hooper = get_node("Path2D/PathFollow2D")
	hooper.progress_ratio = rev
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		if lookup:
			velocity.y += cos(rev * 2 * PI) * HOOP_SPEED * bod.transform.x.x

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	var hoop_h = 0
	if not lookup:
		hoop_h = -cos(rev*2*PI) * HOOP_SPEED
		if is_on_floor():
			if abs(hoop_h) < STABILITY:
				hoop_h = 0
			elif hoop_h > 0:
				hoop_h -= STABILITY
			else:
				hoop_h += STABILITY
	if direction:
		velocity.x = direction * speed + hoop_h
	else:
		velocity.x = move_toward(velocity.x, hoop_h, speed)
	
	if velocity.x < 0:
		bod.transform.x = Vector2(-1, 0)
	elif velocity.x > 0:
		bod.transform.x = Vector2(1, 0)
	move_and_slide()


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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	make_torso()
	make_head()
	pass # Replace with function body.

func sane_coord(point: Vector2) -> Vector2:
	return Vector2(point.x, HEIGHT - point.y)

func sanify_pack(v2a: PackedVector2Array) -> void:
	for v2 in v2a:
		v2.y = HEIGHT - v2.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
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

extends Resource
class_name HulaHoopResource

@export var position: Vector2 = Vector2(0.0, 0.0) # offset from the targetBone
@export var radius: float = 50.0   # Base radius in pixels
@export var speed: float = 2.0     # Radians per second
@export var phase: float = 0.0     # Current rotation angle
@export var influence_range: float = 0.3  # How far up/down the spine it affects
@export var ellipse_ratio: float = 0.6  # Width/height ratio for perspective

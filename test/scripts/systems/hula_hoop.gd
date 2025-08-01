extends Resource
class_name HulaHoop

@export var position: float = 0.5  # 0.0 = bottom of torso, 1.0 = top
@export var radius: float = 50.0   # Base radius in pixels
@export var speed: float = 2.0     # Radians per second
@export var phase: float = 0.0     # Current rotation angle
@export var influence_range: float = 0.3  # How far up/down the spine it affects
@export var intensity: float = 1.0  # Multiplier for the effect
@export var ellipse_ratio: float = 0.6  # Width/height ratio for perspective
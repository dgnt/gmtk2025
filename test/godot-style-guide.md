# GDScript Style Guide

This style guide outlines the standard naming conventions and best practices for writing GDScript code in Godot Engine.

## Table of Contents
- [Naming Conventions](#naming-conventions)
  - [Files](#files)
  - [Classes](#classes)
  - [Variables](#variables)
  - [Constants](#constants)
  - [Functions](#functions)
  - [Signals](#signals)
  - [Enums](#enums)
  - [Nodes and Scenes](#nodes-and-scenes)
- [Code Organization](#code-organization)
- [Best Practices](#best-practices)

## Naming Conventions

### Files

- **Script files**: Use `snake_case` with `.gd` extension
  ```
  player_controller.gd
  health_system.gd
  inventory_manager.gd
  ```

- **Scene files**: Use `PascalCase` with `.tscn` extension
  ```
  Player.tscn
  MainMenu.tscn
  GameWorld.tscn
  ```

### Classes

- **Class names**: Use `PascalCase`
  ```gdscript
  class_name PlayerController
  class_name HealthSystem
  class_name InventoryManager
  ```

### Variables

- **Regular variables**: Use `snake_case`
  ```gdscript
  var player_health = 100
  var movement_speed = 5.0
  var current_weapon = null
  ```

- **Private variables**: Prefix with underscore
  ```gdscript
  var _internal_timer = 0.0
  var _cached_result = null
  ```

- **Boolean variables**: Prefix with `is_`, `has_`, or `can_`
  ```gdscript
  var is_jumping = false
  var has_key = false
  var can_shoot = true
  ```

### Constants

- **Constants**: Use `SCREAMING_SNAKE_CASE`
  ```gdscript
  const MAX_HEALTH = 100
  const GRAVITY_FORCE = 9.8
  const DEFAULT_PLAYER_NAME = "Player"
  ```

### Functions

- **Regular functions**: Use `snake_case`
  ```gdscript
  func calculate_damage(base_damage: float) -> float:
      return base_damage * damage_multiplier
  
  func update_player_position(delta: float) -> void:
      # Function implementation
  ```

- **Private functions**: Prefix with underscore
  ```gdscript
  func _process_input() -> void:
      # Internal function
  
  func _validate_data() -> bool:
      # Private validation logic
  ```

- **Virtual methods**: Always use underscore prefix (Godot convention)
  ```gdscript
  func _ready() -> void:
      # Called when node enters the scene tree
  
  func _process(delta: float) -> void:
      # Called every frame
  
  func _physics_process(delta: float) -> void:
      # Called every physics frame
  ```

### Signals

- **Signal names**: Use `snake_case`, often past tense for events
  ```gdscript
  signal health_changed(new_health)
  signal item_collected(item_name)
  signal player_died
  signal level_completed
  ```

### Enums

- **Enum names**: Use `PascalCase`
- **Enum values**: Use `SCREAMING_SNAKE_CASE`
  ```gdscript
  enum PlayerState {
      IDLE,
      WALKING,
      RUNNING,
      JUMPING,
      FALLING
  }
  
  enum WeaponType {
      SWORD,
      BOW,
      MAGIC_STAFF,
      SHIELD
  }
  ```

### Nodes and Scenes

- **Node names in scene tree**: Use `PascalCase`
  ```
  Player
  ├── Sprite2D
  ├── CollisionShape2D
  ├── AnimationPlayer
  └── HealthBar
  ```

## Code Organization

### Script Structure

Organize your scripts in this order:

```gdscript
class_name MyClass
extends Node

# Signals
signal something_happened

# Enums
enum State { IDLE, ACTIVE }

# Constants
const MAX_VALUE = 100

# Export variables
@export var public_value: int = 10

# Public variables
var health: int = 100

# Private variables
var _internal_state: State = State.IDLE

# Onready variables
@onready var sprite: Sprite2D = $Sprite2D

# Virtual methods
func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

# Public methods
func take_damage(amount: int) -> void:
    health -= amount

# Private methods
func _update_internal_state() -> void:
    pass
```

## Best Practices

### Type Hints

Always use type hints for better code clarity and error prevention:

```gdscript
func calculate_distance(from: Vector2, to: Vector2) -> float:
    return from.distance_to(to)

var player_name: String = "Hero"
var player_level: int = 1
var experience_points: float = 0.0
```

### Export Variables

Use `@export` for variables that should be editable in the Inspector:

```gdscript
@export var movement_speed: float = 300.0
@export var jump_height: float = 600.0
@export_range(0, 100) var health: int = 100
```

### Node References

Cache node references using `@onready`:

```gdscript
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
```

### Groups

Use descriptive group names in `snake_case`:

```gdscript
add_to_group("enemies")
add_to_group("collectible_items")
get_tree().call_group("enemies", "take_damage", 10)
```

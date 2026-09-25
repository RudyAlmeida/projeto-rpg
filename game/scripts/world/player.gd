class_name Player
extends CharacterBody2D
## Field-map player (Phase 1 prototype). Uses the official reference sheet as placeholder
## frames: 0 = down, 1 = left, 2 = up (right = left mirrored). Walking is shown with a
## small bob until real walk cycles exist.

enum Facing { DOWN, LEFT, UP, RIGHT }

const FRAME_SIZE := 64
const BOB_HEIGHT := 2.0
const BOB_SPEED := 14.0

@export var walk_speed := 80.0
@export var run_multiplier := 1.75

var facing := Facing.DOWN

var _bob_time := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _camera: Camera2D = $Camera


func _ready() -> void:
	_update_frame()


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var speed := walk_speed * (run_multiplier if Input.is_action_pressed(&"run") else 1.0)
	velocity = direction * speed
	move_and_slide()

	if direction != Vector2.ZERO:
		facing = facing_for(direction)
		_bob_time += delta * BOB_SPEED * (speed / walk_speed)
	else:
		_bob_time = 0.0
	_update_frame()


## Dominant axis wins; horizontal wins exact diagonals so side sprites show while strafing.
static func facing_for(direction: Vector2) -> Facing:
	if absf(direction.x) >= absf(direction.y):
		return Facing.RIGHT if direction.x > 0 else Facing.LEFT
	return Facing.DOWN if direction.y > 0 else Facing.UP


func set_camera_limits(rect: Rect2i) -> void:
	_camera.limit_left = rect.position.x
	_camera.limit_top = rect.position.y
	_camera.limit_right = rect.end.x
	_camera.limit_bottom = rect.end.y


func _update_frame() -> void:
	var column := {Facing.DOWN: 0, Facing.LEFT: 1, Facing.UP: 2, Facing.RIGHT: 1}[facing] as int
	_sprite.region_rect = Rect2(column * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
	_sprite.flip_h = facing == Facing.RIGHT
	# Whole pixels only, so the bob stays crisp at integer scale.
	_sprite.offset.y = -FRAME_SIZE / 2.0 - roundf(absf(sin(_bob_time)) * BOB_HEIGHT)

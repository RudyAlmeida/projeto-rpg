class_name Player
extends CharacterBody2D
## Field-map player (Phase 1 prototype).
## Idle frames come from the reference sheet (0 = down, 1 = left, 2 = up); walking uses
## `walk_sheet` (rows down / left / up, WALK_FRAMES columns). Right = left mirrored.
## Without a walk sheet the sprite just bobs.

enum Facing { DOWN, LEFT, UP, RIGHT }

const FRAME_SIZE := 64
const WALK_FRAMES := 4
const WALK_FPS := 8.0
const BOB_HEIGHT := 2.0
const INTERACT_REACH := 20.0

@export var walk_speed := 80.0
@export var run_multiplier := 1.75
@export var idle_sheet: Texture2D
@export var walk_sheet: Texture2D

var facing := Facing.DOWN
## Set by gameplay systems (battles, cutscenes) to freeze the player.
var locked := false

var _anim_time := 0.0
var _moving := false
var _scripted := false  # a cutscene is moving the player

@onready var _sprite: Sprite2D = $Sprite
@onready var _camera: Camera2D = $Camera
@onready var _interact_ray: RayCast2D = $InteractRay


func _ready() -> void:
	_interact_ray.add_exception(self)
	_update_frame()


func _physics_process(delta: float) -> void:
	if _scripted:
		_anim_time += delta
		_update_frame()
		return
	var direction := Vector2.ZERO
	if can_move():
		direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var speed := walk_speed * (run_multiplier if Input.is_action_pressed(&"run") else 1.0)
	velocity = direction * speed
	move_and_slide()

	_moving = direction != Vector2.ZERO
	if _moving:
		facing = facing_for(direction)
		_anim_time += delta * (speed / walk_speed)
	else:
		_anim_time = 0.0
	_interact_ray.target_position = facing_vector(facing) * INTERACT_REACH
	_update_frame()


## False while a conversation, a scene transition or a battle is running.
func can_move() -> bool:
	return not locked and not DialogueManager.is_active and not SceneManager.is_transitioning


## Where the camera is looking, after skipping any smoothing still in progress.
func camera_center() -> Vector2:
	_camera.reset_smoothing()
	_camera.force_update_scroll()
	return _camera.get_screen_center_position()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"confirm") and can_move() and not DialogueManager.just_closed():
		if try_interact():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu") and can_move():
		get_viewport().set_input_as_handled()
		MainMenu.open(get_tree())


## Talks to / uses whatever is right in front of the player. Returns true if something reacted.
func try_interact() -> bool:
	_interact_ray.force_raycast_update()
	var target := _interact_ray.get_collider()
	if target and target.has_method(&"interact"):
		target.interact(self)
		return true
	return false


static func facing_vector(dir: Facing) -> Vector2:
	match dir:
		Facing.LEFT:
			return Vector2.LEFT
		Facing.UP:
			return Vector2.UP
		Facing.RIGHT:
			return Vector2.RIGHT
	return Vector2.DOWN


## Cutscenes: walk to `target` with the walk animation.
func walk_to(target: Vector2, speed := 60.0) -> void:
	var delta := target - position
	if delta.length() < 1.0:
		return
	facing = facing_for(delta)
	_scripted = true
	_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", target, delta.length() / speed)
	await tween.finished
	_moving = false
	_scripted = false
	_update_frame()


func face(dir: Facing) -> void:
	facing = dir
	_update_frame()


## Dominant axis wins; horizontal wins exact diagonals so side sprites show while strafing.
static func facing_for(direction: Vector2) -> Facing:
	if absf(direction.x) >= absf(direction.y):
		return Facing.RIGHT if direction.x > 0 else Facing.LEFT
	return Facing.DOWN if direction.y > 0 else Facing.UP


## Current walk frame (0..WALK_FRAMES-1) for the elapsed animation time.
static func walk_frame_at(time: float) -> int:
	return floori(time * WALK_FPS) % WALK_FRAMES


func set_camera_limits(rect: Rect2i) -> void:
	_camera.limit_left = rect.position.x
	_camera.limit_top = rect.position.y
	_camera.limit_right = rect.end.x
	_camera.limit_bottom = rect.end.y
	# Jump straight to the player (e.g. after a spawn) instead of smoothing across the map.
	_camera.reset_smoothing()


func _update_frame() -> void:
	var direction_index := {Facing.DOWN: 0, Facing.LEFT: 1, Facing.UP: 2, Facing.RIGHT: 1}[facing] as int
	_sprite.flip_h = facing == Facing.RIGHT
	var bob := 0.0
	if _moving and walk_sheet:
		_sprite.texture = walk_sheet
		_sprite.region_rect = Rect2(walk_frame_at(_anim_time) * FRAME_SIZE, direction_index * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
	else:
		_sprite.texture = idle_sheet
		_sprite.region_rect = Rect2(direction_index * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		if _moving:
			bob = roundf(absf(sin(_anim_time * 14.0)) * BOB_HEIGHT)  # fallback: whole pixels only
	_sprite.offset.y = -FRAME_SIZE / 2.0 - bob

class_name BattlerView
extends Node2D
## On-screen body of a BattleUnit: idle / attack / hurt frames, lunge-and-return attacks
## (Chrono Trigger style), hurt flash and knock-out fade.

const LUNGE_TIME := 0.3
const RETURN_TIME := 0.2
const STOP_SHORT := 26.0  # stop this far from the target instead of overlapping it

var unit: BattleUnit
var home := Vector2.ZERO

var _sprite: Sprite2D


func setup(p_unit: BattleUnit, pos: Vector2) -> void:
	unit = p_unit
	position = pos
	home = pos
	_sprite = Sprite2D.new()
	_sprite.texture = unit.data.battle_sheet
	_sprite.region_enabled = true
	_sprite.flip_h = unit.data.flip_h
	_sprite.offset = Vector2(0, -unit.data.frame_size.y / 2.0)
	add_child(_sprite)
	show_frame(unit.data.idle_frame)


func frame_size() -> Vector2:
	return Vector2(unit.data.frame_size)


func show_frame(index: int) -> void:
	if index < 0:
		index = unit.data.idle_frame
	var size := frame_size()
	var columns := maxi(1, int(_sprite.texture.get_width() / size.x)) if _sprite.texture else 1
	_sprite.region_rect = Rect2((index % columns) * size.x, (index / columns) * size.y, size.x, size.y)


## Point above the head, for the target cursor and damage numbers.
func head_position() -> Vector2:
	return position + Vector2(0, -frame_size().y + 8)


func lunge_to(target: BattlerView) -> void:
	show_frame(unit.data.attack_frame)
	var dir := signf(target.position.x - position.x)
	var stop := target.position - Vector2(dir * STOP_SHORT, 0)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", stop, LUNGE_TIME)
	await tween.finished


func return_home() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", home, RETURN_TIME)
	await tween.finished
	if unit.is_alive():
		show_frame(unit.data.idle_frame)


func cast() -> void:
	if unit.data.cast_frame >= 0:
		show_frame(unit.data.cast_frame)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(1.6, 1.4, 0.8), 0.15)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)
	await tween.finished
	if unit.data.cast_frame >= 0:
		await get_tree().create_timer(0.25).timeout
		if unit.is_alive():
			show_frame(unit.data.idle_frame)


## Victory pose at the end of a won battle (heroes with a battle sheet).
func victory() -> void:
	if unit.is_alive() and unit.data.victory_frame >= 0:
		show_frame(unit.data.victory_frame)


func hurt() -> void:
	show_frame(unit.data.hurt_frame)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(2.0, 0.6, 0.6), 0.06)
	tween.tween_property(_sprite, "position:x", 3.0, 0.05)
	tween.tween_property(_sprite, "position:x", -3.0, 0.05)
	tween.tween_property(_sprite, "position:x", 0.0, 0.05)
	tween.parallel().tween_property(_sprite, "modulate", Color.WHITE, 0.15)
	await tween.finished
	if unit.is_alive():
		show_frame(unit.data.idle_frame)


func revive() -> void:
	_sprite.rotation = 0.0
	_sprite.modulate = Color.WHITE
	_sprite.modulate = Color.WHITE
	show_frame(unit.data.idle_frame)


func knock_out() -> void:
	var tween := create_tween()
	if unit.data.ko_frame >= 0:
		show_frame(unit.data.ko_frame)
		tween.tween_property(_sprite, "modulate", Color(0.6, 0.6, 0.7), 0.3)
	elif unit.is_player:
		tween.tween_property(_sprite, "modulate", Color(0.5, 0.5, 0.6, 0.7), 0.3)
		tween.parallel().tween_property(_sprite, "rotation", -PI / 2 if not unit.data.flip_h else PI / 2, 0.3)
	else:
		tween.tween_property(_sprite, "modulate:a", 0.0, 0.4)
	await tween.finished

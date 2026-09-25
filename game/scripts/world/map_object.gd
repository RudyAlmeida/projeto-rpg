class_name MapObject
extends StaticBody2D
## Interactable thing on a map, drawn from a tileset cell:
## - INSPECT: shows `lines` (signs, machines Kael listens to).
## - CHEST: gives `item_id` × `amount` and/or `money` once (`flag` remembers it).
## - SAVE_POINT: restores the party and opens the save slots.
## - LEVER: sets `flag` (puzzles; FlagGate nodes react to it).
## - BLOCK: a solid obstacle; gone once `flag` is set.
## Any kind can run `cutscene` after interacting, and be gated with `show_if_flag` /
## `hide_if_flag`.

signal used

enum Kind { INSPECT, CHEST, SAVE_POINT, LEVER, BLOCK }

@export var kind := Kind.INSPECT
@export var texture: Texture2D
## Atlas cell (16×16) drawn normally, and once used (open chest, lever on). (-1, -1) = none.
@export var tile := Vector2i(-1, -1)
@export var tile_used := Vector2i(-1, -1)
@export var solid := true
@export var flag: StringName
@export var item_id: StringName
@export var amount := 1
@export var money := 0
@export var lines: Array[DialogueLine] = []
@export var cutscene: Cutscene
@export var show_if_flag: StringName
@export var hide_if_flag: StringName

const TILE := 16
## Drawn at double size so chests, save points and levers read well next to the 56 px
## characters; the sprite stands on the bottom of its cell and grows upwards.
const SCALE := 2.0

var _sprite: Sprite2D
var _shape: CollisionShape2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.region_enabled = true
	_sprite.scale = Vector2(SCALE, SCALE)
	_sprite.position = Vector2(0, TILE / 2.0 - TILE * SCALE / 2.0)
	add_child(_sprite)
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	_shape.shape = rect
	add_child(_shape)
	GameState.flag_changed.connect(func(_name: StringName) -> void: refresh())
	refresh()


func is_used() -> bool:
	return flag != &"" and bool(GameState.get_flag(flag))


func refresh() -> void:
	var visible_now := FlagGate.passes(show_if_flag, hide_if_flag)
	if kind == Kind.BLOCK and is_used():
		visible_now = false
	visible = visible_now
	_shape.set_deferred("disabled", not visible_now or not solid)
	var cell := tile_used if is_used() and tile_used.x >= 0 else tile
	_sprite.visible = cell.x >= 0
	_sprite.region_rect = Rect2(cell * TILE, Vector2(TILE, TILE))


func interact(_player: Node2D) -> void:
	if not visible:
		return
	match kind:
		Kind.INSPECT, Kind.BLOCK:
			if not lines.is_empty():
				await DialogueManager.play(lines)
		Kind.CHEST:
			if is_used():
				await DialogueManager.play([DialogueLine.make("", "Vazio.")] as Array[DialogueLine])
				return
			GameState.set_flag(flag)
			AudioManager.play_sfx(&"chest")
			await DialogueManager.play([DialogueLine.make("", chest_text())] as Array[DialogueLine])
		Kind.SAVE_POINT:
			if not lines.is_empty():
				await DialogueManager.play(lines)
			for member in GameState.party:
				member.restore()
			AudioManager.play_sfx(&"save")
			await MainMenu.open_save(get_tree()).closed
		Kind.LEVER:
			if not lines.is_empty():
				await DialogueManager.play(lines)
			if flag != &"" and not is_used():
				AudioManager.play_sfx(&"lever")
				GameState.set_flag(flag)
	used.emit()
	if cutscene and (cutscene.once_flag == &"" or not GameState.get_flag(cutscene.once_flag)):
		await cutscene.play(get_parent())


## Gives the chest contents and describes them ("Obteve: Poção ×2").
func chest_text() -> String:
	var parts := PackedStringArray()
	if item_id != &"":
		GameState.add_item(item_id, amount)
		var item := DataRegistry.item(item_id)
		var item_name := item.display_name if item else String(item_id)
		parts.append(item_name + (" ×%d" % amount if amount > 1 else ""))
	if money > 0:
		GameState.add_money(money)
		parts.append("%d moedas" % money)
	return "Obteve: " + ", ".join(parts) + "!"

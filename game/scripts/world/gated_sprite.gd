class_name GatedSprite
extends Sprite2D
## Big map decoration that follows the story (FlagGate): the imperial airship over the
## village, the workshop ruins after the explosion. Optional slow hover (`bob`).

@export var show_if_flag: StringName
@export var hide_if_flag: StringName
## Hover amplitude in pixels (0 = static).
@export var bob := 0.0
## Optional tiled ground drawn behind the sprite (hides what used to stand there, e.g.
## the workshop's roof under the ruins): a tileset cell and the rect it covers (local).
@export var backdrop_texture: Texture2D
@export var backdrop_cell := Vector2i(-1, -1)
@export var backdrop_rect := Rect2()

var _time := 0.0
var _base_y := 0.0


func _ready() -> void:
	_base_y = position.y
	if backdrop_texture and backdrop_cell.x >= 0:
		var tile := AtlasTexture.new()
		tile.atlas = backdrop_texture
		tile.region = Rect2(backdrop_cell * 16, Vector2(16, 16))
		var ground := TextureRect.new()
		ground.texture = tile
		ground.stretch_mode = TextureRect.STRETCH_TILE
		ground.position = backdrop_rect.position
		ground.size = backdrop_rect.size
		ground.show_behind_parent = true
		ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(ground)
	GameState.flag_changed.connect(func(_flag: StringName) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	visible = FlagGate.passes(show_if_flag, hide_if_flag)


func _process(delta: float) -> void:
	if bob <= 0.0 or not visible:
		return
	_time += delta
	position.y = _base_y + roundf(sin(_time * 1.6) * bob)

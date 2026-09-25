extends Node2D
## Temporary boot scene: shows the official character reference sheets to validate the art
## pipeline. Left: each sheet at native in-game size (1x). Right: front poses side by side at 2x.

const SHEETS: Array[String] = [
	"res://assets/sprites/characters/kael/chr_kael_ref.png",
	"res://assets/sprites/characters/eco/chr_eco_ref.png",
	"res://assets/sprites/characters/lyra/chr_lyra_ref.png",
]
const FRAMES_PER_SHEET := 4
const ROW_HEIGHT := 96
const TOP := 40
const LINEUP_LEFT := 300
const LINEUP_STEP := 112

@onready var _preview: Sprite2D = $Preview
@onready var _label: Label = $Label


func _ready() -> void:
	_preview.hide()
	var shown := 0
	for path in SHEETS:
		if not ResourceLoader.exists(path):
			continue
		var sheet: Texture2D = load(path)
		var native := Sprite2D.new()
		native.texture = sheet
		native.centered = false
		native.position = Vector2(8, TOP + shown * ROW_HEIGHT)
		add_child(native)

		var front := Sprite2D.new()
		front.texture = sheet
		front.region_enabled = true
		# pixelize.mjs may widen the cell beyond 64 px when a pose does not fit.
		front.region_rect = Rect2(0, 0, sheet.get_width() / FRAMES_PER_SHEET, sheet.get_height())
		front.scale = Vector2(2, 2)
		front.position = Vector2(LINEUP_LEFT + 64 + shown * LINEUP_STEP, 200)
		add_child(front)
		shown += 1
	_label.text = "O Coracao de Eter - personagens (%d)" % shown

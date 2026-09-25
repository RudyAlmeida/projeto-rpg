extends Node2D
## Temporary boot scene: shows the official Kael sprite sheet to validate the art pipeline.
## Top row: 2x zoom for review. Bottom row: native in-game size (1x).

const SHEET_PATH := "res://assets/sprites/characters/kael/chr_kael_ref.png"
const ZOOM := 2

@onready var _preview: Sprite2D = $Preview
@onready var _label: Label = $Label


func _ready() -> void:
	if not ResourceLoader.exists(SHEET_PATH):
		_label.text = "O Coracao de Eter - sprite do Kael nao encontrado"
		return
	var sheet: Texture2D = load(SHEET_PATH)
	_preview.texture = sheet
	_preview.scale = Vector2(ZOOM, ZOOM)
	_preview.position = Vector2(320, 140)

	var native := Sprite2D.new()
	native.texture = sheet
	native.position = Vector2(320, 320)
	add_child(native)

	_label.text = "O Coracao de Eter - Kael (2x e tamanho real)"

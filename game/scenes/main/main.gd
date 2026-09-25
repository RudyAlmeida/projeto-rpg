extends Node2D
## Temporary boot scene: shows the Codex test image to validate the art pipeline.

const TEST_IMAGE_PATH := "res://assets/_tests/codex_test_01.png"

@onready var _preview: Sprite2D = $Preview
@onready var _label: Label = $Label


func _ready() -> void:
	if ResourceLoader.exists(TEST_IMAGE_PATH):
		_preview.texture = load(TEST_IMAGE_PATH)
		var fit := 600.0 / _preview.texture.get_width()
		_preview.scale = Vector2(fit, fit)
		_label.text = "Projeto RPG - teste de pipeline (Codex)"
	else:
		_label.text = "Projeto RPG - imagem de teste nao encontrada"

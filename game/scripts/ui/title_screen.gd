extends Node2D
## Title screen: key art, logo, New game / Continue / Options / Quit.

const BACKGROUND := preload("res://assets/ui/bg_title.png")
const MUSIC := preload("res://assets/audio/music/bgm_title_b.mp3")
const FIRST_MAP := "res://scenes/maps/prologue/oficina.tscn"
const FIRST_SPAWN := "start"

var _menu: ListMenu
var _slots: ListMenu
var _options: OptionsPanel
var _ui: CanvasLayer


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = BACKGROUND
	bg.centered = false
	add_child(bg)
	_ui = CanvasLayer.new()
	add_child(_ui)
	var logo := UIKit.label(_ui, Vector2(24, 34), "O Coração de Éter", UIKit.GOLD)
	logo.add_theme_font_size_override("font_size", 32)
	logo.add_theme_color_override("font_outline_color", UIKit.DARK)
	logo.add_theme_constant_override("outline_size", 6)
	var tagline := UIKit.label(_ui, Vector2(28, 72), "Um RPG de fantasia e vapor", UIKit.TEXT)
	tagline.add_theme_color_override("font_outline_color", UIKit.DARK)
	tagline.add_theme_constant_override("outline_size", 4)
	_menu = ListMenu.create(_ui, Rect2(24, 104, 170, 84))
	_menu.set_entries(menu_entries())
	AudioManager.play_music(MUSIC)


static func menu_entries() -> Array:
	var any_save := range(1, MainMenu.SAVE_SLOTS + 1).any(func(s: int) -> bool: return SaveManager.has_save(s))
	return [
		{"text": "Novo jogo", "id": "new"},
		{"text": "Continuar", "id": "continue", "enabled": any_save},
		{"text": "Opções", "id": "options"},
		{"text": "Sair", "id": "quit"},
	]


func new_game() -> void:
	GameState.party.clear()  # the first map starts a fresh game with its party
	SceneManager.change_scene(FIRST_MAP, FIRST_SPAWN)


func _unhandled_input(event: InputEvent) -> void:
	if _options:
		return
	var active := _slots if _slots else _menu
	if active.handle_navigation(event):
		get_viewport().set_input_as_handled()
	elif UIKit.is_back(event) and _slots:
		AudioManager.play_sfx(&"ui_cancel")
		get_viewport().set_input_as_handled()
		_slots.queue_free()
		_slots = null
	elif event.is_action_pressed(&"confirm"):
		AudioManager.play_sfx(&"ui_confirm")
		get_viewport().set_input_as_handled()
		if _slots:
			if _slots.is_enabled():
				SaveManager.load_game(_slots.current()["slot"])
			return
		if not _menu.is_enabled():
			return
		match _menu.current()["id"]:
			"new":
				new_game()
			"continue":
				_slots = ListMenu.create(_ui, Rect2(200, 104, 300, 84), "Continuar")
				_slots.set_entries(MainMenu.save_slot_entries().map(func(e: Dictionary) -> Dictionary:
					e["enabled"] = SaveManager.has_save(e["slot"])
					return e))
			"options":
				_options = OptionsPanel.new()
				_ui.add_child(_options)
				_options.closed.connect(func() -> void:
					_options.queue_free()
					_options = null)
			"quit":
				get_tree().quit()

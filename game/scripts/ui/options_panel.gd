class_name OptionsPanel
extends Control
## Options screen shared by the title and the pause menu. ↑↓ picks a row, ←→ changes it,
## cancel saves and emits `closed`.

signal closed

const TEXT_SPEED_NAMES := {&"slow": "Lento", &"normal": "Normal", &"fast": "Rápido", &"instant": "Instantâneo"}
const TIMING_NAMES := {&"easy": "Fácil (janela 2×)", &"normal": "Normal", &"hard": "Difícil (janela ½)", &"auto": "Automático"}
const LANGUAGE_NAMES := {&"pt_BR": "Português", &"en": "English (parcial)"}

var _list: ListMenu
var _help: Label


func _ready() -> void:
	_list = ListMenu.create(self, Rect2(120, 70, 400, 136), "Opções")
	var help_panel := UIKit.panel(self, Rect2(120, 212, 400, 44))
	_help = UIKit.label(help_panel, Vector2(10, 4), "", UIKit.DIM)
	_help.size = Vector2(380, 36)
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh()


func _refresh() -> void:
	_list.set_entries([
		{"text": "Volume da música", "note": "%d%%" % roundi(Settings.music_volume * 100), "id": "volume",
			"help": "Volume das músicas."},
		{"text": "Velocidade do texto", "note": TEXT_SPEED_NAMES[Settings.text_speed], "id": "text",
			"help": "Velocidade das letras nos diálogos."},
		{"text": "Timing em batalha", "note": TIMING_NAMES[Settings.timing_mode], "id": "timing",
			"help": "Automático acerta sempre \"Bom\". Fácil dobra as janelas de tempo."},
		{"text": "Tela cheia", "note": "Sim" if Settings.fullscreen else "Não", "id": "fullscreen",
			"help": "Alterna entre janela e tela cheia."},
		{"text": "Idioma", "note": LANGUAGE_NAMES[Settings.language], "id": "language",
			"help": "O inglês cobre só os menus por enquanto."},
	], true)
	_help.text = _list.current().get("help", "")


func change(id: String, step: int) -> void:
	match id:
		"volume":
			Settings.music_volume = clampf(snappedf(Settings.music_volume + 0.1 * step, 0.1), 0.0, 1.0)
		"text":
			Settings.text_speed = _cycle(Settings.TEXT_SPEEDS.keys(), Settings.text_speed, step)
		"timing":
			Settings.timing_mode = _cycle(Settings.TIMING_WINDOWS.keys(), Settings.timing_mode, step)
		"fullscreen":
			Settings.fullscreen = not Settings.fullscreen
		"language":
			Settings.language = _cycle(Settings.LANGUAGES, Settings.language, step)
	Settings.apply()
	_refresh()


static func _cycle(options: Array, current: StringName, step: int) -> StringName:
	return options[wrapi(options.find(current) + step, 0, options.size())]


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if _list.handle_navigation(event):
		_help.text = _list.current().get("help", "")
	elif event.is_action_pressed(&"move_right") or event.is_action_pressed(&"confirm"):
		change(_list.current()["id"], 1)
	elif event.is_action_pressed(&"move_left"):
		change(_list.current()["id"], -1)
	elif event.is_action_pressed(&"cancel"):
		Settings.save_settings()
		closed.emit()
	else:
		return
	get_viewport().set_input_as_handled()

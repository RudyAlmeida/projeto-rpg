extends Node
## Autoload "Settings": player preferences stored in user://settings.cfg (not in saves)
## and applied immediately — music volume, text speed, timing difficulty, fullscreen,
## language.

signal changed

const PATH := "user://settings.cfg"
const TEXT_SPEEDS := {&"slow": 25.0, &"normal": 40.0, &"fast": 80.0, &"instant": 10000.0}
## GDD 4.1 accessibility: easy = windows 2x, hard = ½, auto = always "Good".
const TIMING_WINDOWS := {&"easy": 2.0, &"normal": 1.0, &"hard": 0.5, &"auto": 1.0}
const LANGUAGES := [&"pt_BR", &"en"]

var music_volume := 0.8
var sfx_volume := 0.8
var text_speed: StringName = &"normal"
var timing_mode: StringName = &"normal"
var fullscreen := false
var language: StringName = &"pt_BR"


func _ready() -> void:
	load_settings()
	apply()


func timing_window() -> float:
	return TIMING_WINDOWS.get(timing_mode, 1.0)


## DamageFormula.Timing to force in battle (-1 = the player presses).
func auto_timing() -> int:
	return DamageFormula.Timing.GOOD if timing_mode == &"auto" else -1


func chars_per_second() -> float:
	return TEXT_SPEEDS.get(text_speed, 40.0)


func apply() -> void:
	AudioManager.music_volume = music_volume
	AudioManager.sfx_volume = sfx_volume
	if DialogueManager.box():
		DialogueManager.box().chars_per_second = chars_per_second()
	if not Engine.is_embedded_in_editor() and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	TranslationServer.set_locale(String(language))
	changed.emit()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("game", "text_speed", String(text_speed))
	cfg.set_value("game", "timing_mode", String(timing_mode))
	cfg.set_value("game", "language", String(language))
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	music_volume = float(cfg.get_value("audio", "music_volume", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", sfx_volume))
	text_speed = StringName(cfg.get_value("game", "text_speed", String(text_speed)))
	timing_mode = StringName(cfg.get_value("game", "timing_mode", String(timing_mode)))
	language = StringName(cfg.get_value("game", "language", String(language)))
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))

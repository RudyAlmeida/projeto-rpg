class_name DialogueLine
extends Resource
## One line of dialogue: who speaks, their portrait and the text (Portuguese, player-facing).

@export var speaker := ""
@export var portrait: Texture2D
@export_multiline var text := ""


static func make(p_speaker: String, p_text: String, p_portrait: Texture2D = null) -> DialogueLine:
	var line := DialogueLine.new()
	line.speaker = p_speaker
	line.text = p_text
	line.portrait = p_portrait
	return line

class_name TileLegends
extends RefCounted
## Text-map legends: which tile each symbol paints. One legend per tileset (8×6 atlases of
## 16×16 tiles made by tools/art/tiles.mjs; see the asset prompts for what each cell holds).
##
## Entry keys: "tile" (atlas cell), "solid", and "decor": true for props drawn on a second
## layer over the ground of the nearest non-decor symbol on the same row (left first).
## "spawn": true marks the default player spawn.

const PLACEHOLDER := {
	"texture": "res://assets/tilesets/til_placeholder.png",
	"symbols": {
		".": {"tile": Vector2i(0, 0)},
		",": {"tile": Vector2i(1, 0)},
		"#": {"tile": Vector2i(2, 0), "solid": true},
		"~": {"tile": Vector2i(3, 0), "solid": true},
		"P": {"tile": Vector2i(0, 0), "spawn": true},
		"p": {"tile": Vector2i(1, 0), "spawn": true},
	},
}

## Vila Caldeira (town + interiors), til_vila_caldeira.png.
const VILA := {
	"texture": "res://assets/tilesets/til_vila_caldeira.png",
	"symbols": {
		# ground
		".": {"tile": Vector2i(0, 0)},
		"\"": {"tile": Vector2i(1, 0)},
		",": {"tile": Vector2i(2, 0)},
		":": {"tile": Vector2i(3, 0)},
		"_": {"tile": Vector2i(4, 0)},
		"=": {"tile": Vector2i(5, 0)},
		";": {"tile": Vector2i(6, 0)},
		"s": {"tile": Vector2i(7, 0)},
		# grass/dirt edges and canal
		"1": {"tile": Vector2i(0, 1)},
		"2": {"tile": Vector2i(1, 1)},
		"3": {"tile": Vector2i(2, 1)},
		"4": {"tile": Vector2i(3, 1)},
		"~": {"tile": Vector2i(6, 1), "solid": true},
		"u": {"tile": Vector2i(7, 1), "solid": true},
		# walls, doors, windows, fences
		"#": {"tile": Vector2i(0, 2), "solid": true},
		"b": {"tile": Vector2i(1, 2), "solid": true},
		"H": {"tile": Vector2i(2, 2), "solid": true},
		"D": {"tile": Vector2i(3, 2)},
		"W": {"tile": Vector2i(4, 2), "solid": true},
		"O": {"tile": Vector2i(5, 2), "solid": true},
		"f": {"tile": Vector2i(6, 2), "solid": true, "decor": true},
		"F": {"tile": Vector2i(7, 2), "solid": true, "decor": true},
		# roofs and pipes
		"^": {"tile": Vector2i(0, 3), "solid": true},
		"A": {"tile": Vector2i(1, 3), "solid": true},
		"r": {"tile": Vector2i(2, 3), "solid": true},
		"R": {"tile": Vector2i(3, 3), "solid": true},
		"C": {"tile": Vector2i(4, 3), "solid": true},
		"-": {"tile": Vector2i(5, 3), "solid": true, "decor": true},
		"|": {"tile": Vector2i(6, 3), "solid": true, "decor": true},
		"L": {"tile": Vector2i(7, 3), "solid": true, "decor": true},
		# props
		"x": {"tile": Vector2i(0, 4), "solid": true, "decor": true},
		"o": {"tile": Vector2i(1, 4), "solid": true, "decor": true},
		"g": {"tile": Vector2i(2, 4), "solid": true, "decor": true},
		"l": {"tile": Vector2i(3, 4), "solid": true, "decor": true},
		"k": {"tile": Vector2i(4, 4), "solid": true, "decor": true},
		"v": {"tile": Vector2i(5, 4), "solid": true, "decor": true},
		"n": {"tile": Vector2i(6, 4), "solid": true, "decor": true},
		"m": {"tile": Vector2i(7, 4), "solid": true, "decor": true},
		"t": {"tile": Vector2i(0, 5), "solid": true, "decor": true},
		"B": {"tile": Vector2i(1, 5), "solid": true, "decor": true},
		"c": {"tile": Vector2i(2, 5), "solid": true, "decor": true},
		"K": {"tile": Vector2i(3, 5), "solid": true, "decor": true},
		"S": {"tile": Vector2i(4, 5), "solid": true, "decor": true},
		"w": {"tile": Vector2i(5, 5), "solid": true, "decor": true},
		"T": {"tile": Vector2i(6, 5), "solid": true, "decor": true},
		"Y": {"tile": Vector2i(7, 5), "solid": true, "decor": true},
		"P": {"decor": true, "spawn": true},
	},
}

## Ferro-Velho do Sul (scrapyard + Aethelian ruin), til_junkyard.png.
const JUNKYARD := {
	"texture": "res://assets/tilesets/til_junkyard.png",
	"symbols": {
		# ground
		".": {"tile": Vector2i(0, 0)},
		"_": {"tile": Vector2i(1, 0)},
		"=": {"tile": Vector2i(2, 0)},
		"o": {"tile": Vector2i(3, 0)},
		",": {"tile": Vector2i(4, 0)},
		"+": {"tile": Vector2i(5, 0)},
		":": {"tile": Vector2i(6, 0)},
		";": {"tile": Vector2i(7, 0)},
		# walls
		"#": {"tile": Vector2i(0, 1), "solid": true},
		"M": {"tile": Vector2i(1, 1), "solid": true},
		"Z": {"tile": Vector2i(2, 1), "solid": true},
		"B": {"tile": Vector2i(3, 1), "solid": true},
		"R": {"tile": Vector2i(4, 1), "solid": true},
		"Q": {"tile": Vector2i(5, 1), "solid": true},
		"I": {"tile": Vector2i(6, 1), "solid": true},
		"V": {"tile": Vector2i(7, 1), "solid": true},
		# machinery
		"c": {"tile": Vector2i(0, 2), "solid": true},
		"e": {"tile": Vector2i(1, 2), "solid": true},
		"X": {"tile": Vector2i(2, 2), "solid": true, "decor": true},
		"k": {"tile": Vector2i(5, 2), "solid": true, "decor": true},
		"h": {"tile": Vector2i(6, 2), "solid": true, "decor": true},
		"v": {"tile": Vector2i(7, 2), "decor": true},
		# giant gear (2×2) and pipes
		"1": {"tile": Vector2i(0, 3), "solid": true, "decor": true},
		"2": {"tile": Vector2i(1, 3), "solid": true, "decor": true},
		"3": {"tile": Vector2i(2, 3), "solid": true, "decor": true},
		"4": {"tile": Vector2i(3, 3), "solid": true, "decor": true},
		"-": {"tile": Vector2i(4, 3), "solid": true, "decor": true},
		"|": {"tile": Vector2i(5, 3), "solid": true, "decor": true},
		"L": {"tile": Vector2i(6, 3), "solid": true, "decor": true},
		# props
		"t": {"tile": Vector2i(0, 4), "solid": true, "decor": true},
		"W": {"tile": Vector2i(1, 4), "solid": true, "decor": true},
		"g": {"tile": Vector2i(2, 4), "solid": true, "decor": true},
		"b": {"tile": Vector2i(3, 4), "solid": true, "decor": true},
		"x": {"tile": Vector2i(4, 4), "solid": true, "decor": true},
		"K": {"tile": Vector2i(7, 4), "solid": true, "decor": true},
		"a": {"tile": Vector2i(0, 5), "solid": true, "decor": true},
		"n": {"tile": Vector2i(1, 5), "decor": true},
		"l": {"tile": Vector2i(2, 5), "solid": true, "decor": true},
		"!": {"tile": Vector2i(3, 5), "solid": true, "decor": true},
		"y": {"tile": Vector2i(4, 5), "decor": true},
		"j": {"tile": Vector2i(5, 5), "decor": true},
		"i": {"tile": Vector2i(6, 5), "solid": true, "decor": true},
		"O": {"tile": Vector2i(7, 5), "decor": true},
		"P": {"decor": true, "spawn": true},
	},
}

## Atlas cells used by MapObject (chests, levers, save point, blocks) per tileset.
const JUNKYARD_OBJECTS := {
	"chest": Vector2i(5, 4), "chest_open": Vector2i(6, 4),
	"lever_off": Vector2i(3, 2), "lever_on": Vector2i(4, 2),
	"boiler": Vector2i(7, 3), "scrap_block": Vector2i(7, 4),
}


static func get_legend(legend_name: String) -> Dictionary:
	match legend_name:
		"vila":
			return VILA
		"junkyard":
			return JUNKYARD
	return PLACEHOLDER

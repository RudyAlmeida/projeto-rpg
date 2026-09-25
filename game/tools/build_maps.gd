extends Node
## Generates the prologue maps (scenes/maps/prologue/*.tscn) from text grids plus node
## lists (NPCs, doors, spawns, objects, encounters, cutscene triggers). Maps are code so
## they stay diff-friendly and consistent with the data built by build_data.gd.
## Run after build_data: godot --headless --path game res://tools/build_maps.tscn
## Script: docs/Roteiro_Prologo.docx.

const OUT := "res://scenes/maps/prologue/"
const PLAYER := preload("res://scenes/characters/player.tscn")
const NPC_SCENE := preload("res://scenes/characters/npc.tscn")
const ENEMY_SCENE := preload("res://scenes/characters/field_enemy.tscn")
const MUSIC_VILA := "res://assets/audio/music/bgm_vila_caldeira_test_a.mp3"
const MUSIC_JUNKYARD := "res://assets/audio/music/bgm_junkyard_a.mp3"
const TIL_VILA := "res://assets/tilesets/til_vila_caldeira.png"
const TIL_JUNK := "res://assets/tilesets/til_junkyard.png"
const POR_KAEL := "res://assets/portraits/por_kael_neutral.png"
const POR_GERD := "res://assets/portraits/por_gerd_neutral.png"
const F := Player.Facing

var _grid: Array = []  # rows of single-character Strings
var _root: FieldMap
var _saved := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_oficina()
	_loja()
	_estalagem()
	_relojoaria()
	_vila()
	_estrada()
	_ferro1()
	_ferro2()
	_ferro3()
	_camara()
	print("build_maps: %d maps written" % _saved)
	get_tree().quit()


# ---------- grid helpers ----------

static func c(x: float, y: float) -> Vector2:
	return Vector2(x * 16 + 8, y * 16 + 8)


func _new_grid(w: int, h: int, fill: String) -> void:
	_grid = []
	for y in h:
		var row := []
		row.resize(w)
		row.fill(fill)
		_grid.append(row)


func _cell_set(x: int, y: int, ch: String) -> void:
	if y >= 0 and y < _grid.size() and x >= 0 and x < _grid[y].size():
		_grid[y][x] = ch


func _fill(x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_cell_set(x, y, ch)


func _border(ch: String) -> void:
	var w: int = _grid[0].size()
	var h := _grid.size()
	_fill(0, 0, w - 1, 0, ch)
	_fill(0, h - 1, w - 1, h - 1, ch)
	_fill(0, 0, 0, h - 1, ch)
	_fill(w - 1, 0, w - 1, h - 1, ch)


## Stamps decor symbols: "x,y:ch x,y:ch ...".
func _put(spec: String) -> void:
	for item in spec.split(" ", false):
		var parts := item.split(":")
		var xy := parts[0].split(",")
		_cell_set(int(xy[0]), int(xy[1]), parts[1])


## Facade building: ridge row, roof rows, wall rows (windows on the first wall row, door
## on the last). Returns the door cell (or (-1, -1)).
func _house(x0: int, y0: int, w: int, roof_rows: int, wall_rows: int, roof: String, ridge: String,
		wall: String, door_dx: int, windows: Array) -> Vector2i:
	_fill(x0, y0, x0 + w - 1, y0, ridge)
	_fill(x0, y0 + 1, x0 + w - 1, y0 + roof_rows - 1, roof)
	var wy := y0 + roof_rows
	_fill(x0, wy, x0 + w - 1, wy + wall_rows - 1, wall)
	for dx: int in windows:
		_cell_set(x0 + dx, wy, "W")
	if door_dx < 0:
		return Vector2i(-1, -1)
	var door := Vector2i(x0 + door_dx, wy + wall_rows - 1)
	_cell_set(door.x, door.y, "D")
	return door


## Room interior: walls all around (two rows at the top), floor inside, door gap at the
## bottom. Returns the door cell.
func _room(w: int, h: int, wall: String, floor_ch: String, door_x: int, windows: Array) -> Vector2i:
	_new_grid(w, h, floor_ch)
	_border(wall)
	_fill(0, 1, w - 1, 1, wall)
	for x: int in windows:
		_cell_set(x, 1, "W")
	_cell_set(door_x, h - 1, "D")
	return Vector2i(door_x, h - 1)


func _layout() -> String:
	var rows := PackedStringArray()
	for row: Array in _grid:
		rows.append("".join(row))
	return "\n".join(rows)


# ---------- scene helpers ----------

func _begin(map_name: String, legend: String, music: String) -> void:
	_root = FieldMap.new()
	_root.name = map_name
	_root.y_sort_enabled = true
	_root.music = load(music) if music != "" else null
	var tiles := AsciiMap.new()
	tiles.name = "Map"
	tiles.legend = legend
	tiles.layout = _layout()
	_own(tiles)
	var player := PLAYER.instantiate()
	player.name = "Player"
	_own(player)
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	_own(spawns)


func _own(node: Node, parent: Node = null) -> Node:
	(parent if parent else _root).add_child(node)
	node.owner = _root
	return node


func _finish(file: String) -> void:
	var scene := PackedScene.new()
	var err := scene.pack(_root)
	assert(err == OK, "pack %s: %s" % [file, error_string(err)])
	var path := OUT + file + ".tscn"
	scene.take_over_path(path)
	err = ResourceSaver.save(scene, path)
	assert(err == OK, "save %s: %s" % [path, error_string(err)])
	_root.free()
	_saved += 1


func _spawn(id: String, cell: Vector2, facing: Player.Facing) -> void:
	var s := SpawnPoint.new()
	s.name = id
	s.position = c(cell.x, cell.y)
	s.facing = facing
	_own(s, _root.get_node("Spawns"))


func _shape(parent: Node, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	_own(shape, parent)


## Door / exit covering `cells_w` cells from `cell`.
func _warp(node_name: String, cell: Vector2, target: String, spawn: String, cells_w := 1, props := {}) -> void:
	var w := Warp.new()
	w.name = node_name
	w.position = c(cell.x + (cells_w - 1) / 2.0, cell.y)
	w.target_scene = OUT + target + ".tscn"
	w.target_spawn = spawn
	if not "Door" in node_name:
		w.sound = &""
	for key: String in props:
		w.set(key, props[key])
	_own(w)
	_shape(w, Vector2(16 * cells_w - 4, 12))


func _npc(node_name: String, cell: Vector2, sheet: String, row: int, facing: Player.Facing, props := {}) -> NPC:
	var n: NPC = NPC_SCENE.instantiate()
	n.name = node_name
	n.position = c(cell.x, cell.y)
	n.idle_sheet = _sheet(sheet)
	n.sheet_row = row
	n.facing = facing
	for key: String in props:
		n.set(key, props[key])
	_own(n)
	return n


## Character sheets; NPCs whose art is still being made fall back to the villagers sheet.
func _sheet(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return load("res://assets/sprites/characters/villagers/npc_villagers.png")


func _object(node_name: String, cell: Vector2, kind: MapObject.Kind, tileset: String, tile: Vector2i, props := {}) -> MapObject:
	var o := MapObject.new()
	o.name = node_name
	o.position = c(cell.x, cell.y)
	o.kind = kind
	o.texture = load(tileset)
	o.tile = tile
	for key: String in props:
		o.set(key, props[key])
	_own(o)
	return o


## Story-gated decoration (skipped while its art does not exist). The sprite's bottom
## sits on `cell` so y-sorting with the player works.
func _gated_sprite(node_name: String, path: String, cell: Vector2, show_if: StringName, hide_if: StringName,
		bob: float, z: int) -> void:
	if not ResourceLoader.exists(path):
		return
	var g := GatedSprite.new()
	g.name = node_name
	g.texture = load(path)
	g.position = c(cell.x, cell.y) + Vector2(0, 8)
	g.offset = Vector2(0, -g.texture.get_height() / 2.0)
	g.show_if_flag = show_if
	g.hide_if_flag = hide_if
	g.bob = bob
	g.z_index = z
	_own(g)


func _enemy(node_name: String, cell: Vector2, ids: Array, props := {}) -> void:
	var e: FieldEnemy = ENEMY_SCENE.instantiate()
	e.name = node_name
	e.position = c(cell.x, cell.y)
	var list: Array[CombatantData] = []
	for id: String in ids:
		list.append(load("res://data/enemies/%s.tres" % id))
	e.enemies = list
	for key: String in props:
		e.set(key, props[key])
	_own(e)


func _trigger(node_name: String, cell: Vector2, size_cells: Vector2, cutscene: String, props := {}) -> void:
	var t := CutsceneTrigger.new()
	t.name = node_name
	t.position = c(cell.x, cell.y)
	t.cutscene = load("res://data/cutscenes/%s.tres" % cutscene)
	for key: String in props:
		t.set(key, props[key])
	_own(t)
	_shape(t, size_cells * 16)


func _lines(items: Array) -> Array[DialogueLine]:
	var out: Array[DialogueLine] = []
	for item: Array in items:
		out.append(DialogueLine.make(item[0], item[1], load(item[2]) if item.size() > 2 else null))
	return out


func _dialogue(id: String) -> DialogueSet:
	return load("res://data/dialogue/%s.tres" % id)


func _items(ids: Array) -> Array[ItemData]:
	var out: Array[ItemData] = []
	for id: String in ids:
		out.append(load("res://data/items/%s.tres" % id))
	return out


# ---------- Vila Caldeira: interiors ----------

const VILLAGERS := "res://assets/sprites/characters/villagers/npc_villagers.png"
const VILLAGERS2 := "res://assets/sprites/characters/villagers/npc_villagers2.png"
const GERD_SHEET := "res://assets/sprites/characters/gerd/npc_gerd_ref.png"
const ECO_SHEET := "res://assets/sprites/characters/eco/chr_eco_ref.png"
const VOSS_SHEET := "res://assets/sprites/characters/voss/chr_voss_map.png"


func _oficina() -> void:
	_room(16, 11, "#", "_", 7, [2, 7, 12])
	_cell_set(15, 5, "D")  # back door
	_put("5,2:K 1,9:o 14,9:x 1,2:c 14,2:g 8,6:x 9,6:x")
	_begin("Oficina", "vila", MUSIC_VILA)
	# New game (title screen): Kael alone, a little money and two potions.
	_root.party = [load("res://data/characters/kael.tres")] as Array[CombatantData]
	_root.starting_money = 50
	_root.starting_items = {&"potion": 2}
	_root.starting_weapons = {&"kael": &"wrench"}
	_root.tint = Color(0.5, 0.55, 0.85)
	_root.tint_show_if = &"boss_beaten"
	_root.tint_hide_if = &"slept"
	var Kd := "Kael"
	_object("Furnace", Vector2(2, 2), MapObject.Kind.INSPECT, TIL_VILA, Vector2i(4, 3), {"lines": _lines([
		[Kd, "A fornalha da oficina. O mestre diz que ela é mais velha que ele. Ela concorda.", POR_KAEL]])})
	_object("Anvil", Vector2(4, 2), MapObject.Kind.INSPECT, TIL_VILA, Vector2i(6, 4), {"lines": _lines([
		[Kd, "A bancada. Ainda tem a marca da minha testa de hoje de manhã.", POR_KAEL]])})
	_object("Photo", Vector2(12, 2), MapObject.Kind.INSPECT, TIL_VILA, Vector2i(0, 4), {"lines": _lines([
		["", "Sobre a caixa, uma foto antiga: um Gerd jovem, de uniforme imperial, ao lado de uma máquina enorme."],
		[Kd, "Nunca vi o velho sorrir assim.", POR_KAEL]])})
	_object("Clock", Vector2(13, 7), MapObject.Kind.INSPECT, TIL_VILA, Vector2i(2, 4), {"lines": _lines([
		[Kd, "Um relógio desmontado. As engrenagens reclamam de saudade dos ponteiros.", POR_KAEL]])})
	_object("Bed", Vector2(11, 4), MapObject.Kind.INSPECT, TIL_VILA, Vector2i(1, 5), {"hide_if_flag": &"dinner_done",
		"lines": _lines([[Kd, "Ainda é cedo pra dormir. O mestre ia me acordar com um balde.", POR_KAEL]])})
	_object("BedRest", Vector2(11, 4), MapObject.Kind.SAVE_POINT, TIL_VILA, Vector2i(1, 5), {
		"show_if_flag": &"dinner_done", "hide_if_flag": &"slept",
		"lines": _lines([["", "Kael se deita. Lá embaixo, Eco observa a fornalha a noite inteira."]]),
		"cutscene": load("res://data/cutscenes/p8_morning.tres")})
	_npc("GerdMorning", Vector2(9, 4), GERD_SHEET, 0, F.LEFT, {"display_name": "Mestre Gerd",
		"dialogue_set": _dialogue("p_gerd_morning"), "hide_if_flag": &"gerd_joined"})
	_npc("GerdEvening", Vector2(8, 5), GERD_SHEET, 0, F.DOWN, {"display_name": "Mestre Gerd",
		"dialogue_set": _dialogue("p_gerd_evening"), "show_if_flag": &"boss_beaten", "hide_if_flag": &"gerd_out"})
	_npc("EcoHome", Vector2(10, 7), ECO_SHEET, 0, F.LEFT, {"display_name": "Eco",
		"dialogue_set": _dialogue("p_eco_home"), "show_if_flag": &"boss_beaten", "hide_if_flag": &"gerd_out"})
	_npc("Pip", Vector2(7, 9), VILLAGERS2, 0, F.UP, {"display_name": "Pip",
		"dialogue_set": _dialogue("p_pip"), "show_if_flag": &"slept", "hide_if_flag": &"gerd_out"})
	_npc("GerdFarewell", Vector2(8, 6), GERD_SHEET, 0, F.DOWN, {"display_name": "Mestre Gerd",
		"show_if_flag": &"voss_fought", "hide_if_flag": &"escaped"})
	_spawn("start", Vector2(4, 3), F.UP)
	_spawn("entrance", Vector2(7, 9), F.UP)
	_spawn("back", Vector2(14, 5), F.LEFT)
	_spawn("dinner", Vector2(6, 6), F.RIGHT)
	_root.get_node("Map").layout = _layout()
	_warp("Door", Vector2(7, 10), "vila_caldeira", "from_oficina")
	_warp("BackDoor", Vector2(15, 5), "vila_caldeira", "back_door")
	_trigger("Morning", Vector2(4, 3), Vector2(1, 1), "p1_morning", {"autostart": true})
	_trigger("Dinner", Vector2(6, 6), Vector2(1, 1), "p7_dinner", {"autostart": true, "show_if_flag": &"boss_beaten"})
	_trigger("Farewell", Vector2(7, 9), Vector2(1, 1), "p9_farewell", {"autostart": true, "show_if_flag": &"voss_fought"})
	_finish("oficina")


func _loja() -> void:
	_room(12, 9, "H", "_", 6, [2, 9])
	_put("4,4:x 5,4:x 7,4:x 8,4:x 1,2:o 10,2:o 1,7:g 10,7:c")
	_begin("Loja", "vila", MUSIC_VILA)
	_npc("Tobias", Vector2(6, 3), VILLAGERS, 0, F.DOWN, {"display_name": "Engrenagem Dourada",
		"dialogue_set": _dialogue("p_tobias"), "role": NPC.Role.SHOP,
		"shop_stock": _items(["potion", "ether", "antidote", "phoenix_feather", "smelling_salts", "brass_blade",
			"aviator_coat", "eco_plating", "brass_amulet", "gem_ice", "gem_heal"])})
	_spawn("entrance", Vector2(6, 7), F.UP)
	_warp("Door", Vector2(6, 8), "vila_caldeira", "from_loja")
	_finish("loja")


func _estalagem() -> void:
	_room(14, 10, "#", "=", 7, [2, 5, 9, 12])
	_put("5,4:x 6,4:x 8,4:x 9,4:x 2,6:B 11,6:B 2,8:v 11,8:v 1,2:o")
	_begin("Estalagem", "vila", MUSIC_VILA)
	_npc("Berta", Vector2(7, 3), VILLAGERS, 1, F.DOWN, {"display_name": "Dona Berta",
		"dialogue_set": _dialogue("p_berta"), "role": NPC.Role.INN, "inn_price": 20})
	_spawn("entrance", Vector2(7, 8), F.UP)
	_warp("Door", Vector2(7, 9), "vila_caldeira", "from_estalagem")
	_finish("estalagem")


func _relojoaria() -> void:
	_room(10, 8, "H", "_", 5, [2, 7])
	_put("1,2:g 8,2:g 3,4:x 4,4:x 6,4:x 1,6:K")
	_begin("Relojoaria", "vila", MUSIC_VILA)
	_npc("Anselmo", Vector2(5, 3), VILLAGERS2, 3, F.DOWN, {"display_name": "Sr. Anselmo",
		"dialogue_set": _dialogue("p_anselmo")})
	_spawn("entrance", Vector2(5, 6), F.UP)
	_warp("Door", Vector2(5, 7), "vila_caldeira", "from_relojoaria")
	_finish("relojoaria")


# ---------- Vila Caldeira: exterior ----------

func _vila() -> void:
	_new_grid(50, 32, ".")
	_border("T")
	_fill(1, 15, 48, 16, ":")          # main street
	_fill(24, 0, 25, 31, ":")          # north-south street and gates
	_fill(18, 11, 31, 20, ":")         # square
	var oficina := _house(36, 9, 9, 3, 2, "r", "R", "#", 4, [1, 7])
	_cell_set(37, 9, "C")
	var loja := _house(6, 4, 7, 3, 2, "^", "A", "H", 3, [1, 5])
	var estalagem := _house(29, 3, 9, 3, 2, "^", "A", "#", 4, [1, 3, 5, 7])
	var relojoaria := _house(6, 20, 7, 3, 2, "r", "R", "H", 3, [1, 5])
	_house(34, 21, 7, 3, 2, "^", "A", "#", -1, [1, 3, 5])
	_house(14, 4, 5, 2, 2, "r", "R", "H", -1, [2])
	_fill(9, 9, 9, 14, ",")
	_fill(33, 8, 33, 14, ",")
	_fill(40, 14, 40, 14, ",")
	_fill(9, 25, 23, 26, ",")
	_fill(2, 27, 18, 27, "u")
	_fill(2, 28, 18, 29, "~")
	_put("21,13:w 20,18:B 29,13:B 18,11:l 31,11:l 18,20:l 31,20:l 3,12:T 45,5:T 46,25:T 15,24:T 44,28:T 3,6:T")
	_put("30,8:v 36,8:v 45,13:o 35,13:x 42,14:n 27,22:m 22,29:t 11,9:S 13,12:k 26,11:k 47,20:k 20,8:k")
	_put('5,17:" 6,17:" 30,24:" 31,24:" 43,17:" 44,18:"')
	_begin("VilaCaldeira", "vila", MUSIC_VILA)
	_warp("OficinaDoor", Vector2(oficina.x, oficina.y), "oficina", "entrance")
	_warp("LojaDoor", Vector2(loja.x, loja.y), "loja", "entrance")
	_warp("EstalagemDoor", Vector2(estalagem.x, estalagem.y), "estalagem", "entrance")
	_warp("RelojoariaDoor", Vector2(relojoaria.x, relojoaria.y), "relojoaria", "entrance")
	_warp("SouthGate", Vector2(24, 31), "estrada_sul", "from_vila", 2, {"require_flag": &"gerd_joined",
		"push_back": Vector2(0, -14), "locked_lines": _lines([["Kael", "(Melhor terminar a entrega do mestre antes de sair da vila.)", POR_KAEL]])})
	_warp("NorthGate", Vector2(24, 0), "vila_caldeira", "", 2, {"require_flag": &"north_gate_open",
		"push_back": Vector2(0, 14), "locked_lines": _lines([["", "O portão norte está trancado desde que o Império fechou a estrada da floresta."]])})
	_spawn("from_oficina", Vector2(oficina.x, oficina.y + 1), F.DOWN)
	_spawn("from_loja", Vector2(loja.x, loja.y + 1), F.DOWN)
	_spawn("from_estalagem", Vector2(estalagem.x, estalagem.y + 1), F.DOWN)
	_spawn("from_relojoaria", Vector2(relojoaria.x, relojoaria.y + 1), F.DOWN)
	_spawn("from_south", Vector2(24, 29), F.UP)
	_spawn("back_door", Vector2(45, 12), F.LEFT)
	_npc("Pip", Vector2(22, 17), VILLAGERS2, 0, F.DOWN, {"display_name": "Pip", "dialogue_set": _dialogue("p_pip"),
		"hide_if_flag": &"slept"})
	_npc("Olavo", Vector2(26, 28), VILLAGERS2, 1, F.LEFT, {"display_name": "Guarda Olavo",
		"dialogue_set": _dialogue("p_olavo"), "hide_if_flag": &"empire_arrived"})
	_npc("Ilse", Vector2(12, 26), VILLAGERS2, 2, F.DOWN, {"display_name": "Velha Ilse", "dialogue_set": _dialogue("p_ilse")})
	# The Empire (morning after the dinner).
	var empire := {"show_if_flag": &"empire_arrived"}
	_npc("Voss", Vector2(26, 15), VOSS_SHEET, 0, F.RIGHT, {"display_name": "General Voss",
		"show_if_flag": &"empire_arrived", "hide_if_flag": &"voss_fought"})
	for s: Array in [["SoldierSouth", Vector2(24, 21), F.UP], ["SoldierSouth2", Vector2(25, 21), F.UP],
			["SoldierNorth", Vector2(25, 9), F.DOWN],
			["SoldierWest", Vector2(17, 15), F.RIGHT], ["SoldierSquare", Vector2(27, 13), F.DOWN]]:
		_npc(s[0], s[1], VILLAGERS2, 4, s[2], {"display_name": "Soldado Imperial", "dialogue_set": _dialogue("p_soldier"),
			"show_if_flag": &"empire_arrived", "hide_if_flag": &"escaped"})
	_npc("Eco", Vector2(38, 15), ECO_SHEET, 0, F.LEFT, {"display_name": "Eco",
		"show_if_flag": &"empire_arrived", "hide_if_flag": &"voss_fought"})
	_npc("GerdSquare", Vector2(-4, -4), GERD_SHEET, 0, F.LEFT, {"display_name": "Mestre Gerd",
		"show_if_flag": &"empire_arrived", "hide_if_flag": &"voss_fought"})
	# The imperial airship hovers over the square; the workshop lies in ruins after the escape.
	_gated_sprite("Airship", "res://assets/sprites/objects/obj_airship.png", Vector2(28, 7), &"empire_arrived", &"prologue_done", 2.0, 30)
	_gated_sprite("WorkshopRuins", "res://assets/sprites/objects/obj_workshop_ruins.png", Vector2(40, 13.5), &"escaped", &"", 0.0, 0)
	_trigger("VossScene", Vector2(34, 14), Vector2(1, 13), "p8_voss", empire)
	_trigger("Escape", Vector2(45, 12), Vector2(1, 1), "p9_escape", {"autostart": true, "show_if_flag": &"escaped"})
	_finish("vila_caldeira")


# ---------- Estrada do Sul ----------

func _estrada() -> void:
	_new_grid(24, 30, ".")
	_border("T")
	_fill(10, 0, 13, 29, ",")
	_fill(9, 8, 9, 12, "f")
	_fill(14, 8, 14, 12, "f")
	_put("16,14:x 17,14:x 16,15:o 3,4:T 5,9:T 19,6:T 20,20:T 4,22:T 6,26:T 18,25:T 2,15:k 21,13:k 7,18:k")
	_put("15,3:s 16,3:s 6,13:s 7,13:s 17,22:s")
	_begin("EstradaSul", "vila", MUSIC_VILA)
	_object("HiddenChest", Vector2(18, 15), MapObject.Kind.CHEST, TIL_JUNK, TileLegends.JUNKYARD_OBJECTS["chest"],
		{"tile_used": TileLegends.JUNKYARD_OBJECTS["chest_open"], "flag": &"chest_road", "item_id": &"potion", "amount": 1,
		"money": 50})
	_enemy("Slimes", Vector2(12, 20), ["oil_slime", "oil_slime"], {"patrol_distance": 20.0})
	_spawn("from_vila", Vector2(11.5, 1), F.DOWN)
	_spawn("from_junkyard", Vector2(11.5, 28), F.UP)
	_warp("ToVila", Vector2(10, 0), "vila_caldeira", "from_south", 4)
	_warp("ToJunkyard", Vector2(10, 29), "ferro_velho_1", "from_north", 4)
	_trigger("RoadTutorial", Vector2(11.5, 4), Vector2(4, 1), "p3_road")
	_finish("estrada_sul")


# ---------- Ferro-Velho do Sul ----------

func _ferro1() -> void:
	_new_grid(36, 24, ".")
	_border("#")
	_fill(17, 0, 18, 0, ".")
	_fill(35, 11, 35, 12, ".")
	_fill(5, 5, 9, 8, "#")
	_fill(24, 4, 29, 7, "#")
	_fill(8, 15, 12, 19, "#")
	_fill(22, 15, 27, 20, "#")
	_put("15,10:o 16,10:o 20,17:o 3,3:t 31,20:t 30,12:a 14,4:k 15,4:h 4,12:x 5,12:b 31,3:g 2,19:W 13,21:n 19,6:j")
	_begin("FerroVelho1", "junkyard", MUSIC_JUNKYARD)
	_root.aether_factor = 0.8
	_object("Chest", Vector2(4, 20), MapObject.Kind.CHEST, TIL_JUNK, TileLegends.JUNKYARD_OBJECTS["chest"],
		{"tile_used": TileLegends.JUNKYARD_OBJECTS["chest_open"], "flag": &"chest_junk1", "item_id": &"potion", "amount": 2})
	_enemy("Rats", Vector2(12, 11), ["gear_rat", "gear_rat"])
	_enemy("Crow", Vector2(27, 11), ["scrap_crow"])
	_enemy("SlimeRat", Vector2(18, 21), ["oil_slime", "gear_rat"])
	_spawn("from_north", Vector2(17.5, 1), F.DOWN)
	_spawn("from_east", Vector2(34, 11.5), F.LEFT)
	_warp("ToRoad", Vector2(17, 0), "estrada_sul", "from_junkyard", 2)
	_warp("ToShed", Vector2(35, 11), "ferro_velho_2", "from_west", 1, {})
	_root.get_node("ToShed").position = c(35, 11.5)
	_trigger("Enter", Vector2(17.5, 3), Vector2(2, 1), "p4_enter")
	_finish("ferro_velho_1")


func _ferro2() -> void:
	_new_grid(36, 22, "_")
	_border("Z")
	_fill(0, 10, 0, 11, "_")
	_fill(4, 6, 20, 6, "c")
	_cell_set(21, 6, "e")
	_fill(1, 18, 34, 20, "Z")
	_fill(17, 18, 17, 21, "_")
	_fill(20, 10, 23, 14, "I")
	_put("8,12:X 12,12:X 28,14:X 30,14:X 32,8:k 33,8:h 3,2:b 4,2:b 26,2:x 10,16:g 25,16:t 14,3:v 5,14:y")
	_begin("FerroVelho2", "junkyard", MUSIC_JUNKYARD)
	_root.aether_factor = 0.8
	var obj := TileLegends.JUNKYARD_OBJECTS
	_object("Lever", Vector2(3, 6), MapObject.Kind.LEVER, TIL_JUNK, obj["lever_off"], {"tile_used": obj["lever_on"],
		"flag": &"conveyor_on", "cutscene": load("res://data/cutscenes/p4_lever.tres"),
		"lines": _lines([["", "Uma alavanca enferrujada ligada à esteira. Kael puxa com toda a força..."]])})
	_object("ScrapBlock", Vector2(17, 18), MapObject.Kind.BLOCK, TIL_JUNK, obj["scrap_block"], {"flag": &"conveyor_on",
		"lines": _lines([["Kael", "Um bloco de sucata prensada. Pesado demais pra empurrar... mas a esteira ali em cima conseguiria.", POR_KAEL]])})
	_object("Boiler", Vector2(30, 4), MapObject.Kind.SAVE_POINT, TIL_JUNK, obj["boiler"], {
		"cutscene": load("res://data/cutscenes/p4_boiler.tres"),
		"lines": _lines([["", "A velha caldeira ainda guarda um calor gostoso. O grupo descansa um pouco."]])})
	_npc("Fuligem", Vector2(33, 16), VILLAGERS2, 5, F.LEFT, {"display_name": "Fuligem", "dialogue_set": _dialogue("p_cat"),
		"show_if_flag": &"quest_q_cat", "hide_if_flag": &"cat_found"})
	_enemy("Spider", Vector2(10, 15), ["bolt_spider"])
	_enemy("CrowRat", Vector2(26, 9), ["scrap_crow", "gear_rat"])
	_enemy("SlimeSpider", Vector2(14, 3), ["oil_slime", "bolt_spider"], {"patrol_distance": 16.0})
	_spawn("from_west", Vector2(1, 10.5), F.RIGHT)
	_spawn("from_south", Vector2(17, 20), F.UP)
	_warp("ToYard", Vector2(0, 10), "ferro_velho_1", "from_east")
	_root.get_node("ToYard").position = c(0, 10.5)
	_warp("ToWell", Vector2(17, 21), "ferro_velho_3", "from_north")
	_finish("ferro_velho_2")


func _ferro3() -> void:
	_new_grid(30, 26, ",")
	_border("#")
	_fill(1, 12, 28, 24, ":")
	_fill(0, 12, 0, 25, "R")
	_fill(29, 12, 29, 25, "R")
	_fill(0, 25, 29, 25, "R")
	_fill(14, 0, 15, 0, ",")
	_put("4,4:1 5,4:2 4,5:3 5,5:4 22,6:1 23,6:2 22,7:3 23,7:4 6,16:1 7,16:2 6,17:3 7,17:4 21,18:1 22,18:2 21,19:3 22,19:4")
	_put("10,14:i 19,14:i 10,20:i 19,20:i 0,16:Q 29,18:Q 0,21:Q 14,24:O 2,9:L 26,3:- 27,3:- 12,9:n 17,10:v")
	_begin("FerroVelho3", "junkyard", MUSIC_JUNKYARD)
	_root.aether_factor = 0.9
	_object("Chest", Vector2(4, 21), MapObject.Kind.CHEST, TIL_JUNK, TileLegends.JUNKYARD_OBJECTS["chest"],
		{"tile_used": TileLegends.JUNKYARD_OBJECTS["chest_open"], "flag": &"chest_junk3", "item_id": &"gem_fire"})
	_enemy("Sentinel", Vector2(14, 9), ["brass_sentinel", "oil_slime"], {"patrol_distance": 12.0})
	_enemy("Lamp", Vector2(8, 18), ["wander_lamp"])
	_enemy("SpiderLamp", Vector2(24, 14), ["bolt_spider", "wander_lamp"])
	_spawn("from_north", Vector2(14.5, 1), F.DOWN)
	_spawn("from_below", Vector2(14, 23), F.UP)
	_warp("ToShed", Vector2(14, 0), "ferro_velho_2", "from_south", 2)
	_warp("Ladder", Vector2(14, 24), "camara", "from_north")
	_trigger("Tech", Vector2(14.5, 4), Vector2(2, 1), "p4_tech")
	_finish("ferro_velho_3")


func _camara() -> void:
	_new_grid(24, 16, ":")
	_border("R")
	_fill(0, 1, 23, 1, "R")
	_put("0,5:Q 23,5:Q 0,10:Q 23,10:Q 6,0:Q 17,0:Q 5,5:i 18,5:i 5,11:i 18,11:i")
	_fill(11, 1, 12, 1, ":")
	_begin("Camara", "junkyard", MUSIC_JUNKYARD)
	_root.aether_factor = 1.2
	_npc("EcoSleeping", Vector2(12, 9), ECO_SHEET, 0, F.DOWN, {"display_name": "???", "hide_if_flag": &"eco_awake",
		"dialogue": _lines([["", "Uma figura de pedra clara e latão, coberta de musgo, sentada como se dormisse."]])})
	_spawn("from_north", Vector2(12, 2), F.DOWN)
	_warp("Up", Vector2(11, 0), "ferro_velho_3", "from_below", 2)
	_trigger("Awakening", Vector2(12, 2), Vector2(1, 1), "p5_eco", {"autostart": true})
	_finish("camara")

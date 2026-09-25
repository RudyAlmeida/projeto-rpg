extends Node
## Autoload "DataRegistry": indexes every data resource by id so saves, shops and the
## inventory can refer to items / characters / skills / techs by name.

const FOLDERS := {
	&"items": "res://data/items",
	&"skills": "res://data/skills",
	&"characters": "res://data/characters",
	&"enemies": "res://data/enemies",
	&"techs": "res://data/techs",
}

var _by_kind := {}  # kind -> {id -> Resource}


func _ready() -> void:
	reload()


func reload() -> void:
	_by_kind.clear()
	for kind: StringName in FOLDERS:
		var table := {}
		for res in _load_folder(FOLDERS[kind]):
			var id: StringName = res.get(&"id")
			if id != &"":
				table[id] = res
		_by_kind[kind] = table


func item(id: StringName) -> ItemData:
	return _by_kind[&"items"].get(id)


func character(id: StringName) -> CombatantData:
	return _by_kind[&"characters"].get(id)


func skill(id: StringName) -> SkillData:
	return _by_kind[&"skills"].get(id)


func all_items() -> Array[ItemData]:
	var out: Array[ItemData] = []
	out.assign(_by_kind[&"items"].values())
	return out


func all_techs() -> Array[DualTechData]:
	var out: Array[DualTechData] = []
	out.assign(_by_kind[&"techs"].values())
	return out


static func _load_folder(path: String) -> Array[Resource]:
	var out: Array[Resource] = []
	if not DirAccess.dir_exists_absolute(path):
		return out
	for file in DirAccess.get_files_at(path):
		# Exported builds list "x.tres.remap"; loading the original name still works.
		file = file.trim_suffix(".remap")
		if file.ends_with(".tres") or file.ends_with(".res"):
			var res := load(path.path_join(file))
			if res:
				out.append(res)
	return out

class_name StatusEffects
extends RefCounted
## Status catalogue (GDD_Combate, section 6). Durations count the affected unit's own turns.

enum Id { POISON, SLEEP, SILENCE, BLIND, PARALYSIS, CONFUSION, PETRIFY, HASTE, SLOW, PROTECT,
	BARRIER, REGEN, OVERHEAT, DISMANTLED }

## name: shown in the UI; tag: 3-letter badge; negative: removable by cures / resisted by
## Spirit; turns: default duration (-1 = until cured / end of battle).
const INFO := {
	Id.POISON: {"name": "Veneno", "tag": "VEN", "negative": true, "turns": 5},
	Id.SLEEP: {"name": "Sono", "tag": "SON", "negative": true, "turns": 3},
	Id.SILENCE: {"name": "Silêncio", "tag": "SIL", "negative": true, "turns": 4},
	Id.BLIND: {"name": "Cegueira", "tag": "CEG", "negative": true, "turns": 4},
	Id.PARALYSIS: {"name": "Paralisia", "tag": "PAR", "negative": true, "turns": 1},
	Id.CONFUSION: {"name": "Confusão", "tag": "CNF", "negative": true, "turns": 3},
	Id.PETRIFY: {"name": "Petrificação", "tag": "PET", "negative": true, "turns": 3},
	Id.HASTE: {"name": "Pressa", "tag": "PRS", "negative": false, "turns": 5},
	Id.SLOW: {"name": "Lentidão", "tag": "LEN", "negative": true, "turns": 5},
	Id.PROTECT: {"name": "Proteção", "tag": "PRT", "negative": false, "turns": 5},
	Id.BARRIER: {"name": "Barreira", "tag": "BAR", "negative": false, "turns": 5},
	Id.REGEN: {"name": "Regeneração", "tag": "REG", "negative": false, "turns": 5},
	Id.OVERHEAT: {"name": "Sobreaquecido", "tag": "SOB", "negative": true, "turns": 2},
	Id.DISMANTLED: {"name": "Desmontado", "tag": "DES", "negative": true, "turns": -1},
}

const POISON_PERCENT := 6.0
const REGEN_PERCENT := 6.0
const PROTECT_MULT := 0.67
const BLIND_HIT_PENALTY := 50.0
const OVERHEAT_ATTACK_MULT := 1.5
const OVERHEAT_TAKEN_MULT := 1.25
const DISMANTLED_DEFENSE_MULT := 0.5


static func display_name(id: Id) -> String:
	return INFO[id]["name"]


static func tag(id: Id) -> String:
	return INFO[id]["tag"]


static func is_negative(id: Id) -> bool:
	return INFO[id]["negative"]


static func default_turns(id: Id) -> int:
	return INFO[id]["turns"]


## Statuses that stop the unit from choosing actions.
static func blocks_action(id: Id) -> bool:
	return id == Id.SLEEP or id == Id.PARALYSIS or id == Id.PETRIFY

class_name ItemData
extends Resource
## Any item: consumables (used in battle / menu), equipment, gems and key items.
## Equipment and gem fields are read by the equipment and gem systems.

enum Kind { CONSUMABLE, WEAPON, ARMOR, ACCESSORY, GEM, KEY }

@export var id: StringName
@export var display_name := ""
@export var kind := Kind.CONSUMABLE
## Column/row index in assets/ui/ico_items.png (4 columns).
@export var icon_index := 0
@export var price := 0
@export_multiline var description := ""

@export_group("Consumable")
@export var battle_usable := true
@export var field_usable := true
@export var target := SkillData.Target.ALLY
@export var heal_hp := 0
@export var heal_mp := 0
## Revives a KO'd ally with this share of max HP (0 = no revive).
@export_range(0.0, 1.0) var revive_percent := 0.0
## StatusEffects.Id values removed on use.
@export var cures: Array[int] = []

@export_group("Equipment")
## Weapon power added to Strength for physical damage.
@export var attack := 0
## Flat bonuses by stat name (CombatantData.STATS), e.g. {"defense": 4}.
@export var stat_bonuses: Dictionary = {}
## Characters who can equip it (CombatantData ids). Empty = everyone.
@export var equippable_by: Array[StringName] = []
## Gem sockets on this piece of equipment (see the gem system).
@export var gem_slots := 0

@export_group("Gem")
## Skills granted while equipped, unlocked as the gem levels up (index = level − 1).
@export var gem_skills: Array[SkillData] = []
## Stat bonuses per gem level (applied × level).
@export var gem_stat_bonuses: Dictionary = {}
## Special gem effects understood by the battle: "timing_window" (multiplier), "element_blade".
@export var gem_effects: Dictionary = {}
## AP (Pontos de Éter) needed per level.
@export var gem_ap_per_level: Array[int] = [20, 60]


func icon_region() -> Rect2:
	return Rect2((icon_index % 4) * 16, (icon_index / 4) * 16, 16, 16)


func is_equipment() -> bool:
	return kind == Kind.WEAPON or kind == Kind.ARMOR or kind == Kind.ACCESSORY


func can_equip(character_id: StringName) -> bool:
	return equippable_by.is_empty() or character_id in equippable_by

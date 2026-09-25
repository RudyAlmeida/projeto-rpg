class_name CombatantData
extends Resource
## Static definition of a hero or enemy: stats, commands, affinities and battle sprite.

@export var display_name := ""

@export_group("Sprite")
@export var battle_sheet: Texture2D
@export var frame_size := Vector2i(64, 64)
## Column of `battle_sheet` used while standing in battle (heroes: 3 = battle stance).
@export var idle_frame := 3
## Optional extra columns (-1 = reuse idle): enemies have attack / hurt frames.
@export var attack_frame := -1
@export var hurt_frame := -1
## Battle sprites must face the other side: heroes right, enemies left.
@export var flip_h := false

@export_group("Stats")
@export var max_hp := 100
@export var max_mp := 0
@export var strength := 10
@export var weapon_power := 0
@export var magic := 5
@export var defense := 5
@export var spirit := 5
@export var speed := 20
@export var luck := 5
@export var precision := 10
@export var evasion := 5

@export_group("Commands")
@export var skills: Array[SkillData] = []
## Enemy AI: chance weight of each entry in `skills` (same order). Heroes ignore it.
@export var ai_weights: Array[int] = []

@export_group("Affinities")
## SkillData.Element -> DamageFormula.Affinity. Missing elements are NORMAL.
@export var affinities: Dictionary = {}

@export_group("Rewards")
@export var xp_reward := 0
@export var money_reward := 0


func affinity_for(element: SkillData.Element) -> DamageFormula.Affinity:
	return affinities.get(element, DamageFormula.Affinity.NORMAL)

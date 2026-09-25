class_name CombatantData
extends Resource
## Static definition of a hero or enemy: stats, commands, affinities and battle sprite.

## How the character's timed press works (GDD 4.2).
enum TimingStyle { RING, HOLD, CHANNEL }
## What a PERFECT press adds on top of the damage multiplier (GDD 4.2).
enum PerfectBonus { NONE, EXTRA_HIT, MAGIC_REFUND, STEAM, GUARD_ALL }

const STATS: Array[StringName] = [&"max_hp", &"max_mp", &"strength", &"magic", &"defense",
	&"spirit", &"speed", &"luck", &"precision", &"evasion"]

@export var id: StringName
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
## Portrait for menus (optional).
@export var portrait: Texture2D

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
## Heroes: points gained per level for each name in STATS (fractions accumulate:
## stat = base + floor(growth × (level − 1))).
@export var growth: Dictionary = {}

@export_group("Commands")
@export var skills: Array[SkillData] = []
## Special move unlocked when the Aether bar is full (heroes).
@export var special: SkillData
@export var timing_style := TimingStyle.RING
@export var perfect_bonus := PerfectBonus.NONE
## Enemy AI rules (GDD 9). Empty = weighted random over `skills` / `ai_weights`.
@export var ai_rules: Array[AIRule] = []
## Fallback AI: chance weight of each entry in `skills` (same order).
@export var ai_weights: Array[int] = []

@export_group("Nature")
## Metal enemies: weak to Kael's Resonance (Dismantled).
@export var mechanical := false
## StatusEffects.Id values this combatant ignores.
@export var status_immunities: Array[int] = []
## Bosses cannot be fled from.
@export var is_boss := false

@export_group("Affinities")
## SkillData.Element -> DamageFormula.Affinity. Missing elements are NORMAL.
@export var affinities: Dictionary = {}

@export_group("Rewards")
@export var xp_reward := 0
@export var money_reward := 0
## Pontos de Éter for gems.
@export var ap_reward := 0
## Item id -> drop chance in percent.
@export var drops: Dictionary = {}


func affinity_for(element: SkillData.Element) -> DamageFormula.Affinity:
	return affinities.get(element, DamageFormula.Affinity.NORMAL)

class_name AIRule
extends Resource
## One enemy AI rule (GDD 9): condition → skill → target, with priority and weight.
## The highest priority whose condition holds wins; ties are drawn by weight.

enum Condition { ALWAYS, SELF_HP_BELOW, ALLY_DOWN, ANY_HERO_WITHOUT_STATUS, EVERY_N_TURNS }
enum TargetMode { RANDOM, LOWEST_HP, HIGHEST_THREAT, WITHOUT_STATUS, SELF, ALL }

@export var priority := 1
@export var condition := Condition.ALWAYS
## SELF_HP_BELOW: HP percent. EVERY_N_TURNS: N. ANY_HERO_WITHOUT_STATUS: StatusEffects.Id.
@export var value := 0.0
@export var skill: SkillData
@export var target_mode := TargetMode.RANDOM
@export var weight := 1
## Optional line shown before the action (boss tells, GDD 9).
@export var tell := ""

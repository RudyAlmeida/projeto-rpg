# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**O Coração de Éter** (working title): a turn-based JRPG inspired by Final Fantasy VII, Final Fantasy X and Chrono Trigger, built in **Godot 4.7.2 / GDScript**. Classic fantasy + steampunk world, 16-bit pixel art, native resolution 640×360.

- The user is the **creative director** and speaks **Portuguese (pt-BR)** — reply in Portuguese. Identifiers and code comments are in English; in-game text is Portuguese.
- **Division of work:** Claude writes all code, scenes, data and tooling. **Codex generates all image assets** (sprites, tilesets, portraits, icons, UI). **Suno generates music and SFX** (via the `suno-music` MCP server). Claude orchestrates both, then post-processes and integrates their output.
- Decisions are approved by the user; don't change approved design without asking.

## Design documents (source of truth)

`docs/*.docx` are **generated** by `tools/docs/build_*.js` — edit the script, never the .docx. The user reads them in LibreOffice.

| Document | Script | Content |
|---|---|---|
| `Planejamento_Projeto_RPG.docx` | `build_planning.js` | Phase control (F0–F6 task tables), decision log D-01..D-09, asset log, risks, version history |
| `Historia_O_Coracao_de_Eter.docx` | `build_story.js` | Story bible: world, party of 7, villains, acts, endings matrix |
| `Guia_de_Estilo.docx` | `build_style.js` | Art style guide (approved v1.0) |
| `GDD_Combate.docx` | `build_combat.js` | Combat design (approved v1.0): CTB formulas, timing, status, gems |

After meaningful progress, update `build_planning.js` (task status, asset log, history row, version) and regenerate. New docs should use the shared helpers in `tools/docs/lib.js` (static TOC, tables kept together — LibreOffice does not refresh TOC fields).

## Commands

Git is installed but not on this shell's PATH: prefix with `$env:Path = "C:\Program Files\Git\cmd;" + $env:Path`.

```powershell
# All tests (GUT 9.7.1, config game/.gutconfig.json) — exit code 0 = pass
./tools/run_tests.ps1

# Single test script / single test
& "D:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path game -s res://addons/gut/gut_cmdln.gd -gselect=test_turn_queue -gunit_test_name=test_haste

# Import assets (needed after adding files, before running headless)
& "D:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path game --import

# Render the running game to PNG frames + WAV (visual/audio check without a window)
& "D:\Godot\Godot_v4.7.2-stable_win64_console.exe" --path game --write-movie <dir>\frame.png --fixed-fps 10 --quit-after 3

# Scripted screenshot of real gameplay: write a temporary game/tools/_probe.gd (extends Node) +
# _probe.tscn, run it AS A SCENE (autoloads only exist then; `-s` SceneTree scripts can't see them),
# save get_viewport().get_texture().get_image(), then delete the probe files. If the probe triggers
# SceneManager.change_scene, make the map the current_scene first or the probe itself gets freed.
& "D:\Godot\Godot_v4.7.2-stable_win64_console.exe" --path game res://tools/_probe.tscn -- <output dir>

# Regenerate input map after editing ACTIONS in game/tools/setup_input_map.gd
& "D:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path game -s res://tools/setup_input_map.gd

# Regenerate a document (fails with EBUSY while the user has it open in LibreOffice — ask them to close it)
cd tools/docs; node build_planning.js "D:\Projeto RPG\docs\Planejamento_Projeto_RPG.docx"
```

`tools/*/node_modules` are gitignored; run `npm install` in `tools/docs`, `tools/art` or `tools/codex-cli` if missing.

## Asset pipeline

**Images (Codex):**
1. Prompt = the fixed block in `game/assets/_prompts/style_base.md` + an asset block (see `chr_kael_ref.md` for the pattern). Save each asset's prompt in `game/assets/_prompts/`.
2. Generate with `tools/gen_image.ps1 -Prompt ... -OutPath assets/_source/<name>_raw_v1.png` (Codex CLI 0.156.1 in `tools/codex-cli`), **or** the `codex` MCP server (`codex_generate_image` + poll `codex_image_status`; it may return 2 variants).
3. Always look at the result: Codex may return a transparent background instead of magenta, and once corrupted an image by "fixing" it. Untouched originals are in `~/.codex/generated_images/`.
4. Convert: `node tools/art/pixelize.mjs <raw.png> game/assets/sprites/characters/<name>/<name>.png` — removes background (magenta or alpha), splits poses into rows × columns (single row for reference sheets, grids for animations), downsamples to 56 px tall in 64×64 cells (scale taken from the first pose, shared by all), locks to the palette, writes a 6× `_preview.png`. 56 px matches Codex's natural pixel grid; smaller heights erase faces. After changing the tool, re-run it on the approved `_source` images and compare hashes with the committed sprites.
   For animations, attach the approved reference image (`referenceImages` on the MCP tool) so the character stays identical — see `chr_kael_walk.md`.
5. Palette: `game/assets/palette/velmora32.hex` (32 colours; index 0 = outline; cyan is reserved for Aether/magic).

`game/assets/_source/` has a `.gdignore` — raw images are versioned but not imported by Godot.

**Audio (Suno via `suno-music` MCP):** generation spends the user's credits — ask first. Tasks are async (poll `suno_get_task`, 1–5 min); each request returns 2 variants. Only `chirp-v5-5` accepts `duration`. Store request args in `game/assets/_prompts/*.json`, audio in `game/assets/audio/music/`. The user's paid account grants commercial rights.

## Code architecture

- `game/` is the Godot project root (`res://`). Planned layout (partly empty yet): `scripts/{core,battle,world,ui,systems}`, `scenes/`, `data/` (Resources for characters, enemies, items, skills), `autoload/` (GameState, SceneManager, SaveManager, AudioManager, EventBus, DataRegistry, DialogueManager), `tests/unit/`.
- **Combat core is pure logic, separate from scenes** so it is unit-testable:
  - `scripts/battle/turn_queue.gd` (`TurnQueue`) — CTB: lowest counter acts; delay = `floor(3000/(VEL+20))` × action weight (2 fast / 3 normal / 4 heavy) × speed modifier; `preview()` gives the upcoming order for the UI "ghost"; `swap()` lets a reserve member take over the counter and act immediately.
  - `scripts/battle/damage_formula.gd` (`DamageFormula`) — static formulas (physical, magical, heal, timing, elements, hit, crit). Tests assert the worked examples from the GDD.
  - `scripts/battle/combat_balance.gd` (`CombatBalance`) — every tunable number, defaults = approved GDD. Change numbers here, not in formulas.
  - `scripts/battle/battle.gd` (`Battle`) — the rules without nodes: `start()`, `next_turn()`, `resolve(actor, skill, target, timing)` → `ActionResult`, `choose_enemy_action()`, `outcome()`. Data: `SkillData` / `CombatantData` resources in `data/skills`, `data/characters`, `data/enemies` (typed arrays in .tres need the element script as `Array[ExtResource("<skill_data.gd id>")]`).
  - `BattleScene` drives `Battle` visually: `BattlerView` (lunge/return, hurt, KO), `TimingPrompt` (gold ring closing on the impact point; `auto_timing` skips input for tests), `BattleUI` (built in code). Hero commands come through `command_requested` → `submit_command()` (menu or tests). `FieldMap.start_battle(FieldEnemy)` runs it on the map at the camera centre; defeat retries.
  - Battle tests set `Engine.time_scale = 8` and `auto_timing`; reset time_scale in `after_each`.
  - Block B: `StatusEffects` catalogue (durations tick in `Battle.begin_turn`), `resolve_action` (multi-target), `use_item`, Aether bar on `BattleUnit`/`PartyMember`, per-hero `TimingStyle` (RING/HOLD/CHANNEL) and `PerfectBonus`, `AIRule` rules, `swap`, `DualTechData` techs, `try_flee`, `aether_factor`. Hero actions reach `BattleScene` as dictionaries (`submit_action`).
- **Data is generated**: `game/tools/build_data.gd` (run `godot --headless --path game -s res://tools/build_data.gd`) writes `data/**/*.tres` with ResourceSaver. Edit the script, not the .tres. `DataRegistry` autoload indexes resources by `id`.
- `tools/audio/suno_gen.mjs <args.json> <outDir> <baseName>` generates Suno music (submit, poll, download all variants). Args files live in `game/assets/_prompts/*.json`.
- Combat is **hybrid CTB + timed button presses** (Perfect ×1.3 / Good ×1.1 attack; ×0.5 / ×0.75 damage taken on defense; missing never penalises), fought **on the field map** (no separate battle screen), 3 active + reserves.
- Input actions (keyboard + gamepad, device -1) are defined in `game/tools/setup_input_map.gd`; `confirm` and `action_timing` share keys by default but stay separate for remapping.
- Main scene is `scenes/maps/test_map.tscn` (Phase 1 prototype). Maps use `FieldMap` (root script; children `Map` = `AsciiMap`, `Player`, optional `Spawns/<id>` = `SpawnPoint`, `Warp` Area2D doors). `AsciiMap` builds a TileMapLayer + collision from a text layout (`P`/`p` = default spawn on grass/floor). `Player` uses `idle_sheet` (reference sheet: columns down/left/up) and `walk_sheet` (rows down/left/up × 4 frames); right = left mirrored. `scenes/main/main.tscn` is only an asset-preview scene.
- Autoloads: `DialogueManager` (`play(lines)` awaits the text box; `DialogueLine` resources), `SceneManager` (`change_scene(path, spawn_id)` with fade; maps call `take_pending_spawn()`), `AudioManager` (`play_music()` keeps the same track playing across rooms). `Player.can_move()` is false during dialogue or transitions.
- NPCs (`scenes/characters/npc.tscn`, `NPC`) have `idle_sheet`, `facing` and a `dialogue` array; the player's `InteractRay` + `confirm` calls `interact()` on whatever is in front.
- UI text uses `assets/fonts/pixelify_ui.tres` (Pixelify Sans, OFL; ligatures off because "fi" renders unreadably at pixel size, wider spaces; font imported with antialiasing/hinting off).
- Tests: inside GUT `get_tree().current_scene` is null, so `SceneManager.change_scene` just adds the new map next to the runner — unload it in `after_each` (`get_tree().unload_current_scene()`). Loops that wait on game state must be bounded (an unbounded `while box.is_open()` once hung the whole suite).
- Known engine quirk: any scene that played an MP3 prints "2 ObjectDB instances were leaked at exit" on quit (reproduced with a minimal probe even after stop()+free). Harmless; not our bug.
- GDScript: static typing everywhere, `class_name` for reusable classes, signals named in past tense. Pixel-art rendering: nearest filter, integer scaling, snap to pixel.

## Current status

Phase 0 (pre-production) essentially complete; Phase 1 (technical prototype: walk a map, talk to an NPC, fight a battle) has started — see the F1 table in the planning doc for the next tasks.

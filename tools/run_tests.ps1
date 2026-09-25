# Runs all GUT tests headless (config: game/.gutconfig.json). Exit code 0 = all passed.
param([string]$Godot = "D:\Godot\Godot_v4.7.2-stable_win64_console.exe")
$game = Join-Path $PSScriptRoot "..\game" | Resolve-Path
# Import first so class_name caches (GutTest, game classes) are up to date.
& $Godot --headless --path $game --import | Out-Null
& $Godot --headless --path $game -s res://addons/gut/gut_cmdln.gd
exit $LASTEXITCODE

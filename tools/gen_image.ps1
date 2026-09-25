param(
	[Parameter(Mandatory)][string]$Prompt,     # image spec (English)
	[Parameter(Mandatory)][string]$OutPath,    # path relative to game/, e.g. assets/sprites/chr_hero_sheet.png
	[string]$Model = "gpt-5.5"
)
# Generates one image through Codex CLI (built-in image_gen) and copies it into the Godot project.
$codex = Join-Path $PSScriptRoot "codex-cli\node_modules\@openai\codex-win32-x64\vendor\x86_64-pc-windows-msvc\bin\codex.exe"
$game = Join-Path $PSScriptRoot "..\game" | Resolve-Path
$task = @"
Use your built-in image generation tool (imagegen skill, built-in mode) to create ONE image, then copy the generated PNG to exactly:
$OutPath
(relative to the current working directory). Do not overwrite an existing file; do not modify any other files.

$Prompt

When done, reply with the saved path, the image width and height in pixels, and the final prompt used.
"@
& $codex exec -m $Model --skip-git-repo-check --sandbox workspace-write -C $game $task
exit $LASTEXITCODE

# Projeto RPG

JRPG por turnos inspirado em Final Fantasy VII, Final Fantasy X e Chrono Trigger, feito em Godot 4.7.2.

## Estrutura

- `game/` — projeto Godot (abrir `game/project.godot`)
- `docs/` — planejamento e controle de fases (`Planejamento_Projeto_RPG.docx`)
- `tools/` — ferramentas de apoio
  - `gen_image.ps1` — gera imagens via Codex CLI e salva dentro de `game/`

## Configuração

1. Godot 4.7.2 (stable).
2. Codex CLI local para geração de imagens:
   ```powershell
   cd tools/codex-cli
   npm install
   ```
3. Gerar uma imagem:
   ```powershell
   ./tools/gen_image.ps1 -Prompt "<descrição>" -OutPath "assets/sprites/nome.png"
   ```

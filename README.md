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
3. Gerar uma imagem (bloco de `game/assets/_prompts/style_base.md` + descrição do asset):
   ```powershell
   ./tools/gen_image.ps1 -Prompt "<prompt>" -OutPath "assets/_source/nome_raw.png"
   ```
4. Converter em sprite (fundo, grade de pixels, paleta Velmora 32):
   ```powershell
   cd tools/art; npm install; cd ../..
   node tools/art/pixelize.mjs game/assets/_source/nome_raw.png game/assets/sprites/.../nome.png
   ```
5. Documentos (`docs/`) são gerados por `tools/docs/build_*.js` (`cd tools/docs; npm install`).

# chr_kael_walk — ciclo de caminhada do Kael

- Referência enviada: `assets/_source/chr_kael_ref_raw_v1.png`
- Bruto: `assets/_source/chr_kael_walk_raw_v1.png`
- Sprite: `assets/sprites/characters/kael/chr_kael_walk.png` (3 linhas × 4 quadros, 64×64)
- Ferramenta: ponte MCP do Codex com imagem de referência, 2026-09-24

Prompt = bloco de `style_base.md` + o bloco abaixo:

```text
Asset type: walk-cycle sprite sheet for the protagonist, to be converted into in-game sprites.
Reference: the attached image is the official reference sheet of KAEL. Copy his design EXACTLY: same face, spiky navy hair, brass goggles on the forehead, scarlet scarf, brown leather armor over navy tunic, cream trousers, brown boots, workshop gloves, gear-blade sword carried on his back. Same proportions, same colors, same pixel scale as the reference.
Composition: a strict grid of 3 rows x 4 columns, every cell the same size, lots of empty background between cells, all frames of a row standing on the same baseline.
Row 1: walking DOWN (towards the viewer). Row 2: walking LEFT (side view, facing left). Row 3: walking UP (back view, gear-blade visible).
Columns (4-frame walk cycle, classic 16-bit JRPG style): 1) left foot forward, 2) passing pose (legs together, body 1 pixel higher), 3) right foot forward, 4) passing pose again. Arms swing opposite to the legs. The scarf trails slightly.
Pixel scale: each frame is a small native sprite about 40 pixels wide and 56 pixels tall, upscaled with nearest-neighbour so each art pixel is a large perfectly square block.
```

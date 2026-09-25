# npc_villagers — lojista e estalajadeira de Vila Caldeira

- Bruto: `assets/_source/npc_villagers_raw_v1.png`
- Sprites: `assets/sprites/characters/villagers/npc_villagers.png` (linha 1: lojista, linha 2: estalajadeira; colunas baixo/esquerda/cima/acenando)
- Ferramenta: ponte MCP do Codex, 2026-09-25

Prompt = bloco de `style_base.md` + o bloco abaixo:

```text
Asset type: NPC reference sheet for two townsfolk of a steampunk frontier workshop town, to be converted into in-game sprites.
Composition: a strict grid of 2 rows x 4 columns, same scale, same baseline per row, lots of empty background between figures.
Row 1 — MERCHANT: plump middle-aged man, brown bowler hat with brass goggles on the brim, curly brown moustache, green vest over a cream shirt with rolled sleeves, a small brass monocle, brown trousers.
Row 2 — INNKEEPER: cheerful woman in her forties, auburn hair in a bun with a pencil in it, rosy cheeks, dark red dress with a cream apron, holding a steaming mug in the waving pose.
Columns for both rows: 1) facing down/front, 2) facing left/side, 3) facing up/back, 4) facing down/front waving hello.
Pixel scale: draw each figure as a small native sprite about 36 pixels wide and 52 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block.
```

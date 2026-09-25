# enm_brass_sentinel — Sentinela de Latão (inimigo mecânico)

- Bruto: `assets/_source/enm_brass_sentinel_raw_v1.png`
- Sprite: `assets/sprites/enemies/enm_brass_sentinel.png` (4 quadros)
- Ferramenta: ponte MCP do Codex, 2026-09-25

Prompt = bloco de `style_base.md` + o bloco abaixo:

```text
Asset type: enemy sprite sheet for a JRPG battle, to be converted into in-game sprites.
Subject: BRASS SENTINEL, a small imperial guard automaton patrolling refineries. Barrel-shaped riveted brass body on two short piston legs, one round red glass eye, a small smokestack on its head puffing grey steam, one arm is a spiked club and the other arm a small steam cannon, imperial navy-blue paint chipped on the chest plate with a gear emblem. Mechanical, sturdy, a bit clumsy.
Composition: the SAME robot in 4 frames in one horizontal row, evenly spaced, same scale, same baseline, all facing LEFT (towards the heroes): 1) idle, 2) idle with steam puff (breathing), 3) attacking — swinging the spiked club forward to the left, 4) hurt — sparks flying, dented, eye flickering.
Pixel scale: draw each frame as a small native sprite about 36 pixels wide and 40 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty background between frames.
```

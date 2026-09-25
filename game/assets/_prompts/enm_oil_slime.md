# enm_oil_slime — Slime de Óleo (primeiro inimigo)

- Bruto: `assets/_source/enm_oil_slime_raw_v1.png`
- Sprite: `assets/sprites/enemies/enm_oil_slime.png` (4 quadros)
- Ferramenta: ponte MCP do Codex, 2026-09-25

Prompt = bloco de `style_base.md` + o bloco abaixo:

```text
Asset type: enemy sprite sheet for a JRPG battle, to be converted into in-game sprites.
Subject: OIL SLIME, a small blob monster made of thick black-brown machine oil leaking from an imperial refinery. Glossy dark body with purple-grey highlights and a rainbow oily sheen on top, a few tiny brass bolts and a small copper gear floating inside the goo, two round white eyes with a grumpy look, oil drips at the base. Cute but menacing, classic 16-bit JRPG slime silhouette.
Composition: the SAME slime in 4 frames in one horizontal row, evenly spaced, same scale, same baseline, all facing LEFT (towards the heroes): 1) idle, 2) idle squashed (wider and lower, breathing), 3) attacking — stretched forward to the left in a lunge, 4) hurt — squished with a pained expression and oil droplets flying.
Pixel scale: draw each frame as a small native sprite about 32 pixels wide and 26 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty background between frames.
```

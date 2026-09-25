# chr_kael_ref — referência oficial do Kael

- Bruto: `assets/_source/chr_kael_ref_raw_v1.png` (2103×748, fundo transparente)
- Sprite: `assets/sprites/characters/kael/chr_kael_ref.png` (4 quadros 64×64, paleta velmora32)
- Conversão: `node tools/art/pixelize.mjs game/assets/_source/chr_kael_ref_raw_v1.png game/assets/sprites/characters/kael/chr_kael_ref.png`
- Ferramenta: `tools/gen_image.ps1` (Codex CLI 0.156.1, gpt-5.5), 2026-09-24

Prompt = bloco de `style_base.md` + o bloco abaixo:

```text
Asset type: official character reference sheet for the protagonist, to be converted into in-game sprites.
Subject: KAEL, 17-year-old apprentice mechanic hero. Spiky dark navy-blue hair, scarlet red scarf, brass goggles pushed up on his forehead, light brown leather armor with small brass rivets over a navy-blue tunic, cream trousers, brown boots, thick workshop gloves, a tool pouch on the belt. Weapon: a "gear-blade" longsword with a small brass piston and gear on the guard, carried on his back.
Composition: the SAME character in 4 poses in one horizontal row, evenly spaced, same scale, all standing on the same baseline: 1) facing down/front, 2) facing left/side, 3) facing up/back (gear-blade visible on back), 4) battle-ready stance holding the gear-blade in both hands.
Pixel scale: draw each pose as a small native sprite about 40 pixels wide and 56 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty magenta between poses.
```

Observação: o Codex devolveu fundo transparente em vez de magenta (a ferramenta aceita os dois).

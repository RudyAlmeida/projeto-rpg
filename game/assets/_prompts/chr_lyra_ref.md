# chr_lyra_ref — referência oficial da Lyra

- Bruto: `assets/_source/chr_lyra_ref_raw_v1.png`
- Sprite: `assets/sprites/characters/lyra/chr_lyra_ref.png`
- Ferramenta: `tools/gen_image.ps1` (Codex CLI 0.156.1), 2026-09-24

Prompt = bloco de `style_base.md` + o bloco abaixo:

```text
Asset type: official character reference sheet for a party member, to be converted into in-game sprites.
Subject: LYRA, 22-year-old druid of the forest kingdom of Sylvaran. Long copper-red hair in a thick braid with a few dry autumn leaves woven in, slightly pointed elven ears, moss-green hooded cloak (hood down) over a brown leather bodice and cream linen dress, soft brown boots, a wooden staff made of a twisted living root topped with a dim, almost extinguished Aether-cyan crystal. Proud, confident expression.
Composition: the SAME character in 4 poses in one horizontal row, evenly spaced, same scale, all standing on the same baseline: 1) facing down/front, 2) facing left/side, 3) facing up/back (braid visible), 4) battle-ready spellcasting stance holding the staff forward with one hand raised.
Pixel scale: draw each pose as a small native sprite about 40 pixels wide and 56 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty background between poses.
```

# chr_eco_ref — referência oficial do Eco

- Bruto: `assets/_source/chr_eco_ref_raw_v1.png`
- Sprite: `assets/sprites/characters/eco/chr_eco_ref.png`
- Ferramenta: ponte MCP do Codex (`codex_generate_image`, adapter.cjs → Codex App Server), 2026-09-24

Prompt = bloco de `style_base.md` + o bloco abaixo:

```text
Asset type: official character reference sheet for a party member, to be converted into in-game sprites.
Subject: ECO, an ancient automaton from a forgotten civilization. Sturdy, slightly bulky chibi robot body, a bit wider than a human hero but the same height. Body made of pale weathered stone plates joined by aged brass and copper fittings; thin glowing gold circuit lines engraved on the stone; a single round glowing Aether-cyan eye in a smooth stone head; small patches of green moss growing in the joints; heavy rounded forearms that can work as shields. Gentle, curious posture — not menacing.
Composition: the SAME character in 4 poses in one horizontal row, evenly spaced, same scale, all standing on the same baseline: 1) facing down/front, 2) facing left/side, 3) facing up/back, 4) battle-ready defensive stance with both forearm shields raised.
Pixel scale: draw each pose as a small native sprite about 40 pixels wide and 56 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty background between poses.
```

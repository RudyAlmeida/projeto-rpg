# Retratos de diálogo (por_*)

Retrato: busto 64×64 nativo, 3/4 olhando para a DIREITA (fica à esquerda da caixa de diálogo).
Sempre gerado com a folha de referência do personagem anexada.

- `por_kael_neutral` — referência: `assets/_source/chr_kael_ref_raw_v1.png`
- `por_gerd_neutral` — referência: `assets/_source/npc_gerd_ref_raw_v1.png`

Prompt = bloco de `style_base.md` + o bloco abaixo (trocar NAME):

```text
Asset type: dialogue portrait for a JRPG text box, to be converted into a 64x64 in-game portrait.
Reference: the attached image is the official reference sheet of NAME. Copy the character design EXACTLY: same face, hair, colors and outfit details.
Subject: head-and-shoulders bust portrait of NAME in 3/4 view looking to the RIGHT, neutral friendly expression, eyes clearly readable.
Composition: ONE single portrait only, centered, bust cut at mid-chest, no frame, no border, no background scenery.
Pixel scale: draw it as a small native portrait about 64 pixels tall and 64 pixels wide, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block.
```

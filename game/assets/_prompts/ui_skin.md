# ui_skin — moldura de janela, cursor e marcadores da interface

Prompt = bloco de `style_base.md` + o bloco abaixo. Fatiado com
`node tools/art/tiles.mjs <raw> <out> --cols 4 --rows 2 --tile 32` e recortado em
`assets/ui/ui_window.png` (célula 0, 9-slice com margem 8 px) e `assets/ui/ui_cursor.png` (células 1–2).

```text
Asset type: JRPG menu interface kit, steampunk brass style (like Final Fantasy VI / Chrono Trigger menus).
Composition: an exact grid of 4 columns x 2 rows of SQUARE cells, every cell the same size, separated by thin straight magenta #FF00FF gutters (gutters and outer margin plain magenta). Each cell is drawn as 32x32 big square pixels.
Cell 1: a small window frame filling the whole cell: dark purple-navy interior (#1f1a2e), a 3-pixel ornate brass border with darker brass shadow line and tiny rivets at the 4 corners; the border must be uniform along the edges so it can be stretched (9-slice).
Cell 2: a menu cursor: a small brass pointing hand (gloved, pointing right) with dark outline, frame A.
Cell 3: the same pointing hand shifted 1 pixel right, frame B (for a bobbing animation).
Cell 4: a small downward brass triangle arrow (continue indicator).
Cell 5: a tiny brass gear icon.
Cell 6: a filled Aether gauge segment: cyan glowing bar piece with brass caps.
Cell 7: an empty gauge segment: dark bar with brass caps.
Cell 8: a small gold star (perfect timing marker).
Avoid: text, letters, characters, soft gradients, background scenery.
```

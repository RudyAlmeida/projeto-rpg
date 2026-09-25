# vfx_battle — efeitos de batalha (8 efeitos × 4 quadros, células de 48 px)

Prompt = bloco de `style_base.md` + o bloco abaixo. Fatiado com
`node tools/art/tiles.mjs <raw> game/assets/vfx/vfx_battle.png --cols 4 --rows 8 --tile 48`.

```text
Asset type: battle visual effects sprite sheet for a JRPG (animation frames).
Composition: an exact grid of 4 columns x 8 rows of SQUARE cells, every cell the same size, separated by thin straight magenta #FF00FF gutters (gutters and outer margin plain magenta). Each row is ONE effect animated over 4 frames from left to right (start, peak, fading, almost gone). Each effect is centred in its cell and fills most of it. Each cell is drawn as 48x48 big square pixels. Effects glow but use flat pixel colours, no soft gradients.
Row 1 SLASH: a white-and-cyan crescent sword slash arc sweeping diagonally.
Row 2 IMPACT: a hit spark star burst, white core with yellow and orange rays.
Row 3 FIRE: a fire burst, orange and red flames with yellow core rising up.
Row 4 ICE: sharp pale blue ice crystals shooting up and shattering.
Row 5 THUNDER: a jagged yellow-white lightning bolt striking down with small sparks.
Row 6 HEAL: green and Aether-cyan sparkles and small plus shapes rising.
Row 7 STEAM: a puff of white steam clouds expanding.
Row 8 EXPLOSION: a big orange explosion with dark smoke and flying scrap bits.
Avoid: characters, text, frames around cells, background scenery.
```

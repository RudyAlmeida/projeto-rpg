# Poses de batalha dos heróis (Kael, Eco, Gerd)

Prompt = bloco de `style_base.md` + o bloco abaixo, com a folha de referência oficial do
personagem anexada (`referenceImages`). Saída: `assets/sprites/characters/<id>/chr_<id>_battle.png`
(grade 2 × 3: parado, ataque, técnica / dano, KO, vitória), virado para a DIREITA.

```text
Asset type: battle pose sprite sheet for a JRPG party member, to be converted into in-game sprites.
Reference: the attached image is the official reference sheet of NAME. Copy the character design EXACTLY: same face, hair, colors, outfit and weapon.
Subject: NAME (DESCRIPTION).
Composition: a strict grid of 2 rows x 3 columns, same scale, same baseline per row, VERY wide empty magenta gaps between figures, all facing RIGHT (towards the enemies):
Row 1: 1) battle-ready idle stance, 2) attacking — ATTACK, 3) using a technique — TECH.
Row 2: 4) hurt — recoiling backwards with a pained face, 5) knocked out — collapsed on one knee, head down, 6) victory pose — VICTORY.
Pixel scale: draw each pose as a small native sprite about 40 pixels wide and 56 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block.
```

| NAME | ATTACK | TECH | VICTORY |
|---|---|---|---|
| KAEL | lunging forward slashing the gear-blade | gear-blade raised, piston venting steam, cyan sparks | gear-blade on the shoulder, grinning, thumbs up |
| ECO | punching forward with a heavy stone forearm | both forearm shields raised, glowing cyan barrier dome | single eye glowing brighter, waving one hand |
| GERD | throwing a small smoking bomb with the mechanical arm | kneeling and fixing something with a wrench, sparks | arms crossed, smug smile, pipe in mouth |

# enm_triturador — chefe do prólogo (Triturador), em 3 partes

Prompt = bloco de `style_base.md` + o bloco abaixo. O núcleo e as garras viram inimigos separados
na batalha (partes), então vêm em linhas separadas.

```text
Asset type: boss sprite sheet for a JRPG battle, to be converted into in-game sprites. The boss is split into separate parts that are drawn apart from each other.
Subject: THE CRUSHER (Triturador), a giant old scrap-compacting press machine that woke up angry in a scrapyard: a heavy rusty iron body shaped like a hydraulic press with a boxy furnace core, glowing orange-red furnace mouth like a face with teeth-like grill, two big riveted smokestacks puffing black smoke, yellow-and-black hazard stripes, patches of brass, and two separate huge mechanical CLAWS made of rusty iron and brass pistons with three crushing fingers each.
Composition: a strict grid of 3 rows x 3 columns, lots of empty background between figures, all facing LEFT (towards the heroes):
Row 1 — the CORE (body without claws): 1) idle, 2) idle with smoke puff and brighter furnace glow, 3) hurt — sparks and dents, furnace flickering.
Row 2 — the UPPER CLAW (detached, floating on its own piston arm stub): 1) idle open, 2) raised high ready to smash, 3) hurt — bent with sparks.
Row 3 — the LOWER CLAW (detached, mirrored variation of the upper claw): 1) idle open, 2) raised high ready to smash, 3) hurt — bent with sparks.
Pixel scale: draw the core about 96 pixels wide and 96 pixels tall, each claw about 56 pixels wide and 48 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block.
```

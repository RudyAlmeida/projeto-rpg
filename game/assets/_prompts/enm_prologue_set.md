# Inimigos comuns do prólogo (Rato-Engrenagem, Corvo de Sucata, Aranha-Parafuso, Lâmpada Errante, Soldado Imperial)

Um pedido por inimigo: prompt = bloco de `style_base.md` + o bloco do inimigo. Todos com 4 quadros
(parado, respirando, ataque, dano), virados para a ESQUERDA, como a Sentinela de Latão.
Saídas: `assets/_source/enm_<id>_raw_v1.png` → `assets/sprites/enemies/enm_<id>.png`.

## gear_rat — Rato-Engrenagem
```text
Asset type: enemy sprite sheet for a JRPG battle, to be converted into in-game sprites.
Subject: GEAR RAT, a scrapyard rat that chews copper: grey furry rat body with parts replaced by brass — a small gear embedded in its back, a copper wire tail, one glowing red lens eye, big front teeth of steel. Quick, twitchy, a bit cute.
Composition: the SAME creature in 4 frames in one horizontal row, evenly spaced, same scale, same baseline, all facing LEFT: 1) idle crouched, 2) idle sniffing (breathing), 3) attacking — lunging forward to the left with teeth bared, 4) hurt — flinching with small sparks.
Pixel scale: draw each frame as a small native sprite about 30 pixels wide and 22 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty background between frames.
```

## scrap_crow — Corvo de Sucata
```text
Asset type: enemy sprite sheet for a JRPG battle, to be converted into in-game sprites.
Subject: SCRAP CROW, a black crow whose wings are patched with thin rusty metal plates and bolts, a brass monocle over one eye, carrying a stolen shiny screw in its beak. Sly thief.
Composition: the SAME creature in 4 frames in one horizontal row, evenly spaced, same scale, same baseline, all facing LEFT: 1) hovering wings up, 2) hovering wings down, 3) attacking — diving forward to the left with claws out, 4) hurt — feathers and a bolt flying off.
Pixel scale: draw each frame as a small native sprite about 32 pixels wide and 28 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty background between frames.
```

## bolt_spider — Aranha-Parafuso
```text
Asset type: enemy sprite sheet for a JRPG battle, to be converted into in-game sprites.
Subject: BOLT SPIDER, a mechanical spider: a round rusty body made of a big hex nut, eight thin legs made of long screws and bolts, two small green glowing eyes, a dripping green poison needle at the front. Creepy but readable.
Composition: the SAME creature in 4 frames in one horizontal row, evenly spaced, same scale, same baseline, all facing LEFT: 1) idle, 2) idle legs shifted (breathing), 3) attacking — rearing up and stabbing with the poison needle to the left, 4) hurt — legs curled, sparks.
Pixel scale: draw each frame as a small native sprite about 34 pixels wide and 24 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty background between frames.
```

## wander_lamp — Lâmpada Errante
```text
Asset type: enemy sprite sheet for a JRPG battle, to be converted into in-game sprites.
Subject: WANDERING LAMP, a little ghost of leaked Aether living inside an old broken brass street-lamp head: the glass lamp cage floats with no pole, a wispy glowing Aether-cyan flame-spirit with two dark eyes inside, small cyan sparks around it. Floating, mischievous, magical.
Composition: the SAME creature in 4 frames in one horizontal row, evenly spaced, same scale, same baseline, all facing LEFT: 1) floating, 2) floating slightly higher with brighter flame, 3) attacking — flaring a bolt of cyan lightning to the left, 4) hurt — glass cracked, flame flickering.
Pixel scale: draw each frame as a small native sprite about 24 pixels wide and 34 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty background between frames.
```

## imperial_soldier — Soldado Imperial
```text
Asset type: enemy sprite sheet for a JRPG battle, to be converted into in-game sprites.
Subject: IMPERIAL SOLDIER of the Ferrovar Empire, chibi human (about 2.5 heads tall): imperial navy-blue uniform coat with brass buttons, a brass-rimmed helmet with dark goggles covering the eyes, a leather bandolier, holding a long steam rifle with a small copper tank. Faceless, disciplined.
Composition: the SAME soldier in 4 frames in one horizontal row, evenly spaced, same scale, same baseline, all facing LEFT: 1) idle holding rifle, 2) idle breathing, 3) attacking — firing the steam rifle to the left with a puff of steam, 4) hurt — recoiling.
Pixel scale: draw each frame as a small native sprite about 36 pixels wide and 52 pixels tall, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block. Keep lots of empty background between frames.
```

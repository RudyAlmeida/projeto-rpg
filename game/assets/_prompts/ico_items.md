# ico_items — ícones de itens e gemas (16×16)

- Bruto: `assets/_source/ico_items_raw_v1.png`
- Sprite: `assets/ui/ico_items.png` (grade 4 × 4, células 16×16)
- Ferramenta: ponte MCP do Codex, 2026-09-25

Ordem (linha por linha): Poção, Éter, Pena Fênix, Antídoto / Lâmina-engrenagem, Cajado de raiz, Manopla a vapor, Casaco de couro / Amuleto de latão, Gema de Fogo, Gema de Gelo, Gema de Raio / Gema de Cura, Gema de Força, Gema de Timing, Bolsa de moedas.

Prompt = bloco de `style_base.md` + o bloco abaixo:

```text
Asset type: inventory icon sheet for a JRPG menu, to be converted into 16x16 in-game icons.
Composition: a strict grid of 4 rows x 4 columns, 16 separate small icons, every icon the same size and centered in its cell, lots of empty background between icons, no labels.
Row 1 (consumables): red healing potion in a round glass flask with brass cap; glowing Aether-cyan mana vial; golden phoenix feather; small green antidote bottle with a leaf label.
Row 2 (equipment): short sword with a brass gear on the guard; wooden druid staff made of a twisted root with a small crystal; heavy brass steam gauntlet; brown leather coat with brass buttons.
Row 3: round brass amulet with a gear engraving; faceted red fire gem; faceted icy blue gem; faceted yellow lightning gem.
Row 4: faceted green healing gem; faceted orange strength gem with a fist symbol; faceted white-gold gem with a tiny clock face (timing gem); leather coin pouch with gold coins.
Each icon is chunky and readable at tiny size, 1-pixel dark outline, simple shading.
Pixel scale: draw each icon as a native 16x16 sprite, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block.
```

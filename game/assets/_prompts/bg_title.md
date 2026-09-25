# bg_title — arte da tela de título

- Bruto: `assets/_source/bg_title_raw_v1.png`
- Final: `assets/ui/bg_title.png` (640×360, paleta velmora32)
- Ferramenta: ponte MCP do Codex, 2026-09-25

Prompt = bloco de `style_base.md` (sem a regra de fundo magenta) + o bloco abaixo:

```text
Asset type: title screen key art for a 16-bit JRPG, 16:9 landscape, full-bleed scene (no transparent or magenta background).
Scene: dusk over a steampunk frontier workshop town built on a hillside — brick houses with copper roofs, chimneys and gears, a small airship moored at a tower, warm lamp lights in windows. In the sky far behind, a giant faint glowing Aether-cyan heart-shaped machine silhouette with gears, half hidden by clouds, radiating soft cyan light. Foreground: a young hero with spiky navy hair and a red scarf seen from behind on a cliff edge, looking at the distant glowing heart, a small ancient stone automaton with one cyan eye standing next to him.
Composition: wide landscape, horizon in the lower third, large calm sky area in the upper half left mostly empty for the game logo, hero and automaton small at bottom-left.
Palette: dusk purples and navy in the sky, warm brass and copper in the town, cyan Aether glow as the only bright accent.
Pixel scale: draw as native 320x180 pixel art, then upscale with nearest-neighbour so each art pixel becomes a large perfectly square block.
Avoid: text, logo, letters, watermark, UI.
```

# Prompt-base — O Coração de Éter

Todo pedido de imagem ao Codex começa com o bloco abaixo. Depois vem o bloco específico do asset
(Subject / Composition). Nunca alterar este bloco sem registrar no Guia de Estilo.

```text
Use case: stylized-concept
Style/medium: 16-bit SNES-era JRPG pixel art (Chrono Trigger / Final Fantasy VI era), clean hand-placed pixels on a strict square pixel grid, every pixel block the same size, no anti-aliasing, no blur, no gradients inside pixels, no dithering noise.
World: classic fantasy mixed with steampunk — stone, wood and magic next to brass, copper, gears, pistons, steam and airships.
Palette: limited, max ~32 colors: dark purple-black outlines (#1a1423), warm skin tones, cream linen cloth (#e9dcb4, #bfa87a), brass/gold (#e8b64c, #b8862b), copper/rust (#e07b4c, #b0492e), leather browns (#c99a6b, #8f6040), imperial navy blues (#5a8bc4, #34568f, #1f2f5a), scarlet red (#d23a3a), forest greens (#6fa84a, #3b6b3a), glowing Aether cyan (#4fe0d0) for magic/energy, steel greys.
Lighting: soft light from top-left, one highlight tone and one shadow tone per material.
Outline: 1-pixel dark outline around characters and objects (selout allowed).
Proportions: characters chibi, about 2.5 heads tall.
Background: plain flat solid magenta #FF00FF (it will be removed), no shadow on the background.
Avoid: text, labels, watermark, UI, signatures, painterly rendering, smooth vector art, high-resolution anime illustration, 3D render, photorealism.
```

## Tamanhos (resolução nativa do jogo, 640×360)

| Asset | Tamanho nativo | Observação |
|---|---|---|
| Personagem (mapa e batalha) | corpo ~32×56, célula 64×64 | célula maior para armas e poses de ataque |
| Tile | 16×16 | |
| Retrato de diálogo | 64×64 | |
| Ícone de item/habilidade | 16×16 | |
| Inimigo comum | 32×32 a 64×64 | |
| Chefe | 96×96 a 160×160 | |

## Pipeline

1. `tools/gen_image.ps1` gera a imagem bruta em `game/assets/_source/` (ignorada pelo Godot).
2. `tools/art/pixelize.mjs` remove o magenta, separa as poses, reduz para o tamanho nativo e aplica a paleta `assets/palette/velmora32.hex`.
3. Resultado final em `game/assets/sprites/...`.

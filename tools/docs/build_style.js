// Builds docs/Guia_de_Estilo.docx — art style guide.
// Usage: node build_style.js <output.docx>
const fs = require('fs');
const path = require('path');
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Table, TableRow, TableCell,
  WidthType, ShadingType, LevelFormat, BorderStyle, PageBreak, Footer, Header, PageNumber,
  VerticalAlign, ImageRun,
} = require('docx');

const OUT = process.argv[2];
const ROOT = path.join(__dirname, '..', '..');
const GAME = path.join(ROOT, 'game');
const W = 9638;
const ACCENT = '5A3A1A';
const GOLD = 'B8860B';

const runs = (text, opts = {}) => String(text).split(/(\*\*[^*]+\*\*)/g).filter(Boolean).map(p => p.startsWith('**')
  ? new TextRun({ text: p.slice(2, -2), bold: true, ...opts })
  : new TextRun({ text: p, ...opts }));
const P = (text, run, keepNext = false) => new Paragraph({ keepNext, children: runs(text, run), spacing: { after: 120 } });
const tocEntries = [];
const H1 = t => { tocEntries.push(t); return new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(t)], pageBreakBefore: true }); };
const H2 = t => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(t)] });
const B = t => new Paragraph({ numbering: { reference: 'bullets', level: 0 }, children: runs(t), spacing: { after: 60 } });
const N = t => new Paragraph({ numbering: { reference: 'num', level: 0 }, children: runs(t), spacing: { after: 60 } });
const Code = t => new Paragraph({ children: [new TextRun({ text: t, font: 'Consolas', size: 17 })], shading: { type: ShadingType.CLEAR, color: 'auto', fill: 'F3EEE6' }, spacing: { after: 0 }, indent: { left: 200, right: 200 } });
const gap = () => new Paragraph({ children: [], spacing: { after: 120 } });

const border = { style: BorderStyle.SINGLE, size: 4, color: 'C9B8A0' };
const borders = { top: border, bottom: border, left: border, right: border };
function table(headers, rows, widths) {
  const sum = widths.reduce((a, b) => a + b, 0);
  widths = widths.map(w => Math.round(w * W / sum));
  widths[widths.length - 1] += W - widths.reduce((a, b) => a + b, 0);
  const cell = (text, i, header, keepNext) => new TableCell({
    width: { size: widths[i], type: WidthType.DXA }, borders, verticalAlign: VerticalAlign.CENTER,
    shading: header ? { type: ShadingType.CLEAR, color: 'auto', fill: ACCENT } : undefined,
    margins: { top: 60, bottom: 60, left: 100, right: 100 },
    children: [new Paragraph({ keepNext, children: runs(text, header ? { bold: true, color: 'FFFFFF', size: 19 } : { size: 19 }) })],
  });
  return new Table({
    width: { size: W, type: WidthType.DXA }, columnWidths: widths,
    rows: [
      new TableRow({ tableHeader: true, cantSplit: true, children: headers.map((h, i) => cell(h, i, true, true)) }),
      ...rows.map((r, ri) => new TableRow({ cantSplit: true, children: r.map((c, i) => cell(c, i, false, ri < rows.length - 1)) })),
    ],
  });
}

// PNG size from the IHDR chunk (no image library needed).
function pngSize(file) {
  const b = fs.readFileSync(file);
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
}
// Image scaled to fit maxWidthPx (at 96 dpi a 16 cm column ≈ 600 px).
function image(file, maxWidthPx = 600, caption) {
  if (!fs.existsSync(file)) return [P(`(imagem não encontrada: ${path.relative(ROOT, file)})`, { italics: true, color: 'AA0000' })];
  const { w, h } = pngSize(file);
  const s = Math.min(1, maxWidthPx / w);
  const out = [new Paragraph({ alignment: AlignmentType.CENTER, keepNext: !!caption, children: [new ImageRun({ type: 'png', data: fs.readFileSync(file), transformation: { width: Math.round(w * s), height: Math.round(h * s) } })] })];
  if (caption) out.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new TextRun({ text: caption, italics: true, size: 18, color: '666666' })] }));
  return out;
}

// ---------- palette ----------
const palette = fs.readFileSync(path.join(GAME, 'assets/palette/velmora32.hex'), 'utf8').split(/\s+/).filter(Boolean);
const ramps = [
  ['Contorno e aço', [0, 1, 2, 3, 4]],
  ['Pele', [5, 6, 7]],
  ['Linho (tecido claro)', [8, 9]],
  ['Latão / ouro', [10, 11, 12, 13]],
  ['Cobre / ferrugem', [14, 15]],
  ['Couro', [16, 17, 18]],
  ['Azul imperial', [19, 20, 21, 22]],
  ['Vermelho', [23, 24, 25]],
  ['Verde (natureza)', [26, 27, 28]],
  ['Éter (magia/energia)', [29, 30, 31]],
];
const swatchW = Math.floor((W - 2400) / 5);
const paletteTable = new Table({
  width: { size: 2400 + swatchW * 5, type: WidthType.DXA },
  columnWidths: [2400, swatchW, swatchW, swatchW, swatchW, swatchW],
  rows: ramps.map(([name, ids]) => new TableRow({
    cantSplit: true,
    children: [
      new TableCell({ width: { size: 2400, type: WidthType.DXA }, borders, verticalAlign: VerticalAlign.CENTER, margins: { left: 100 }, children: [new Paragraph({ keepNext: true, children: [new TextRun({ text: name, bold: true, size: 18 })] })] }),
      ...[0, 1, 2, 3, 4].map(k => {
        const id = ids[k];
        const hex = id === undefined ? null : palette[id];
        const light = hex && (parseInt(hex.slice(0, 2), 16) * 0.3 + parseInt(hex.slice(2, 4), 16) * 0.59 + parseInt(hex.slice(4, 6), 16) * 0.11) > 140;
        return new TableCell({
          width: { size: swatchW, type: WidthType.DXA }, borders,
          shading: hex ? { type: ShadingType.CLEAR, color: 'auto', fill: hex.toUpperCase() } : undefined,
          margins: { top: 160, bottom: 160 },
          children: [new Paragraph({ keepNext: true, alignment: AlignmentType.CENTER, children: [new TextRun({ text: hex ? `#${hex}` : '', size: 16, font: 'Consolas', color: light ? '1A1423' : 'FFFFFF' })] })],
        });
      }),
    ],
  })),
});

// ---------- prompt-base (read from the project, single source of truth) ----------
const styleMd = fs.readFileSync(path.join(GAME, 'assets/_prompts/style_base.md'), 'utf8');
const promptBase = (styleMd.match(/```text\r?\n([\s\S]*?)```/) || [, ''])[1].trim().split(/\r?\n/);

// ---------- content ----------
const children = [];
children.push(
  new Paragraph({ children: [], spacing: { before: 2400 } }),
  new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: 'O CORAÇÃO DE ÉTER', bold: true, size: 60, color: ACCENT, font: 'Georgia' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: GOLD, space: 8 } }, spacing: { before: 200, after: 400 }, children: [new TextRun({ text: 'Guia de Estilo de Arte', size: 32, color: '333333' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 1400 }, children: [new TextRun({ text: 'Pixel art 16-bit · fantasia clássica + steampunk', size: 22, color: '555555' })] }),
  table(['Campo', 'Valor'], [
    ['Versão', '0.1 — proposta para aprovação'],
    ['Data', '24/09/2026'],
    ['Decisões de base', 'D-02 pixel art 16-bit · D-07 640×360'],
    ['Arquivos no projeto', 'game/assets/palette/velmora32.hex · game/assets/_prompts/style_base.md'],
  ], [30, 70]),
  new Paragraph({ children: [new PageBreak()] }),
  new Paragraph({ children: [new TextRun({ text: 'Sumário', bold: true, size: 32, color: ACCENT })], spacing: { after: 200 } }),
);
const tocIndex = children.length;

children.push(
  H1('1. Princípios visuais'),
  B('**Leitura primeiro:** silhuetas claras e contraste entre personagem e cenário, mesmo em 640×360.'),
  B('**Pixels honestos:** grade quadrada, sem anti-aliasing, sem desfoque, sem gradientes suaves.'),
  B('**Mundo em conflito na cor:** o Império é latão, cobre e azul-marinho; a natureza e a magia são verdes e ciano-Éter. Regiões drenadas perdem saturação.'),
  B('**Éter é a única cor que brilha:** o ciano (#4fe0d0) fica reservado para magia, energia e o Éter.'),
  B('**Luz de cima à esquerda,** um tom de luz e um de sombra por material, contorno escuro de 1 pixel.'),
);

children.push(
  H1('2. Paleta Velmora 32'),
  P('32 cores fixas. Toda arte final é convertida para esta paleta pela ferramenta de conversão. Arquivo: game/assets/palette/velmora32.hex (importável no Aseprite e no Krita).', undefined, true),
  paletteTable,
  gap(),
  H2('Regras de uso'),
  B('A primeira cor (#1a1423) é o contorno. Não usar preto puro.'),
  B('Pele: usar a rampa de pele; nunca tons de latão no rosto.'),
  B('Ciano-Éter só para magia, energia, olhos de autômatos e o Coração.'),
  B('Novas cores só entram com registro neste guia (e no histórico de versões).'),
);

children.push(
  H1('3. Tamanhos e grade'),
  P('Resolução nativa 640×360, ampliada por múltiplos inteiros (1280×720, 1920×1080). Tamanhos em pixels nativos:', undefined, true),
  table(['Asset', 'Tamanho nativo', 'Observação'], [
    ['Personagem (mapa e batalha)', 'corpo ~32×56, célula 64×64', 'célula maior para armas e poses de ataque; alinhado pela base, centralizado. 56 px é a grade natural das imagens do Codex: alturas menores apagam o rosto'],
    ['Tile', '16×16', 'cenário montado em TileMap'],
    ['Retrato de diálogo', '64×64', 'expressões: neutro, feliz, triste, bravo, surpreso'],
    ['Ícone de item/habilidade', '16×16', ''],
    ['Inimigo comum', '32×32 a 64×64', ''],
    ['Chefe', '96×96 a 160×160', ''],
    ['Proporção', '~2,5 cabeças', 'estilo chibi SNES'],
  ], [30, 25, 45]),
);

children.push(
  H1('4. Prompt-base do Codex'),
  P('Todo pedido de imagem começa com este bloco, seguido da descrição do asset. Fonte: game/assets/_prompts/style_base.md.', undefined, true),
  ...promptBase.map(Code),
  gap(),
  H2('Bloco do asset (exemplo: Kael)'),
  B('**Asset type:** o que é e onde será usado.'),
  B('**Subject:** aparência completa (cabelo, roupa, cores, arma).'),
  B('**Composition:** poses em linha, mesma escala, mesma base, bastante espaço magenta entre elas.'),
  B('**Pixel scale:** desenhar como sprite pequeno (~40×56) ampliado sem suavização.'),
);

children.push(
  H1('5. Pipeline de produção'),
  N('**Gerar:** tools/gen_image.ps1 cria a imagem bruta em game/assets/_source/ (ignorada pelo Godot).'),
  N('**Converter:** tools/art/pixelize.mjs remove o fundo (magenta ou transparente), separa as poses, reduz para o tamanho nativo, aplica a paleta e limpa pixels soltos.'),
  N('**Revisar:** conferir a prévia ampliada (_preview.png) e o sprite em tamanho real no Godot.'),
  N('**Ajustar à mão (opcional):** retoques finos no Aseprite/Krita com a paleta velmora32.'),
  N('**Registrar:** prompt em game/assets/_prompts/ e linha no Controle de assets do planejamento.'),
  gap(),
  table(['Pasta', 'Conteúdo'], [
    ['game/assets/_source/', 'imagens brutas do Codex (não importadas pelo Godot)'],
    ['game/assets/_prompts/', 'prompt-base e prompts de cada asset'],
    ['game/assets/palette/', 'paleta velmora32'],
    ['game/assets/sprites/characters/<nome>/', 'sprites finais de personagens'],
  ], [40, 60]),
);

const RAW = path.join(GAME, 'assets/_source/chr_kael_ref_raw_v1.png');
const PREVIEW = path.join(GAME, 'assets/sprites/characters/kael/chr_kael_ref_preview.png');
children.push(
  H1('6. Referência oficial: Kael'),
  P('Primeira imagem produzida com o prompt-base e convertida pela ferramenta. Serve de referência de escala, cores e acabamento para todos os outros personagens.', undefined, true),
  ...image(RAW, 600, 'Imagem bruta gerada pelo Codex (fundo transparente)'),
  ...image(PREVIEW, 600, 'Após a conversão: 4 quadros de 64×64 na paleta Velmora 32 (prévia ampliada 6×)'),
  ...image(path.join(GAME, 'assets/_source/godot_kael_preview.png'), 600, 'No Godot, tela de 640×360: acima ampliado 2×, abaixo no tamanho real do jogo'),
  H2('Limitações conhecidas'),
  B('A conversão automática não "desenha": detalhes menores que um pixel nativo somem. Na pose de combate o rosto do Kael fica escuro e pede retoque manual.'),
  B('Poses de animação (andar, atacar) vão exigir geração quadro a quadro com a mesma referência, ou retoque manual.'),
  H2('Pontos para aprovação'),
  B('Paleta: as rampas cobrem bem pele, linho, latão, couro, azul imperial e natureza?'),
  B('Escala: o Kael com ~56 px de altura (15% da tela de 640×360, proporção parecida com Chrono Trigger) está bom?'),
  B('Visual: cabelo azul, cachecol vermelho, óculos de latão e lâmina-engrenagem representam o personagem?'),
);

children.splice(tocIndex, 0, ...tocEntries.map(t => new Paragraph({ children: [new TextRun({ text: t, size: 24 })], spacing: { after: 140 } })));

const doc = new Document({
  creator: 'Claude',
  title: 'O Coração de Éter — Guia de Estilo',
  styles: {
    default: { document: { run: { font: 'Calibri', size: 22 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 34, bold: true, color: ACCENT, font: 'Georgia' },
        paragraph: { spacing: { before: 240, after: 200 }, outlineLevel: 0, border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: GOLD, space: 4 } } } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 26, bold: true, color: ACCENT }, paragraph: { spacing: { before: 280, after: 80 }, outlineLevel: 1, keepNext: true, keepLines: true } },
    ],
  },
  numbering: { config: [
    { reference: 'bullets', levels: [{ level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 300 } } } }] },
    { reference: 'num', levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 360 } } } }] },
  ] },
  sections: [{
    properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } },
    headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'O Coração de Éter — Guia de Estilo', size: 16, color: '888888' })] })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: ['Página ', PageNumber.CURRENT, ' de ', PageNumber.TOTAL_PAGES], size: 16, color: '888888' })] })] }) },
    children,
  }],
});

Packer.toBuffer(doc).then(buf => { fs.writeFileSync(OUT, buf); console.log('written', OUT, buf.length); });

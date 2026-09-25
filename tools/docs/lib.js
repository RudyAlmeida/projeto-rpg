// Shared helpers for the project documents (docx). LibreOffice-friendly: static TOC,
// tables and headings kept together across pages.
const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Table, TableRow, TableCell,
  WidthType, ShadingType, LevelFormat, BorderStyle, PageBreak, Footer, Header, PageNumber, VerticalAlign,
} = require('docx');

const W = 9638; // A4 content width with 2 cm margins (DXA)

function createDoc({ accent = '5A3A1A', gold = 'B8860B', border = 'C9B8A0' } = {}) {
  const tocEntries = [];
  const children = [];
  let tocIndex = -1;

  const runs = (text, opts = {}) => String(text).split(/(\*\*[^*]+\*\*)/g).filter(Boolean).map(p => p.startsWith('**')
    ? new TextRun({ text: p.slice(2, -2), bold: true, ...opts })
    : new TextRun({ text: p, ...opts }));
  const P = (text, run, keepNext = false) => new Paragraph({ keepNext, children: runs(text, run), spacing: { after: 120 } });
  const H1 = t => { tocEntries.push(t); return new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(t)], pageBreakBefore: true }); };
  const H2 = t => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(t)] });
  const H3 = t => new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun(t)] });
  const B = t => new Paragraph({ numbering: { reference: 'bullets', level: 0 }, children: runs(t), spacing: { after: 60 } });
  const N = (t, ref = 'num') => new Paragraph({ numbering: { reference: ref, level: 0 }, children: runs(t), spacing: { after: 60 } });
  const Code = t => new Paragraph({ children: [new TextRun({ text: t, font: 'Consolas', size: 18 })], shading: { type: ShadingType.CLEAR, color: 'auto', fill: 'F3EEE6' }, spacing: { after: 0 }, indent: { left: 200, right: 200 } });
  const gap = () => new Paragraph({ children: [], spacing: { after: 120 } });

  const line = { style: BorderStyle.SINGLE, size: 4, color: border };
  const borders = { top: line, bottom: line, left: line, right: line };
  // Tables up to keepRows rows stay on one page; longer ones split with a repeated header.
  function table(headers, rows, widths, keepRows = 22) {
    const sum = widths.reduce((a, b) => a + b, 0);
    widths = widths.map(w => Math.round(w * W / sum));
    widths[widths.length - 1] += W - widths.reduce((a, b) => a + b, 0);
    const keep = rows.length <= keepRows;
    const cell = (text, i, header, keepNext) => new TableCell({
      width: { size: widths[i], type: WidthType.DXA }, borders, verticalAlign: VerticalAlign.CENTER,
      shading: header ? { type: ShadingType.CLEAR, color: 'auto', fill: accent } : undefined,
      margins: { top: 60, bottom: 60, left: 100, right: 100 },
      children: [new Paragraph({ keepNext, children: runs(text, header ? { bold: true, color: 'FFFFFF', size: 19 } : { size: 19 }) })],
    });
    return new Table({
      width: { size: W, type: WidthType.DXA }, columnWidths: widths,
      rows: [
        new TableRow({ tableHeader: true, cantSplit: true, children: headers.map((h, i) => cell(h, i, true, true)) }),
        ...rows.map((r, ri) => new TableRow({ cantSplit: true, children: r.map((c, i) => cell(c, i, false, keep && ri < rows.length - 1)) })),
      ],
    });
  }

  function cover({ title, subtitle, tagline, info }) {
    children.push(
      new Paragraph({ children: [], spacing: { before: 2400 } }),
      new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: title, bold: true, size: 60, color: accent, font: 'Georgia' })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: gold, space: 8 } }, spacing: { before: 200, after: 400 }, children: [new TextRun({ text: subtitle, size: 32, color: '333333' })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 1400 }, children: [new TextRun({ text: tagline, size: 22, color: '555555' })] }),
      table(['Campo', 'Valor'], info, [30, 70]),
      new Paragraph({ children: [new PageBreak()] }),
      new Paragraph({ children: [new TextRun({ text: 'Sumário', bold: true, size: 32, color: accent })], spacing: { after: 200 } }),
    );
    tocIndex = children.length;
  }

  function write(out, { title, header }) {
    if (tocIndex >= 0) children.splice(tocIndex, 0, ...tocEntries.map(t => new Paragraph({ children: [new TextRun({ text: t, size: 24 })], spacing: { after: 140 } })));
    const numbered = ref => ({ reference: ref, levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 360 } } } }] });
    const doc = new Document({
      creator: 'Claude', title,
      styles: {
        default: { document: { run: { font: 'Calibri', size: 22 } } },
        paragraphStyles: [
          { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
            run: { size: 34, bold: true, color: accent, font: 'Georgia' },
            paragraph: { spacing: { before: 240, after: 200 }, outlineLevel: 0, border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: gold, space: 4 } } } },
          { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
            run: { size: 26, bold: true, color: accent }, paragraph: { spacing: { before: 280, after: 100 }, outlineLevel: 1, keepNext: true, keepLines: true } },
          { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true,
            run: { size: 22, bold: true, color: '444444' }, paragraph: { spacing: { before: 160, after: 80 }, outlineLevel: 2, keepNext: true, keepLines: true } },
        ],
      },
      numbering: { config: [
        { reference: 'bullets', levels: [{ level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 300 } } } }] },
        numbered('num'), numbered('num2'), numbered('num3'),
      ] },
      sections: [{
        properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } },
        headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: header, size: 16, color: '888888' })] })] }) },
        footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: ['Página ', PageNumber.CURRENT, ' de ', PageNumber.TOTAL_PAGES], size: 16, color: '888888' })] })] }) },
        children,
      }],
    });
    return Packer.toBuffer(doc).then(buf => { fs.writeFileSync(out, buf); console.log('written', out, buf.length); });
  }

  return { children, runs, P, H1, H2, H3, B, N, Code, gap, table, cover, write };
}

module.exports = { createDoc };

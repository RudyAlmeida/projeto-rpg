// Converts a Codex tileset sheet (tiles in a grid separated by magenta gutters) into a
// native 16×16 tile atlas locked to the game palette.
//
// Usage:
//   node tiles.mjs <input.png> <output.png> [--cols 8] [--rows 6] [--tile 16] [--preview 6]
//                  [--palette <file.hex>]
//
// Every cell becomes one tile, keeping the grid order. Cells are found from the magenta
// gutters; all cells share one square size (the median column width), so a prop drawn
// smaller than its cell keeps its relative size and gets a transparent margin.
import { createCanvas, loadImage } from '@napi-rs/canvas';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const args = process.argv.slice(2);
const opt = (name, def) => { const i = args.indexOf(`--${name}`); return i >= 0 ? args[i + 1] : def; };
const [input, output] = args.filter((a, i) => !a.startsWith('--') && !(i > 0 && args[i - 1].startsWith('--')));
if (!input || !output) { console.error('usage: node tiles.mjs <input.png> <output.png> [--cols 8] [--rows 6]'); process.exit(1); }
const here = path.dirname(fileURLToPath(import.meta.url));
const paletteFile = opt('palette', path.join(here, '../../game/assets/palette/velmora32.hex'));
const COLS = Number(opt('cols', 8)), ROWS = Number(opt('rows', 6)), TILE = Number(opt('tile', 16));
const previewScale = Number(opt('preview', 6));

const palette = fs.readFileSync(paletteFile, 'utf8').split(/\s+/).filter(Boolean)
  .map(h => [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)]);
function nearest(r, g, b) {
  let best = 0, bestD = Infinity;
  for (let i = 0; i < palette.length; i++) {
    const [pr, pg, pb] = palette[i];
    const rm = (r + pr) / 2, dr = r - pr, dg = g - pg, db = b - pb;
    const d = (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db;
    if (d < bestD) { bestD = d; best = i; }
  }
  return best;
}

const img = await loadImage(fs.readFileSync(input));
const W = img.width, H = img.height;
const src = createCanvas(W, H);
src.getContext('2d').drawImage(img, 0, 0);
const data = src.getContext('2d').getImageData(0, 0, W, H).data;
const isBg = (r, g, b, a) => a < 128 || (r - g > 90 && b - g > 90 && Math.abs(r - b) < 110);
const idx = new Int16Array(W * H).fill(-1);
for (let i = 0; i < W * H; i++) {
  const r = data[i * 4], g = data[i * 4 + 1], b = data[i * 4 + 2], a = data[i * 4 + 3];
  if (!isBg(r, g, b, a)) idx[i] = nearest(r, g, b);
}

// Foreground runs along one axis; keeps the `count` longest, in order.
function bands(length, fgAt, count) {
  const found = [];
  let start = -1;
  for (let i = 0; i <= length; i++) {
    const on = i < length && fgAt(i);
    if (on && start < 0) start = i;
    if (!on && start >= 0) { found.push([start, i - 1]); start = -1; }
  }
  return found.sort((a, b) => (b[1] - b[0]) - (a[1] - a[0])).slice(0, count).sort((a, b) => a[0] - b[0]);
}
const colFg = x => { let n = 0; for (let y = 0; y < H; y++) if (idx[y * W + x] >= 0) n++; return n > H * 0.02; };
const rowFg = y => { let n = 0; for (let x = 0; x < W; x++) if (idx[y * W + x] >= 0) n++; return n > W * 0.02; };
const cols = bands(W, colFg, COLS), rows = bands(H, rowFg, ROWS);
if (cols.length !== COLS || rows.length !== ROWS) {
  console.error(`expected ${COLS}×${ROWS} cells, found ${cols.length}×${rows.length}`); process.exit(1);
}
const sizes = cols.map(([a, b]) => b - a + 1).sort((a, b) => a - b);
const S = sizes[Math.floor(sizes.length / 2)];
// Square cell of side S around each band (bands narrower than S are props: keep them centred
// horizontally and resting on the bottom of the band).
const square = ([a, b], bottom) => bottom ? [b - S + 1, b] : [Math.round((a + b - S) / 2), Math.round((a + b - S) / 2) + S - 1];

const atlas = createCanvas(COLS * TILE, ROWS * TILE);
const actx = atlas.getContext('2d');
const out = actx.createImageData(atlas.width, atlas.height);
for (let r = 0; r < ROWS; r++) for (let c = 0; c < COLS; c++) {
  const [x0] = square(cols[c], false);
  const [y0] = square(rows[r], true);
  const counts = new Float32Array(palette.length);
  for (let ty = 0; ty < TILE; ty++) for (let tx = 0; tx < TILE; tx++) {
    counts.fill(0);
    let total = 0, opaque = 0;
    const sx0 = x0 + Math.floor(tx * S / TILE), sx1 = x0 + Math.floor((tx + 1) * S / TILE);
    const sy0 = y0 + Math.floor(ty * S / TILE), sy1 = y0 + Math.floor((ty + 1) * S / TILE);
    for (let y = Math.max(sy0, 0); y < Math.min(sy1, H); y++) for (let x = Math.max(sx0, 0); x < Math.min(sx1, W); x++) {
      total++;
      const i = idx[y * W + x];
      if (i >= 0) { opaque++; counts[i]++; }
    }
    if (!total || opaque / total < 0.5) continue;
    let best = 0;
    for (let i = 1; i < counts.length; i++) if (counts[i] > counts[best]) best = i;
    const o = ((r * TILE + ty) * atlas.width + c * TILE + tx) * 4;
    [out.data[o], out.data[o + 1], out.data[o + 2]] = palette[best];
    out.data[o + 3] = 255;
  }
}
actx.putImageData(out, 0, 0);
fs.writeFileSync(output, atlas.toBuffer('image/png'));
console.log(`${COLS}×${ROWS} tiles of ${TILE}px from ${S}px cells -> ${output}`);

if (previewScale > 0) {
  const p = createCanvas(atlas.width * previewScale, atlas.height * previewScale);
  const pctx = p.getContext('2d');
  pctx.imageSmoothingEnabled = false;
  pctx.fillStyle = '#3a3050';
  pctx.fillRect(0, 0, p.width, p.height);
  pctx.drawImage(atlas, 0, 0, p.width, p.height);
  const previewPath = output.replace(/\.png$/, '_preview.png');
  fs.writeFileSync(previewPath, p.toBuffer('image/png'));
}

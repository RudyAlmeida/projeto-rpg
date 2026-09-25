// Converts a Codex-generated reference image (poses on a magenta background) into
// native-resolution pixel-art sprites locked to the game palette.
//
// Usage:
//   node pixelize.mjs <input.png> <output.png> [--palette <file.hex>] [--height 56]
//                     [--cell 64x64] [--ref 0] [--preview 6]
//
//   --height   native height (px) of the reference pose after scaling
//   --ref      index of the pose used to compute the scale (others use the same scale)
//   --cell     frame size in the output sheet; grows automatically if a pose does not fit
//   --preview  also writes <output>_preview.png upscaled N× for review (0 = off)
//   --outline-weight  vote weight of the outline colour when downscaling (default 1.0)
import { createCanvas, loadImage } from '@napi-rs/canvas';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const args = process.argv.slice(2);
const opt = (name, def) => { const i = args.indexOf(`--${name}`); return i >= 0 ? args[i + 1] : def; };
const [input, output] = args.filter((a, i) => !a.startsWith('--') && !(i > 0 && args[i - 1].startsWith('--')));
if (!input || !output) { console.error('usage: node pixelize.mjs <input.png> <output.png> [options]'); process.exit(1); }

const here = path.dirname(fileURLToPath(import.meta.url));
const paletteFile = opt('palette', path.join(here, '../../game/assets/palette/velmora32.hex'));
// 56 px matches the pixel grid Codex naturally draws at (~9 screen px per art pixel); smaller
// heights force a fractional scale that destroys small features such as faces.
const targetH = Number(opt('height', 56));
const refPose = Number(opt('ref', 0));
const [cellW0, cellH0] = opt('cell', '64x64').split('x').map(Number);
const previewScale = Number(opt('preview', 6));
const outlineWeight = Number(opt('outline-weight', 1.0)); // >1 keeps thin dark lines, but can swallow small faces

// ---------- palette ----------
const palette = fs.readFileSync(paletteFile, 'utf8').split(/\s+/).filter(Boolean)
  .map(h => [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)]);
const OUTLINE = 0; // first palette entry is the outline colour

// "redmean" weighted RGB distance — cheap and close to perceptual.
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

// ---------- load + background mask ----------
const img = await loadImage(fs.readFileSync(input));
const W = img.width, H = img.height;
const src = createCanvas(W, H);
const sctx = src.getContext('2d');
sctx.drawImage(img, 0, 0);
const data = sctx.getImageData(0, 0, W, H).data;

// Magenta key, including the pinkish fringe left by resampling.
const isBg = (r, g, b, a) => a < 128 || (r - g > 90 && b - g > 90 && Math.abs(r - b) < 110);
const fg = new Uint8Array(W * H);
const idx = new Int16Array(W * H).fill(-1);
for (let p = 0; p < W * H; p++) {
  const r = data[p * 4], g = data[p * 4 + 1], b = data[p * 4 + 2], a = data[p * 4 + 3];
  if (!isBg(r, g, b, a)) { fg[p] = 1; idx[p] = nearest(r, g, b); }
}

// ---------- split poses: rows by empty horizontal bands, then poses by empty columns ----------
// Returns [start, end] runs where counts[i] >= minCount, merging gaps up to minGap.
function runs(counts, minCount, minGap, minSize) {
  const out = [];
  for (let i = 0, start = -1, gap = 0; i <= counts.length; i++) {
    const on = i < counts.length && counts[i] >= minCount;
    if (on) { if (start < 0) start = i; gap = 0; }
    else if (start >= 0 && (++gap > minGap || i === counts.length)) { out.push([start, i - gap]); start = -1; gap = 0; }
  }
  return out.filter(([a, b]) => b - a > minSize); // drop specks
}
const rowCount = new Int32Array(H);
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) rowCount[y] += fg[y * W + x];
const bands = runs(rowCount, Math.max(2, Math.round(W * 0.002)), Math.round(H * 0.02), H * 0.05);
const poses = []; // { x0, x1, y0, y1, row, baseline }
bands.forEach(([by0, by1], row) => {
  const colCount = new Int32Array(W);
  for (let y = by0; y <= by1; y++) for (let x = 0; x < W; x++) colCount[x] += fg[y * W + x];
  for (const [x0, x1] of runs(colCount, Math.max(2, Math.round(H * 0.004)), Math.round(W * 0.01), W * 0.02)) {
    let y0 = by1, y1 = by0;
    for (let y = by0; y <= by1; y++) for (let x = x0; x <= x1; x++) if (fg[y * W + x]) { if (y < y0) y0 = y; if (y > y1) y1 = y; }
    poses.push({ x0, x1, y0, y1, row });
  }
});
if (!poses.length) { console.error('no poses found'); process.exit(1); }
// Each row shares a ground line, so walk frames keep their vertical bob.
for (const p of poses) p.baseline = Math.max(...poses.filter(q => q.row === p.row).map(q => q.y1));
const rowSizes = bands.map((_, r) => poses.filter(p => p.row === r).length);
console.log(`poses: ${poses.length} in ${bands.length} row(s) [${rowSizes.join(', ')}]`);

// ---------- downscale each pose (mode of palette indices per block) ----------
const ref = poses[Math.min(refPose, poses.length - 1)];
const scale = targetH / (ref.y1 - ref.y0 + 1); // native px per source px, shared by all poses
const sprites = poses.map(p => {
  const baseline = p.baseline;
  const w = Math.max(1, Math.round((p.x1 - p.x0 + 1) * scale));
  const h = Math.max(1, Math.round((baseline - p.y0 + 1) * scale));
  const out = new Int16Array(w * h).fill(-1);
  const counts = new Float32Array(palette.length);
  for (let oy = 0; oy < h; oy++) for (let ox = 0; ox < w; ox++) {
    const sx0 = p.x0 + Math.floor(ox / scale), sx1 = p.x0 + Math.floor((ox + 1) / scale);
    const sy0 = baseline - Math.floor((h - oy) / scale), sy1 = baseline - Math.floor((h - oy - 1) / scale);
    counts.fill(0);
    let total = 0, opaque = 0;
    for (let y = Math.max(sy0, 0); y < Math.min(sy1, H); y++) for (let x = sx0; x < Math.min(sx1, W); x++) {
      total++;
      const i = idx[y * W + x];
      if (i >= 0) { opaque++; counts[i] += i === OUTLINE ? outlineWeight : 1; }
    }
    if (!total || opaque / total < 0.45) continue;
    let best = 0;
    for (let i = 1; i < counts.length; i++) if (counts[i] > counts[best]) best = i;
    out[oy * w + ox] = best;
  }
  return { w, h, px: despeckle(out, w, h), row: p.row, col: poses.filter(q => q.row === p.row).indexOf(p) };
});

// Replaces fully isolated pixels (colour shared by none of the 8 neighbours) with the dominant
// neighbour colour when it clearly dominates. Outline pixels are kept, and never used as the
// replacement, so thin lines and small dark details (eyes) survive.
function despeckle(px, w, h) {
  const out = px.slice();
  const counts = new Map();
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const c = px[y * w + x];
    if (c < 0 || c === OUTLINE) continue;
    counts.clear();
    let same = 0;
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
      if (!dx && !dy) continue;
      const nx = x + dx, ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      const n = px[ny * w + nx];
      if (n === c) same++;
      else if (n >= 0 && n !== OUTLINE) counts.set(n, (counts.get(n) || 0) + 1);
    }
    if (same > 0) continue;
    let best = -1, bestN = 0;
    for (const [n, k] of counts) if (k > bestN) { best = n; bestN = k; }
    if (bestN >= 5) out[y * w + x] = best;
  }
  return out;
}

// ---------- pack into a sheet ----------
const cellW = Math.max(cellW0, ...sprites.map(s => s.w));
const cellH = Math.max(cellH0, ...sprites.map(s => s.h));
const sheet = createCanvas(cellW * Math.max(...rowSizes), cellH * bands.length);
const ctx = sheet.getContext('2d');
const outData = ctx.createImageData(sheet.width, sheet.height);
sprites.forEach(s => {
  // bottom-centre in its grid cell
  const ox = s.col * cellW + Math.floor((cellW - s.w) / 2), oy = s.row * cellH + cellH - s.h;
  for (let y = 0; y < s.h; y++) for (let x = 0; x < s.w; x++) {
    const i = s.px[y * s.w + x];
    if (i < 0) continue;
    const q = ((oy + y) * sheet.width + ox + x) * 4;
    [outData.data[q], outData.data[q + 1], outData.data[q + 2]] = palette[i];
    outData.data[q + 3] = 255;
  }
});
ctx.putImageData(outData, 0, 0);
fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, sheet.toBuffer('image/png'));
console.log(`sheet: ${output} (${bands.length}x${Math.max(...rowSizes)} grid of ${cellW}x${cellH}; sprites ${sprites.map(s => `${s.w}x${s.h}`).join(' ')})`);

// ---------- preview ----------
if (previewScale > 0) {
  const pv = createCanvas(sheet.width * previewScale, sheet.height * previewScale);
  const pctx = pv.getContext('2d');
  pctx.fillStyle = '#2b2b35';
  pctx.fillRect(0, 0, pv.width, pv.height);
  pctx.imageSmoothingEnabled = false;
  pctx.drawImage(sheet, 0, 0, pv.width, pv.height);
  const pvPath = output.replace(/\.png$/i, '_preview.png');
  fs.writeFileSync(pvPath, pv.toBuffer('image/png'));
  console.log(`preview: ${pvPath}`);
}

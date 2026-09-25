// Splits a pixelize.mjs grid sheet into one sheet per row (boss parts, characters with map
// and battle rows).
// Usage: node split_rows.mjs <sheet.png> <cellHeight> <out_row0.png> [<out_row1.png> ...]
//   pass "-" to skip a row.
import { createCanvas, loadImage } from '@napi-rs/canvas';
import fs from 'fs';

const [, , input, cellH, ...outs] = process.argv;
if (!input || !cellH || !outs.length) {
  console.error('usage: node split_rows.mjs <sheet.png> <cellHeight> <out_row0.png> [...]');
  process.exit(1);
}
const img = await loadImage(fs.readFileSync(input));
const h = Number(cellH);
outs.forEach((out, row) => {
  if (out === '-') return;
  const c = createCanvas(img.width, h);
  c.getContext('2d').drawImage(img, 0, row * h, img.width, h, 0, 0, img.width, h);
  fs.writeFileSync(out, c.toBuffer('image/png'));
  console.log(`row ${row} -> ${out} (${img.width}x${h})`);
});

// Downsamples full-scene art (title screens, backgrounds) to its native pixel grid by
// taking the dominant colour of each block, then upscales with nearest neighbour.
// Unlike pixelize.mjs it keeps the original colours (a 32-colour lock bands big scenes).
// Usage: node resize_art.mjs <input.png> <output.png> [--native 320x180] [--scale 2]
import { createCanvas, loadImage } from '@napi-rs/canvas';
import fs from 'fs';

const args = process.argv.slice(2);
const opt = (name, def) => { const i = args.indexOf(`--${name}`); return i >= 0 ? args[i + 1] : def; };
// Positional arguments are the ones that are neither a --flag nor a flag's value.
const [input, output] = args.filter((a, i) => !a.startsWith('--') && !(i > 0 && args[i - 1].startsWith('--')));
const [nw, nh] = opt('native', '320x180').split('x').map(Number);
const scale = Number(opt('scale', 2));

const img = await loadImage(fs.readFileSync(input));
const src = createCanvas(img.width, img.height);
const sctx = src.getContext('2d');
sctx.drawImage(img, 0, 0);
const data = sctx.getImageData(0, 0, img.width, img.height).data;

const small = createCanvas(nw, nh);
const out = small.getContext('2d').createImageData(nw, nh);
const bx = img.width / nw, by = img.height / nh;
for (let y = 0; y < nh; y++) for (let x = 0; x < nw; x++) {
  // Dominant colour (quantised to 5 bits per channel for voting), averaged within its bucket.
  const votes = new Map();
  for (let sy = Math.floor(y * by); sy < Math.floor((y + 1) * by); sy++) {
    for (let sx = Math.floor(x * bx); sx < Math.floor((x + 1) * bx); sx++) {
      const p = (sy * img.width + sx) * 4;
      const key = (data[p] >> 3) << 10 | (data[p + 1] >> 3) << 5 | (data[p + 2] >> 3);
      const v = votes.get(key) || [0, 0, 0, 0];
      v[0]++; v[1] += data[p]; v[2] += data[p + 1]; v[3] += data[p + 2];
      votes.set(key, v);
    }
  }
  let best = null;
  for (const v of votes.values()) if (!best || v[0] > best[0]) best = v;
  const q = (y * nw + x) * 4;
  out.data[q] = best[1] / best[0]; out.data[q + 1] = best[2] / best[0]; out.data[q + 2] = best[3] / best[0]; out.data[q + 3] = 255;
}
small.getContext('2d').putImageData(out, 0, 0);
const big = createCanvas(nw * scale, nh * scale);
const bctx = big.getContext('2d');
bctx.imageSmoothingEnabled = false;
bctx.drawImage(small, 0, 0, nw * scale, nh * scale);
fs.writeFileSync(output, big.toBuffer('image/png'));
console.log(`written ${output} (${nw}x${nh} native, ${nw * scale}x${nh * scale})`);

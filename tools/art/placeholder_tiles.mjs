// Generates a tiny placeholder tileset (16×16 tiles, Velmora 32 colours) for the Phase 1
// prototype, until Codex tilesets exist. Tiles, left to right: grass, path, stone wall, water.
// Usage: node placeholder_tiles.mjs [output.png]
import { createCanvas } from '@napi-rs/canvas';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const out = process.argv[2] || path.join(here, '../../game/assets/tilesets/til_placeholder.png');
const T = 16;
const tiles = [
  { base: '#6fa84a', dots: '#3b6b3a', light: '#b6d97a' },      // grass
  { base: '#c99a6b', dots: '#8f6040', light: '#e9dcb4' },      // path
  { base: '#6c6a70', dots: '#3c3a44', light: '#a8a4a0', wall: true }, // stone wall
  { base: '#34568f', dots: '#1f2f5a', light: '#5a8bc4', waves: true }, // water
];

// Deterministic pseudo-random so the file is stable between runs.
let seed = 7;
const rand = () => ((seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff);

const canvas = createCanvas(T * tiles.length, T);
const ctx = canvas.getContext('2d');
tiles.forEach((t, i) => {
  const x0 = i * T;
  ctx.fillStyle = t.base;
  ctx.fillRect(x0, 0, T, T);
  if (t.wall) {
    // brick courses with dark mortar and a light top edge
    ctx.fillStyle = t.dots;
    for (let y = 0; y < T; y += 4) ctx.fillRect(x0, y, T, 1);
    for (let y = 0; y < T; y += 4) {
      const offset = (y / 4) % 2 ? 0 : 4;
      for (let x = offset; x < T; x += 8) ctx.fillRect(x0 + x, y, 1, 4);
    }
    ctx.fillStyle = t.light;
    ctx.fillRect(x0, 1, T, 1);
    return;
  }
  if (t.waves) {
    ctx.fillStyle = t.light;
    for (const [x, y] of [[2, 3], [9, 7], [4, 11], [12, 13]]) ctx.fillRect(x0 + x, y, 3, 1);
    return;
  }
  for (let k = 0; k < 10; k++) {
    ctx.fillStyle = k % 3 ? t.dots : t.light;
    ctx.fillRect(x0 + Math.floor(rand() * T), Math.floor(rand() * T), 1, 1);
  }
});
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, canvas.toBuffer('image/png'));
console.log('written', out);

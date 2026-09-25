// Generates music with Suno through the "suno-music" MCP server (AceDataCloud) configured in
// ~/.claude.json, waits for the task and downloads every variant.
// Usage: node suno_gen.mjs <args.json> <outDir> <baseName>
//   -> <outDir>/<baseName>_a.mp3, _b.mp3 ... and <outDir>/<baseName>_task.json
// The bearer token is read from the local config at runtime and never printed.
import fs from 'fs';
import os from 'os';
import path from 'path';

const [, , argsFile, outDir, baseName] = process.argv;
if (!argsFile || !outDir || !baseName) {
  console.error('usage: node suno_gen.mjs <args.json> <outDir> <baseName>');
  process.exit(1);
}

const cfg = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.claude.json'), 'utf8'));
const entry = Object.values(cfg.projects || {}).find(p => p.mcpServers?.['suno-music']);
if (!entry) { console.error('suno-music MCP server not configured'); process.exit(1); }
const server = entry.mcpServers['suno-music'];
const headers = { 'Content-Type': 'application/json', Accept: 'application/json, text/event-stream', ...(server.headers || {}) };

let session;
let seq = 0;
async function rpc(method, params, notify = false) {
  const body = { jsonrpc: '2.0', method, ...(params ? { params } : {}), ...(notify ? {} : { id: ++seq }) };
  const res = await fetch(server.url, { method: 'POST', headers: { ...headers, ...(session ? { 'Mcp-Session-Id': session } : {}) }, body: JSON.stringify(body) });
  session = res.headers.get('mcp-session-id') || session;
  const text = await res.text();
  if (notify) return null;
  const json = text.trim().startsWith('{') ? text : text.split('\n').filter(l => l.startsWith('data:')).map(l => l.slice(5).trim()).pop();
  return JSON.parse(json);
}
async function tool(name, args) {
  const r = await rpc('tools/call', { name, arguments: args });
  const text = (r.result?.content || []).map(c => c.text || '').join('\n');
  if (r.error || r.result?.isError) throw new Error(`${name}: ${text || JSON.stringify(r.error)}`);
  return JSON.parse(text);
}

await rpc('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'rpg-suno-gen', version: '1.0' } });
await rpc('notifications/initialized', undefined, true);

const submitted = await tool('suno_generate_custom_music', JSON.parse(fs.readFileSync(argsFile, 'utf8')));
const taskId = submitted.task_id;
console.log('task', taskId);

let task;
for (let i = 0; i < 60; i++) {
  await new Promise(r => setTimeout(r, 15000));
  task = await tool('suno_get_task', { task_id: taskId });
  const items = task.response?.data || [];
  if (items.length && items.every(d => d.state === 'succeeded' && d.audio_url)) break;
  if (items.some(d => d.state === 'failed') || task.response?.success === false) throw new Error('task failed');
}
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, `${baseName}_task.json`), JSON.stringify(task.response, null, 2));
const letters = 'abcdefgh';
for (const [i, item] of (task.response?.data || []).entries()) {
  const file = path.join(outDir, `${baseName}_${letters[i]}.mp3`);
  const audio = await fetch(item.audio_url);
  fs.writeFileSync(file, Buffer.from(await audio.arrayBuffer()));
  console.log(`saved ${file} (${Math.round(item.duration)} s)`);
}

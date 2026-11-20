import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';

const banned = /\b(?:profit|earn|passive|make money|guaranteed|rewards)\b/iu;
const extensions = new Set(['.css', '.html', '.js', '.jsx', '.ts', '.tsx']);
const root = path.resolve(process.argv[2] ?? 'apps/web');
const hits = [];

async function walk(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      if (!['.next', 'node_modules'].includes(entry.name)) await walk(target);
      continue;
    }
    if (!extensions.has(path.extname(entry.name))) continue;
    const lines = (await readFile(target, 'utf8')).split('\n');
    lines.forEach((line, index) => { if (banned.test(line)) hits.push(`${path.relative(process.cwd(), target)}:${index + 1}`); });
  }
}

await walk(root);
if (hits.length) {
  console.error(`Banned copy found:\n${hits.join('\n')}`);
  process.exit(1);
}
console.log(`Copy check passed: ${root}`);

import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const alerts = [];
const messages = [];
globalThis.alert = message => alerts.push(message);
const originalLog = console.log;
console.log = message => messages.push(message);
try {
  const source = await readFile(new URL('../src/awesome.js', import.meta.url), 'utf8');
  const entry = await readFile(new URL('../main.js', import.meta.url), 'utf8');
  const moduleUrl = 'data:text/javascript;base64,' + Buffer.from(source).toString('base64');
  assert.match(entry, /import Awesome from ['"]\.\/src\/awesome\.js['"]/);
  await import('data:text/javascript;base64,' + Buffer.from(entry.replace('./src/awesome.js', moduleUrl)).toString('base64'));
  assert.deepEqual(alerts, ['your crap website is now been awesome sauced']);
  assert.deepEqual(messages, [
    'your crap website website is now awesome',
    'your crap website website is now more awesome',
  ]);
} finally {
  console.log = originalLog;
  delete globalThis.alert;
}

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

async function main() {
  const handlers = {}, documentHandlers = {}, sources = [];
  let context;
  class AudioContext {
    constructor() { this.state = 'suspended'; context = this; }
    createGain() { return {gain: {value: 1}, connect() {}}; }
    createBufferSource() {
      const source = {playbackRate: {}, connect() {}, start() {this.started = true;}, disconnect() {this.disconnected = true;}};
      sources.push(source); return source;
    }
    resume() { this.state = 'running'; return Promise.resolve(); }
    decodeAudioData() { return Promise.resolve({decoded: true}); }
  }
  const doc = {hidden: false, addEventListener(name, fn) {documentHandlers[name] = fn;}, querySelectorAll() {return [];}};
  const audio = vm.createContext({window: {AudioContext}, document: doc, navigator: {userAgent: 'iPhone', platform: 'iPhone', maxTouchPoints: 1}, console,
    fetch: async () => ({ok: true, arrayBuffer: async () => new ArrayBuffer(4)})});
  vm.runInContext(fs.readFileSync('web/audio.js', 'utf8'), audio);
  audio.sfxLoad('combo', '/assets/combo.wav');
  await new Promise(resolve => setImmediate(resolve));
  audio.sfxSetVolume(0.3);
  audio.sfxPlay('combo', 1.2); audio.sfxPlay('combo', 1.3);
  assert.equal(sources.length, 2);
  assert.equal(sources[1].playbackRate.value, 1.3);
  assert.equal(audio._sfxGain.gain.value, 0.3);
  sources[0].onended(); assert.equal(sources[0].disconnected, true);
  doc.hidden = true; audio.sfxPlay('combo'); assert.equal(sources.length, 2);
  doc.hidden = false; context.state = 'interrupted'; documentHandlers.pointerdown();
  assert.equal(context.state, 'running');

  let skipped = 0, claimed = 0;
  const deleted = [], added = [];
  const cache = {addAll: async items => added.push(...items), match: async key => String(key).endsWith('index.html') ? 'offline-shell' : undefined};
  const self = {location: {origin: 'https://example.test'}, registration: {scope: 'https://example.test/game/'},
    clients: {claim: async () => claimed++}, skipWaiting() {skipped++;}, addEventListener(name, fn) {handlers[name] = fn;}};
  const worker = vm.createContext({self, URL, caches: {open: async () => cache, keys: async () => ['unrelated-app', 'hukuk-games-old', 'hukuk-games-test'], delete: async key => deleted.push(key)}, fetch: async () => 'network'});
  const source = fs.readFileSync('web/sw.js','utf8').replace('__BUILD_VERSION__','test').replace('__CORE_FILES__','["index.html"]');
  vm.runInContext(source, worker);
  let pending;
  handlers.install({waitUntil(p) {pending = p;}}); await pending;
  assert.equal(skipped, 0); assert.deepEqual(added, ['index.html']);
  handlers.activate({waitUntil(p) {pending = p;}}); await pending;
  assert.deepEqual(deleted, ['hukuk-games-old']); assert.equal(claimed, 1);
  handlers.message({data: 'skipWaiting'}); assert.equal(skipped, 1);
  let response;
  handlers.fetch({request: {method: 'GET', url: 'https://example.test/game/', mode: 'navigate', headers: {has: () => false}}, respondWith(p) {response = p;}});
  assert.equal(await response, 'offline-shell');
  response = null;
  handlers.fetch({request: {method: 'GET', url: 'https://example.test/game/song.m4a', headers: {has: () => true}}, respondWith(p) {response = p;}});
  assert.equal(response, null); // Safari range requests must reach the server.
  console.log('Web audio and offline/update lifecycle checks passed.');
}
main().catch(error => {console.error(error); process.exitCode = 1;});

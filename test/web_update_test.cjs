const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
async function boot({pending, page = 'new', active = 'new', waiting = true} = {}) {
  const events = {}, swEvents = {}, elements = [], storage = new Map(pending ? [['hukuk-update-pending', pending]] : []);
  let reloads = 0, skips = 0;
  function element() { return {children: [], classList: {add() {}, remove() {}}, setAttribute() {}, append(...items) {this.children.push(...items);}, appendChild(item) {this.children.push(item);}, remove() {this.removed = true;}}; }
  function worker(version) { return {postMessage(message, ports) {
    if (message === 'getVersion') ports[0].reply({data: version});
    else if (message === 'skipWaiting') skips++;
  }}; }
  const target = worker('new');
  const reg = {waiting: waiting ? target : null, addEventListener() {}};
  const sw = {controller: worker(active), addEventListener(name, fn) {swEvents[name] = fn;}, async register() {return reg;}};
  const ctx = {document: {querySelector: () => ({content: page}), getElementById: id => elements.findLast(e => e.id === id && !e.removed), createElement: element, body: {appendChild(e) {elements.push(e);}}, addEventListener() {}},
    navigator: {serviceWorker: sw}, window: {addEventListener(name, fn) {events[name] = fn;}, location: {reload() {reloads++;}}},
    sessionStorage: {getItem: k => storage.get(k), setItem: (k,v) => storage.set(k,v), removeItem: k => storage.delete(k)},
    MessageChannel: class { constructor() {this.port1 = {close() {}}; this.port2 = {reply: e => this.port1.onmessage(e)};} },
    setTimeout: () => 1, clearTimeout() {}, console};
  vm.runInNewContext(fs.readFileSync('web/update.js', 'utf8'), ctx);
  await events['flutter-first-frame']();
  return {elements, sw, target, storage, change: swEvents.controllerchange, reloads: () => reloads, skips: () => skips};
}
(async () => {
  const app = await boot();
  const button = app.elements.at(-1).children.at(-1);
  await button.onclick(); await button.onclick();
  assert.equal(app.skips(), 1);
  assert.equal(button.disabled, true);
  app.change(); assert.equal(app.reloads(), 0);
  app.sw.controller = app.target;
  app.change(); app.change(); assert.equal(app.reloads(), 1);
  assert.equal(app.storage.get('hukuk-update-pending'), 'new');
  const updated = await boot({pending: 'new', waiting: false});
  assert.equal(updated.elements.at(-1).className, 'update-card success');
  assert.equal(updated.storage.size, 0);
  const stale = await boot({pending: 'new', page: 'old', waiting: false});
  assert.equal(stale.elements.length, 0);
  const first = await boot({waiting: false});
  assert.equal(first.elements.length, 0);
  console.log('Single reload, duplicate clicks, verified success, stale page and normal startup passed.');
})().catch(error => {console.error(error); process.exitCode = 1;});

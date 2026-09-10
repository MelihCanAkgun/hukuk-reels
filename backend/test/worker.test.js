import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker, {tokenHash, validSubscription, deliver} from '../src/worker.js';

const tokens = ['a'.repeat(43), 'b'.repeat(43)];
async function setup() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  for (let i=0;i<2;i++) db.prepare('INSERT INTO players(id, token_hash, name, active) VALUES (?, ?, ?, 1)')
    .run(i+1, await tokenHash(tokens[i]), ['Melih','Arkadaş'][i]);
  const env = {APP_ORIGIN:'https://app.example', APP_URL:'https://app.example/', DB:{prepare(sql) {
    let args=[];
    const stmt = db.prepare(sql);
    return {bind(...values){args=values;return this;}, async first(){return stmt.get(...args) || null;},
      async all(){return {results:stmt.all(...args)};}, async run(){return stmt.run(...args);}};
  }}};
  async function call(path, data, id=0, origin=env.APP_ORIGIN) {
    const pending=[];
    const response = await worker.fetch(new Request('https://worker.example'+path, {
      method: data === undefined ? 'GET':'POST', headers:{Origin:origin, Authorization:'Bearer '+tokens[id]},
      ...(data === undefined ? {} : {body:JSON.stringify(data)}),
    }), env, {waitUntil(p){pending.push(p);}});
    await Promise.all(pending);
    return {status:response.status, data:await response.json()};
  }
  return {db, env, call};
}
test('only two private players; bad origin and tokens cannot read scores', async()=>{
  const {db,call}=await setup();
  assert.equal((await call('/board')).data.players.length,2);
  assert.equal((await call('/board',undefined,2)).status,401);
  assert.equal((await call('/board',undefined,0,'https://evil.example')).status,403);
  assert.throws(()=>db.prepare("INSERT INTO players(id,token_hash,name) VALUES(3,'x','x')").run());
});
test('scores never decrease; overtakes notify once, ties do not notify', async()=>{
  const {db,call}=await setup();
  await call('/score',{score:100});
  assert.equal(db.prepare('SELECT COUNT(*) n FROM notifications').get().n,1);
  await call('/score',{score:100});
  await call('/score',{score:90});
  await call('/score',{score:100},1);
  assert.equal(db.prepare('SELECT COUNT(*) n FROM notifications').get().n,1);
  await call('/score',{score:110},1);
  assert.equal(db.prepare('SELECT COUNT(*) n FROM notifications').get().n,2);
  const event=db.prepare('SELECT * FROM notifications ORDER BY id DESC LIMIT 1').get();
  assert.equal(event.player_id,1);
  assert.match(event.body,/Arkadaş senin skorunu geçti/);
  await call('/score',{score:120},1);
  assert.equal(db.prepare('SELECT COUNT(*) n FROM notifications').get().n,2);
  assert.equal((await call('/score',{score:-1})).status,400);
  assert.equal((await call('/score',{score:1.5})).status,400);
});
test('manual message requires recipient permission and has cooldown', async()=>{
  const {db,call}=await setup();
  assert.equal((await call('/message',{message:'Oynayalım mı?'})).status,400);
  // Exercise enqueue without making an external push request.
  db.prepare("INSERT INTO subscriptions VALUES('fake',2,'{}')").run();
  assert.equal((await call('/message',{message:'Oynayalım mı?'})).status,200);
  assert.equal((await call('/message',{message:'Tekrar'})).status,429);
  assert.equal((await call('/message',{message:'x'.repeat(181)})).status,400);
});
test('subscription gateways cannot be arbitrary servers',()=>{
  const s={endpoint:'https://web.push.apple.com/abc',keys:{p256dh:'A'.repeat(87),auth:'B'.repeat(22)}};
  assert.equal(validSubscription(s),true);
  assert.equal(validSubscription({...s,endpoint:'https://127.0.0.1/'}),false);
  assert.equal(validSubscription({...s,endpoint:'https://web.push.apple.com.evil.example/'}),false);
  assert.equal(validSubscription({...s,endpoint:'http://web.push.apple.com/'}),false);
});
test('expired subscriptions are deleted; transient failure remains queued',async()=>{
  const {db,env}=await setup();
  db.prepare("INSERT INTO subscriptions VALUES('expired',2,'{}')").run();
  db.prepare("INSERT INTO notifications(player_id,title,body) VALUES(2,'Test','Test')").run();
  await deliver(env,async()=>410);
  assert.equal(db.prepare('SELECT COUNT(*) n FROM subscriptions').get().n,0);
  assert.equal(db.prepare('SELECT sent FROM notifications').get().sent,1);
  db.prepare("INSERT INTO subscriptions VALUES('retry',2,'{}')").run();
  db.prepare("INSERT INTO notifications(player_id,title,body) VALUES(2,'Test2','Test2')").run();
  await deliver(env,async()=>503);
  const item=db.prepare('SELECT * FROM notifications ORDER BY id DESC LIMIT 1').get();
  assert.equal(item.sent,0);
  assert.equal(item.attempts,1);
  let calls=0;
  await deliver(env,async()=>{calls++;return 201;});
  assert.equal(calls,0, 'active lease must not be delivered twice');
});

test('player two cannot send manual notifications or spoof admin identity', async()=>{
  const {db,call}=await setup();
  for (const payload of [{message:'Test'}, {message:'Test',id:1,me:1,admin:true}]) {
    assert.equal((await call('/message',payload,1)).status,403);
  }
  assert.equal(db.prepare('SELECT COUNT(*) n FROM notifications').get().n,0);
  assert.equal(db.prepare('SELECT last_message FROM players WHERE id=2').get().last_message,0);
  db.prepare('UPDATE players SET active=0 WHERE id=2').run();
  assert.equal((await call('/message',{message:'Test'},1)).status,403);
});

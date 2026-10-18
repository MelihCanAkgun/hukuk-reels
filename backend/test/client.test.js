import {test} from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
const source=readFileSync(new URL('../../web/social.js',import.meta.url),'utf8');
function client({push = false} = {}) {
  const saved=new Map(); const timers=[]; const requests=[]; let offline=false; let best=0; const scores={};
  const window={addEventListener(){}};
  const sub = {endpoint:'https://web.push.apple.com/test', toJSON(){return {endpoint:this.endpoint, keys:{p256dh:'A'.repeat(87),auth:'B'.repeat(22)}};}};
  const notification = {permission:'granted'};
  const navigator = push ? {serviceWorker:{getRegistration:async()=>({pushManager:{getSubscription:async()=>sub}})}} : {};
  if (push) { window.PushManager = {}; window.Notification = notification; }
  const context=vm.createContext({window,document:{hidden:false,addEventListener(){}},navigator,
    ...(push ? {Notification:notification} : {}),
    localStorage:{getItem:k=>saved.get(k),setItem:(k,v)=>saved.set(k,v)},
    setTimeout:fn=>timers.push(fn),clearTimeout(){},setInterval(){},AbortSignal,
    fetch:async(url,init)=>{
      requests.push({url,body:init.body});
      if(offline) throw new Error('Offline');
      const data=init.body?JSON.parse(init.body):{};
      if(url.endsWith('/score')) {
        if(data.game) scores[data.game]=Math.max(scores[data.game]||0,data.score);
        else best=Math.max(best,data.score);
      }
      return {ok:true,json:async()=>({me:1,players:[{id:1,best,name:'A'},{id:2,best:100,name:'B'}],
        scores:Object.entries(scores).map(([game,b])=>({id:1,game,best:b}))})};
    }});
  vm.runInContext(source,context);
  return {saved,requests,timers,context,offline:v=>offline=v,
    call:async(action,data={})=>JSON.parse(await window.hukukSocialCall(action,JSON.stringify(data)))};
}
test('offline personal best survives and is submitted after reconnection',async()=>{
  const c=client();
  await c.call('init',{url:'https://worker.example'});
  await c.call('join',{token:'a'.repeat(43),name:'A',score:50});
  c.offline(true);
  await c.call('score',{score:150});
  await c.timers.pop()();
  assert.equal(JSON.parse(c.saved.get('hukuk_social_v1')).best,150);
  await c.call('score',{score:75});
  assert.equal(JSON.parse(c.saved.get('hukuk_social_v1')).best,150);
  c.offline(false);
  await c.call('state');
  await new Promise(r=>setImmediate(r));
  assert.equal((await c.call('state')).players[0].best,150);
});
test('a device without an invite never uploads a score',async()=>{
  const c=client();
  await c.call('init',{url:'https://worker.example'});
  await c.call('score',{score:200});
  assert.equal(c.requests.length,0);
  assert.match((await c.call('join',{token:'bad',name:'A'})).error,/kodunu/);
});

test('an existing browser permission repairs missing server registration once',async()=>{
  const c=client({push:true});
  await c.call('init',{url:'https://worker.example'});
  const joined=await c.call('join',{token:'a'.repeat(43),name:'A',score:0});
  assert.equal(joined.subscribed,true);
  assert.equal(c.requests.filter(r=>r.url.endsWith('/subscribe')).length,1);
  await c.call('state');
  await c.call('state');
  assert.equal(c.requests.filter(r=>r.url.endsWith('/subscribe')).length,1);
});
test('failed registration is shown truthfully and retried when online',async()=>{
  const c=client({push:true});
  await c.call('init',{url:'https://worker.example'});
  await c.call('join',{token:'a'.repeat(43),name:'A',score:0});
  // A new page/session must check its server registration again.
  c.offline(true);
  vm.runInContext(source,c.context);
  await c.call('init',{url:'https://worker.example'});
  const offline=await c.call('state');
  assert.equal(offline.subscribed,false);
  assert.match(offline.pushError,/kaydedilemedi/);
  c.offline(false);
  assert.equal((await c.call('state')).subscribed,true);
});

test('arcade games keep separate bests and upload only what the server lacks',async()=>{
  const c=client();
  await c.call('init',{url:'https://worker.example'});
  await c.call('join',{token:'a'.repeat(43),name:'A',score:40,scores:{flappy:9,tower:3,subway:-1}});
  const scoreBodies=()=>c.requests.filter(r=>r.url.endsWith('/score')).map(r=>JSON.parse(r.body));
  assert.deepEqual(scoreBodies(),[{score:40},{game:'flappy',score:9},{game:'tower',score:3}]);
  await c.call('score',{game:'flappy',score:7});
  assert.equal(c.timers.length,0);
  c.offline(true);
  await c.call('score',{game:'subway',score:250});
  await c.timers.pop()();
  const offline=await c.call('state',{});
  assert.deepEqual(offline.pendingGames,['subway']);
  assert.equal(JSON.parse(c.saved.get('hukuk_social_v1')).bests.subway,250);
  c.offline(false);
  await c.call('state');
  await new Promise(r=>setImmediate(r));
  const online=await c.call('state');
  assert.equal(online.pending,false);
  assert.equal(online.scores.find(r=>r.game==='subway').best,250);
  assert.equal(online.players[0].best,40);
  assert.match((await c.call('score',{game:'chess',score:1})).error,/Geçersiz oyun/);
  await c.call('leave');
  assert.deepEqual(JSON.parse(c.saved.get('hukuk_social_v1')).bests,{});
});
test('activity: an entry on join, none without a code; admin view is a GET',async()=>{
  const c=client();
  const seen=()=>c.requests.filter(r=>r.url.endsWith('/seen')).map(r=>JSON.parse(r.body));
  await c.call('init',{url:'https://worker.example'});
  assert.deepEqual(seen(),[]);
  await c.call('join',{token:'a'.repeat(43),name:'A',score:0});
  assert.deepEqual(seen(),[{open:true,device:'other',area:'home'}]);
  // Another init right after does not count as a new entry.
  await c.call('init',{url:'https://worker.example'});
  assert.equal(seen().length,1);
  const r=await c.call('activity');
  assert.equal(r.connected,true);
  assert.ok(c.requests.at(-1).url.endsWith('/activity'));
  assert.equal(c.requests.at(-1).body,undefined);
});
test('activity: changing area reports once after a short pause',async()=>{
  const c=client();
  const seen=()=>c.requests.filter(r=>r.url.endsWith('/seen')).map(r=>JSON.parse(r.body));
  await c.call('init',{url:'https://worker.example'});
  await c.call('join',{token:'a'.repeat(43),name:'A',score:0});
  const before=c.timers.length;
  await c.call('area',{area:'flappy'});
  await c.call('area',{area:'block'});
  await c.call('area',{area:'block'});
  assert.equal(c.timers.length,before+2, 'one timer per change, none for the same area');
  await c.timers.at(-1)();
  await new Promise(r=>setImmediate(r));
  assert.deepEqual(seen().at(-1),{open:false,device:'other',area:'block'});
});

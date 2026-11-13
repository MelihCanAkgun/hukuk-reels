import {test} from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
const source=readFileSync(new URL('../../web/social.js',import.meta.url),'utf8');
function client({push = false, stored} = {}) {
  const saved=new Map(stored ? [['hukuk_social_v1', JSON.stringify(stored)]] : []); const timers=[]; const requests=[]; let offline=false; let best=0; const scores={}; let round=null; const weekly={}; const films=[{id:1,title:'A'}];
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
      if(url.includes('/weekly')) {
        if(url.endsWith('/weekly/start')) round={id:1,start:Math.floor(Date.now()/1000)-5,end:Math.floor(Date.now()/1000)+600};
        if(url.endsWith('/weekly/score')&&round&&data.at>=round.start) weekly[data.game]=Math.max(weekly[data.game]||0,data.score);
        return {ok:true,json:async()=>({me:1,round,scores:Object.entries(weekly).map(([game,b])=>({player:1,game,best:b}))})};
      }
      if(url.endsWith('/films')) return {ok:true,json:async()=>({films,me:1,now:Date.now()})};
      if(url.endsWith('/score')) {
        if(data.game) scores[data.game]=Math.max(scores[data.game]||0,data.score);
        else best=Math.max(best,data.score);
      }
      return {ok:true,json:async()=>({me:1,players:[{id:1,best,name:'A'},{id:2,best:100,name:'B'}],
        scores:Object.entries(scores).map(([game,b])=>({id:1,game,best:b}))})};
    }});
  vm.runInContext(source,context);
  return {saved,requests,timers,context,films,offline:v=>offline=v,
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
  const scoreBodies=()=>c.requests.filter(r=>r.url.endsWith('/score')&&!r.url.includes('/weekly')).map(r=>JSON.parse(r.body));
  assert.deepEqual(scoreBodies(),[{score:40,season:2},{game:'flappy',score:9},{game:'tower',score:3}]);
  // No new record: only the challenge copy is queued (the round is unknown yet).
  await c.call('score',{game:'flappy',score:7});
  await c.timers.pop()();
  assert.equal(scoreBodies().length,3);
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
test('a new Block Blast season zeroes this device\'s stored record only',async()=>{
  const c=client({stored:{url:'https://worker.example',token:'a'.repeat(43),best:9000,bests:{flappy:4}}});
  const kept=JSON.parse(c.saved.get('hukuk_social_v1'));
  assert.equal(kept.best,0);
  assert.equal(kept.legacyBest,9000);
  assert.equal(kept.blockSeason,2);
  assert.deepEqual(kept.bests,{flappy:4});
  await c.call('state');
  await new Promise(r=>setImmediate(r));
  const uploads=c.requests.filter(r=>r.url.endsWith('/score')).map(r=>JSON.parse(r.body));
  // The old best goes once without a season (the worker keeps it only if it
  // beats the archived record); it is not resent as a season 2 score.
  assert.deepEqual(uploads,[{score:9000},{game:'flappy',score:4}]);
  assert.equal(JSON.parse(c.saved.get('hukuk_social_v1')).legacyBest,undefined);
  await c.call('state');
  await new Promise(r=>setImmediate(r));
  assert.equal(c.requests.filter(r=>r.url.endsWith('/score')).length,2);
});
test('challenge: played scores go to the round; old ones and sync copies do not',async()=>{
  const c=client();
  const sent=()=>c.requests.filter(r=>r.url.endsWith('/weekly/score')).map(r=>JSON.parse(r.body));
  await c.call('init',{url:'https://worker.example'});
  await c.call('join',{token:'a'.repeat(43),name:'A',score:0});
  // No round (just checked): nothing is kept or sent.
  let w=await c.call('weekly');
  assert.equal(w.round,null);
  await c.call('score',{game:'flappy',score:5});
  assert.deepEqual(sent(),[]);
  w=await c.call('weeklyStart');
  assert.equal(w.round.id,1);
  await c.call('score',{game:'tower',score:30,sync:true});     // opening the game syncs the old record
  await c.call('score',{game:'tower',score:4});
  await c.timers.pop()();
  await c.call('score',{game:'tower',score:3});                // lower in the same round: not sent
  await c.call('score',{game:'tower',score:9});
  await c.timers.pop()();
  assert.deepEqual(sent().map(b=>[b.game,b.score]),[['tower',4],['tower',9]]);
  assert.ok(sent().every(b=>Number.isSafeInteger(b.at)));
  // Offline: the score shows at once and is sent when the connection is back.
  c.offline(true);
  await c.call('score',{game:'subway',score:120});
  await c.timers.pop()();
  w=await c.call('weekly');
  assert.equal(w.offline,true);
  assert.equal(w.localBests.subway,120);
  c.offline(false);
  w=await c.call('weekly');
  assert.equal(w.scores.find(s=>s.game==='subway').best,120);
  assert.equal(w.localBests.subway,0);
  // Block Blast reports every move: no immediate request, the periodic flush sends it.
  const timers=c.timers.length;
  await c.call('score',{score:10});
  await c.call('score',{score:25});
  assert.equal(c.timers.length-timers,2);                       // only the all-time record timers
  await c.call('leave');
  assert.deepEqual(JSON.parse(c.saved.get('hukuk_social_v1')).plays,{});
});
test('lists open from the device copy first; an unchanged reply is short',async()=>{
  const c=client();
  await c.call('init',{url:'https://worker.example'});
  await c.call('join',{token:'a'.repeat(43),name:'A',score:0});
  const gets=()=>c.requests.filter(r=>r.url.endsWith('/films')).length;
  // Nothing stored yet: the cached request falls through to the network.
  let r=await c.call('films',{cached:true});
  assert.equal(r.cached,undefined); assert.equal(r.films.length,1); assert.equal(gets(),1);
  // Same list (only `now` differs): Flutter keeps what it has.
  r=await c.call('films',{known:true});
  assert.deepEqual(r,{unchanged:true,connected:true});
  // A fresh start reads the stored copy without a request, even offline.
  c.offline(true);
  r=await c.call('films',{cached:true});
  assert.equal(r.cached,true); assert.equal(r.films[0].title,'A'); assert.equal(gets(),2);
  c.offline(false);
  c.films.push({id:2,title:'B'});
  r=await c.call('films',{known:true});
  assert.equal(r.films.length,2); assert.equal(r.unchanged,undefined);
  // Without `known` the full list always comes back.
  assert.equal((await c.call('films')).films.length,2);
});

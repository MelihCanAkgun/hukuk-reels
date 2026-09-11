import {test} from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
import {Miniflare,convertV4MiniflareOptions} from 'miniflare';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('../',import.meta.url));
const origin='https://app.example';
const tokens=['a'.repeat(43),'b'.repeat(43)];
async function server() {
  const bundle=await build({entryPoints:[root+'src/worker.js'],bundle:true,keepNames:true,format:'esm',platform:'node',
    external:['node:*'],write:false,banner:{js:"import {createRequire} from 'node:module'; const require=createRequire('/');"}});
  const mf=new Miniflare(convertV4MiniflareOptions({modules:true,script:bundle.outputFiles[0].text,
    compatibilityDate:'2026-09-10',compatibilityFlags:['nodejs_compat'],d1Databases:['DB'],
    durableObjects:{BATTLES:{className:'BattleRoom',useSQLite:true}},
    bindings:{APP_ORIGIN:origin,APP_URL:origin}}));
  const db=await mf.getD1Database('DB');
  await db.exec(readFileSync(root+'schema.sql','utf8').replaceAll('\n',' '));
  for(let i=0;i<2;i++) await db.prepare('INSERT INTO players(id,token_hash,name,active) VALUES(?,?,?,1)')
    .bind(i+1,createHash('sha256').update(tokens[i]).digest('hex'),'P'+(i+1)).run();
  const call=async(path,data,id=0)=>{
    const response=await mf.dispatchFetch('https://worker.example'+path,{method:'POST',
      headers:{Origin:origin,Authorization:'Bearer '+(tokens[id]||'invalid'),'Content-Type':'application/json'},
      body:JSON.stringify(data)});
    return {status:response.status,data:await response.json()};
  };
  const connect=async permit=>{
    const response=await mf.dispatchFetch('https://worker.example/battle/socket/'+permit.room+'?ticket='+permit.ticket,
      {headers:{Origin:origin,Upgrade:'websocket'}});
    assert.equal(response.status,101);
    const ws=response.webSocket;const messages=[];ws.accept();
    ws.addEventListener('message',event=>{if(event.data!=='pong') messages.push(JSON.parse(event.data));});
    const timer=setInterval(()=>{try{ws.send('ping');}catch{}},4000);
    return {ws,messages,send:d=>ws.send(JSON.stringify(d)),close(){clearInterval(timer);ws.close();},
      async until(predicate,timeout=6000){
        const end=Date.now()+timeout;
        while(Date.now()<end){const found=messages.findLast(predicate);if(found)return found;
          await new Promise(r=>setTimeout(r,20));}
        throw new Error('WebSocket condition timed out: '+JSON.stringify(messages.at(-1)));
      }};
  };
  return {mf,call,connect};
}

test('real sockets: auth, shared start, authoritative moves, duplicate/reconnect and forfeit', {timeout:35000},async()=>{
  const {mf,call,connect}=await server();const sockets=[];
  try {
    assert.equal((await call('/battle/create',{},2)).status,401);
    const created=await call('/battle/create',{id:2});
    assert.equal(created.status,200);assert.equal(created.data.me,1);
    const a=await connect(created.data);sockets.push(a);
    const joined=await call('/battle/join',{room:created.data.room},1);
    assert.equal(joined.status,200);
    const b=await connect(joined.data);sockets.push(b);
    await b.until(e=>e.state?.players.every(p=>p.connected));
    const state=(await a.until(e=>e.state?.players.every(p=>p.connected))).state;
    assert.equal(state.players.length,2);
    assert.deepEqual(state.players[0].game.tray,state.players[1].game.tray);
    // A one-use ticket cannot create an extra connection.
    const rejected=await mf.dispatchFetch('https://worker.example/battle/socket/'+joined.data.room+'?ticket='+joined.data.ticket,
      {headers:{Origin:origin,Upgrade:'websocket'}});
    assert.equal(rejected.status,401);
    a.send({type:'PLAYER_READY'});b.send({type:'PLAYER_READY'});
    const countdown=await a.until(e=>e.state?.status==='countdown');
    assert.ok(countdown.state.startAt-countdown.serverNow>2500);
    const started=await b.until(e=>e.state?.status==='playing');
    assert.equal(started.state.startAt,countdown.state.startAt);
    a.send({type:'PLACE_PIECE',moveId:1,slot:0,row:0,col:0,id:2,score:999999,lives:99});
    const first=await a.until(e=>e.state?.players[0].lastMove===1);
    assert.ok(first.state.players[0].game.score<20);
    assert.equal(first.state.players[1].game.score,0);
    const score=first.state.players[0].game.score;
    a.send({type:'PLACE_PIECE',moveId:1,slot:0,row:0,col:0});
    a.send({type:'PLACE_PIECE',moveId:2,slot:1,row:-20,col:0});
    await a.until(e=>e.type==='ERROR');
    assert.equal(a.messages.at(-1).state.players[0].game.score,score);
    b.send({type:'PLACE_PIECE',moveId:1,slot:0,row:0,col:0});
    const both=await b.until(e=>e.state?.players.every(p=>p.lastMove===1));
    assert.deepEqual(both.state.players[0].game.grid,both.state.players[1].game.grid);
    a.close();
    await b.until(e=>e.state?.players[0].connected===false);
    const rejoin=await call('/battle/join',{room:created.data.room});
    const again=await connect(rejoin.data);sockets.push(again);
    const recovered=await again.until(e=>e.state?.players[0].connected);
    assert.equal(recovered.state.players.length,2);
    assert.equal(recovered.state.players[0].lastMove,1);
    assert.equal(recovered.state.players[0].game.score,score);
    again.close();
    const result=await b.until(e=>e.state?.status==='finished',18000);
    assert.equal(result.state.winner,2);assert.equal(result.state.reason,'disconnect');
    b.send({type:'PLACE_PIECE',moveId:2,slot:1,row:0,col:0});
    await b.until(e=>e.type==='ERROR' && e.state?.status==='finished');
    assert.equal(b.messages.at(-1).state.players[1].lastMove,1);
  } finally {for(const s of sockets)try{s.close();}catch{} await mf.dispose();}
});

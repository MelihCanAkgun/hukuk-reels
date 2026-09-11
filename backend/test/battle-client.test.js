import {test} from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
const source=readFileSync(new URL('../../web/battle.js',import.meta.url),'utf8');
function client(storage=new Map()) {
  const sockets=[],timers=new Map();let index=0,fail=null;
  const state={roomId:'ABC234',revision:1,status:'playing',players:[{id:1,lastMove:0,connected:true},{id:2,lastMove:0,connected:true}]};
  class Socket {
    static OPEN=1;
    constructor(url){this.url=url;this.readyState=0;this.sent=[];sockets.push(this);}
    open(){this.readyState=1;this.onopen();}
    send(data){this.sent.push(data);}
    close(code=1006){this.readyState=3;this.onclose?.({code});}
    message(data){this.onmessage({data:JSON.stringify(data)});}
  }
  const window={addEventListener(){},async hukukSocialCall(){
    return JSON.stringify(fail || {room:'ABC234',me:1,ticket:'short-lived',url:'https://worker.example',state});
  }};
  const context=vm.createContext({window,document:{hidden:false,addEventListener(){}},localStorage:{
    getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)},
    URL,WebSocket:Socket,Date,JSON,setTimeout:fn=>{timers.set(++index,fn);return index;},
    clearTimeout:i=>timers.delete(i),setInterval:()=>++index,clearInterval(){}});
  vm.runInContext(source,context);
  const call=async(a,d={})=>JSON.parse(await window.hukukBattleCall(a,JSON.stringify(d)));
  const tick=async()=>{const [id,fn]=timers.entries().next().value;timers.delete(id);fn();await new Promise(r=>setImmediate(r));};
  return {sockets,call,tick,timers,storage,state,fail:v=>fail=v};
}
test('only placements cross socket; unacked move persists and replays with same ID',async()=>{
  const c=client();await c.call('create');const a=c.sockets[0];a.open();
  a.message({type:'STATE_UPDATE',state:c.state});
  await c.call('place',{slot:2,row:3,col:4,score:999999});
  assert.deepEqual(JSON.parse(a.sent.at(-1)),{type:'PLACE_PIECE',moveId:1,slot:2,row:3,col:4});
  assert.match((await c.call('place',{slot:0,row:0,col:0})).error,/Önceki/);
  a.close();await c.tick();const b=c.sockets[1];b.open();b.message({type:'STATE_UPDATE',state:c.state});
  assert.equal(JSON.parse(b.sent.at(-1)).moveId,1);
  const count=b.sent.length;b.message({type:'STATE_UPDATE',state:c.state});assert.equal(b.sent.length,count);
  c.state.players[0].lastMove=1;c.state.revision++;
  b.message({type:'STATE_UPDATE',state:c.state});
  assert.equal(JSON.parse(c.storage.get('hukuk_battle_v1')).pending,null);
  await c.call('leave');assert.equal(c.storage.size,0);
});
test('refresh uses saved room and already accepted move is never sent again',async()=>{
  const storage=new Map([['hukuk_battle_v1',JSON.stringify({room:'ABC234',me:1,pending:{type:'PLACE_PIECE',moveId:1,slot:0,row:0,col:0}})]]);
  const c=client(storage);c.state.players[0].lastMove=1;
  assert.equal((await c.call('inspect')).room,'ABC234');await c.call('resume');
  const ws=c.sockets[0];ws.open();ws.message({type:'STATE_UPDATE',state:c.state});
  assert.deepEqual(ws.sent,['ping']);
});
test('expired/invalid room stops retry; transient join failure keeps retry available',async()=>{
  const c=client();c.fail({error:'Oda yok',status:404});
  assert.equal((await c.call('join',{room:'ABC234'})).error,'Oda yok');assert.equal(c.timers.size,0);
  c.fail(null);await c.call('create');c.sockets[0].open();c.fail({error:'Offline'});
  c.sockets[0].close();await c.tick();assert.equal(c.timers.size,1);
});

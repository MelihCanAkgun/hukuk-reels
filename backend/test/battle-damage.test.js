import {test} from 'node:test';
import assert from 'node:assert/strict';
globalThis.self = globalThis;
await import('../generated/battle_rules.js');
const rules = data => JSON.parse(globalThis.blockBattleRules(JSON.stringify(data)));
function match() {
  let state;
  for (const id of [1, 2]) {
    for (const action of ['join', 'connect', 'ready']) {
      const result = rules({roomId:'ABC234', seed:123, state, action, id, name:`P${id}`, now:0});
      assert.equal(result.error, undefined);
      state = result.state;
    }
  }
  return rules({state, action:'advance', now:3000}).state;
}
const move = state => rules({state, action:'place', id:1, moveId:1, slot:0, row:0, col:0, now:3001});
test('compiled server applies cumulative 600 HP boundaries once, including restore/replay', () => {
  for (const target of [599,600,1199,1200,1800,2400,3000]) {
    const state=match(), p=state.players[0], prior=Math.floor((target-1)/600);
    p.game.score=target-1;p.game.tray=[[0,0],[0,1],null];p.thresholds=prior;p.damage=prior;
    state.players[1].lives=5-prior;
    const result=move(state);assert.equal(result.ok,true);
    assert.equal(result.state.players[0].game.score,target);
    assert.equal(result.state.players[0].damage,Math.floor(target/600));
    assert.equal(result.state.players[1].lives,5-Math.floor(target/600));
    assert.deepEqual(move(result.state).state,result.state);
  }
});
test('compiled server handles multi-threshold jumps and keeps post-board-out score progress', () => {
  for (const start of [590,1150]) {
    const state=match(),p=state.players[0];
    p.game.score=start;p.game.tray=[[0,0],[0,1],null];p.thresholds=Math.floor(start/600);
    p.game.grid[0]=[null,0,0,0,0,0,0,0];p.game.grid[7][7]=0;p.game.combo=start===590?13:69;
    const result=move(state);assert.equal(result.ok,true);
    assert.equal(result.state.players[0].damage,start===590?1:2);
  }
  const state=match(),p=state.players[0];
  p.game.grid=Array.from({length:8},(_,r)=>Array.from({length:8},(_,c)=>(r+c)%2===0?0:null));
  p.game.tray=[[0,0],[10,1],null];p.game.score=1798;p.thresholds=2;
  const reset=rules({state,action:'place',id:1,moveId:1,slot:0,row:0,col:1,now:3001});
  assert.equal(reset.state.players[0].lives,4);assert.equal(reset.state.players[0].game.score,1799);
  reset.state.players[0].game.tray=[[0,0],[0,1],null];
  const crossed=rules({state:reset.state,action:'place',id:1,moveId:2,slot:0,row:0,col:0,now:3002});
  assert.equal(crossed.state.players[0].game.score,1800);assert.equal(crossed.state.players[0].lives,4);
  assert.equal(crossed.state.players[1].lives,4);assert.equal(crossed.state.players[0].thresholds,3);
});

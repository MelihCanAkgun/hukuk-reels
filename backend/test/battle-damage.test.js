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
test('compiled server applies cumulative 500 HP boundaries once, including restore/replay', () => {
  for (const target of [499,500,999,1000,1500,2000,2500]) {
    const state=match(), p=state.players[0], prior=Math.floor((target-1)/500);
    p.game.score=target-1;p.game.tray=[[0,0],[0,1],null];p.thresholds=prior;p.damage=prior;
    state.players[1].lives=5-prior;
    const result=move(state);assert.equal(result.ok,true);
    assert.equal(result.state.players[0].game.score,target);
    assert.equal(result.state.players[0].damage,Math.floor(target/500));
    assert.equal(result.state.players[1].lives,5-Math.floor(target/500));
    assert.deepEqual(move(result.state).state,result.state);
  }
});
test('compiled server handles multi-threshold jumps and keeps post-board-out score progress', () => {
  for (const start of [490,950]) {
    const state=match(),p=state.players[0];
    p.game.score=start;p.game.tray=[[0,0],[0,1],null];p.thresholds=Math.floor(start/500);
    p.game.grid[0]=[null,0,0,0,0,0,0,0];p.game.grid[7][7]=0;p.game.combo=start===490?13:69;
    const result=move(state);assert.equal(result.ok,true);
    assert.equal(result.state.players[0].damage,start===490?1:2);
  }
  const state=match(),p=state.players[0];
  p.game.grid=Array.from({length:8},(_,r)=>Array.from({length:8},(_,c)=>(r+c)%2===0?0:null));
  p.game.tray=[[0,0],[10,1],null];p.game.score=1498;p.thresholds=2;
  const reset=rules({state,action:'place',id:1,moveId:1,slot:0,row:0,col:1,now:3001});
  assert.equal(reset.state.players[0].lives,4);assert.equal(reset.state.players[0].game.score,1499);
  reset.state.players[0].game.tray=[[0,0],[0,1],null];
  const crossed=rules({state:reset.state,action:'place',id:1,moveId:2,slot:0,row:0,col:0,now:3002});
  assert.equal(crossed.state.players[0].game.score,1500);assert.equal(crossed.state.players[0].lives,4);
  assert.equal(crossed.state.players[1].lives,4);assert.equal(crossed.state.players[0].thresholds,3);
});
test('compiled server handles rematch flow: single request waits, mutual request resets match cleanly', () => {
  const init=match();
  const finished=rules({state:init,action:'resign',id:2,now:3005}).state;
  assert.equal(finished.status,'finished');
  assert.equal(finished.winner,1);
  assert.equal(finished.round,1);

  // Player 1 requests rematch alone -> waits
  const req1=rules({state:finished,action:'rematch',id:1,now:3006});
  assert.equal(req1.state.status,'finished');
  assert.equal(req1.state.players[0].rematch,true);
  assert.equal(req1.state.players[1].rematch,false);
  assert.equal(req1.state.round,1);

  // Player 2 also requests rematch -> round 2 starts countdown
  const req2=rules({state:req1.state,action:'rematch',id:2,seed:999,now:3007});
  assert.equal(req2.state.status,'countdown');
  assert.equal(req2.state.round,2);
  assert.equal(req2.state.seed,999);
  assert.equal(req2.state.winner,null);
  assert.equal(req2.state.reason,null);
  assert.equal(req2.state.players[0].game.score,0);
  assert.equal(req2.state.players[1].game.score,0);
  assert.equal(req2.state.players[0].lives,5);
  assert.equal(req2.state.players[1].lives,5);
  assert.equal(req2.state.players[0].lastMove,0);
  assert.equal(req2.state.players[1].lastMove,0);
  assert.equal(req2.state.players[0].rematch,false);
  assert.equal(req2.state.players[1].rematch,false);

  // Old round move rejection test
  const oldMove=rules({state:req2.state,action:'place',id:1,moveId:1,slot:0,row:0,col:0,now:3008,round:1});
  assert.equal(oldMove.error,'Eski round hamlesi.');
});

import {test} from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';

test('generated Worker rules are current and match the native Dart match trace',async()=>{
  const root=fileURLToPath(new URL('../../',import.meta.url));
  const hashes=JSON.parse(readFileSync(new URL('../generated/battle_rules.sources.json',import.meta.url)));
  for(const [file,hash] of Object.entries(hashes)) {
    assert.equal(createHash('sha256').update(readFileSync(root+file)).digest('hex'),hash,
      'Run python3 tools/build_battle.py after changing shared rules');
  }
  globalThis.self=globalThis;
  await import('../generated/battle_rules.js');
  const output=execFileSync('dart',['run','backend/dart/battle_fixture.dart'],{cwd:root,encoding:'utf8'});
  const steps=JSON.parse(output.slice(output.indexOf('[{"command"')));
  let state;
  for(const {command,state:expected} of steps) {
    const result=JSON.parse(globalThis.blockBattleRules(JSON.stringify({roomId:'ABC234',seed:987654321,state,...command})));
    assert.equal(result.error,undefined);
    assert.deepEqual(result.state,expected);
    state=result.state;
  }
  assert.ok(steps.length>30);
  assert.equal(state.status,'finished');
});

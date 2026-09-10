import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createECDH, randomBytes} from 'node:crypto';
import webpush from 'web-push';
import {build} from 'esbuild';
import {Miniflare, convertV4MiniflareOptions} from 'miniflare';
import {fileURLToPath} from 'node:url';

test('push request is valid in Workers and never follows redirects', async()=>{
  const curve=createECDH('prime256v1');
  const fixture={subscription:{endpoint:'https://web.push.apple.com/not-a-real-device',
    keys:{p256dh:curve.generateKeys().toString('base64url'),auth:randomBytes(16).toString('base64url')}},
    vapid:webpush.generateVAPIDKeys()};
  const bundled=await build({stdin:{resolveDir:fileURLToPath(new URL('../',import.meta.url)),contents:`
    import {sendPush} from './src/worker.js';
    export default {async fetch(){
      const f=${JSON.stringify(fixture)};
      let requestInfo;
      const status=await sendPush(f.subscription,{title:'Test',body:'Test'},
        {VAPID_SUBJECT:'https://example.com',VAPID_PUBLIC_KEY:f.vapid.publicKey,VAPID_PRIVATE_KEY:f.vapid.privateKey},
        async(url,options)=>{
          // Validate in workerd, but never contact any real push gateway.
          const request=new Request(url,options);
          requestInfo={redirect:request.redirect,encoding:request.headers.get('content-encoding'),
            bytes:(await request.arrayBuffer()).byteLength};
          return new Response(null,{status:201});
        });
      return Response.json({status,...requestInfo});
    }};
  `},bundle:true,format:'esm',platform:'node',external:['node:*'],write:false,
    banner:{js:"import {createRequire} from 'node:module'; const require=createRequire('/');"}});
  const mf=new Miniflare(convertV4MiniflareOptions({modules:true,script:bundled.outputFiles[0].text,
    compatibilityDate:'2026-09-10',compatibilityFlags:['nodejs_compat']}));
  try {
    const result=await (await mf.dispatchFetch('http://localhost/')).json();
    assert.equal(result.status,201);
    assert.equal(result.redirect,'manual');
    assert.equal(result.encoding,'aes128gcm');
    assert.ok(result.bytes>100);
  } finally {await mf.dispose();}
});

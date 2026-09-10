// Run once. Secrets stay in a gitignored, mode-0700 folder; nothing is printed.
import {mkdirSync, existsSync, writeFileSync, chmodSync} from 'node:fs';
import {randomBytes, createHash} from 'node:crypto';
import webpush from 'web-push';
const dir = new URL('../.secrets/', import.meta.url);
mkdirSync(dir, {recursive:true,mode:0o700});
chmodSync(dir,0o700);
const secretFile = new URL('keys.json',dir);
if (existsSync(secretFile)) throw new Error('Secrets already exist; reuse them. Do not rotate accidentally.');
const keys = webpush.generateVAPIDKeys();
const players = [1,2].map(id=>({id,token:randomBytes(32).toString('base64url')}));
writeFileSync(secretFile,JSON.stringify({keys,players},null,2),{mode:0o600});
writeFileSync(new URL('vapid.json',dir),JSON.stringify({VAPID_PUBLIC_KEY:keys.publicKey,VAPID_PRIVATE_KEY:keys.privateKey}),{mode:0o600});
writeFileSync(new URL('seed.sql',dir),players.map(p=>`INSERT INTO players(id,token_hash,name) VALUES (${p.id},'${createHash('sha256').update(p.token).digest('hex')}','Oyuncu ${p.id}');`).join('\n'),{mode:0o600});
writeFileSync(new URL('oyuncu-kodlari.txt',dir),players.map(p=>`Oyuncu ${p.id}\n${p.token}\n`).join('\n')+'\nHer oyuncu yalnızca kendi kodunu kullanmalı. Kodlar hesaba erişim sağlar.\n',{mode:0o600});
console.log('Private setup files prepared in .secrets (not tracked by Git).');

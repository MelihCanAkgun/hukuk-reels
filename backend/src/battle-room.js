import '../generated/battle_rules.js';

const reply = (data, status = 200) => Response.json(data, {status});
const codePattern = /^[A-HJ-NP-Z2-9]{6}$/;
export const validRoom = code => typeof code === 'string' && codePattern.test(code);
export function roomCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return [...crypto.getRandomValues(new Uint8Array(6))].map(v => alphabet[v % alphabet.length]).join('');
}
const rules = data => JSON.parse(globalThis.blockBattleRules(JSON.stringify(data)));

/** One SQLite Durable Object per match. The only mutable game authority.
 * Hibernating sockets have a persisted identity, never an identity supplied in
 * PLACE_PIECE. Storage commits precede broadcast; IDs survive process eviction.
 */
export class BattleRoom {
  constructor(ctx, env) {
    this.ctx = ctx; this.env = env;
    this.match = null; this.tickets = {}; this.sessions = {};
    ctx.blockConcurrencyWhile(async () => {
      const saved = await ctx.storage.get('room');
      if (saved) Object.assign(this, saved);
    });
    ctx.setWebSocketAutoResponse(new WebSocketRequestResponsePair('ping', 'pong'));
  }
  apply(action, data = {}, now = Date.now()) {
    const result = rules({state:this.match, action, now, ...data});
    if (result.state) this.match = result.state;
    return result;
  }
  frame(extra = {}) {
    return {type:'STATE_UPDATE', state:this.match, serverNow:Date.now(), ...extra};
  }
  send(ws, frame) { try { ws.send(JSON.stringify(frame)); } catch {} }
  broadcast(extra = {}) {
    const frame = this.frame(extra);
    for (const ws of this.ctx.getWebSockets()) this.send(ws, frame);
  }
  async save() {
    await this.ctx.storage.put('room', {match:this.match, tickets:this.tickets, sessions:this.sessions});
    await this.schedule();
  }
  seen(ws) {
    return Math.max(ws.deserializeAttachment().openedAt,
      this.ctx.getWebSocketAutoResponseTimestamp(ws)?.getTime() || 0);
  }
  async schedule() {
    if (!this.match) return;
    const m = this.match;
    const times = m.status === 'finished' ? [m.endedAt + 600000]
      : m.status === 'waiting' ? [m.createdAt + 3600000] : [];
    if (m.status !== 'finished') {
      if (m.status === 'countdown') times.push(m.startAt);
      for (const p of m.players) if (p.disconnectAt) times.push(p.disconnectAt);
      for (const ws of this.ctx.getWebSockets()) {
        const a = ws.deserializeAttachment();
        if (this.sessions[a.id] === a.session && m.players.find(p => p.id === a.id)?.connected) {
          times.push(this.seen(ws) + 10000);
        }
      }
    }
    await this.ctx.storage.setAlarm(Math.max(Date.now() + 50, Math.min(...(times.length ? times : [Date.now()+15000]))));
  }
  async fetch(request) {
    return this.ctx.blockConcurrencyWhile(async () => {
      const url = new URL(request.url), now = Date.now();
      if (url.pathname === '/socket') {
        const ticket = url.searchParams.get('ticket');
        const permit = this.tickets[ticket];
        if (!permit || permit.expires < now || !this.match) return reply({error:'Bağlantı anahtarı geçersiz.'},401);
        delete this.tickets[ticket];
        const result = this.apply('connect', {id:permit.id}, now);
        if (result.error) return reply(result,400);
        const [client, server] = Object.values(new WebSocketPair());
        const session = crypto.randomUUID();
        this.sessions[permit.id] = session;
        for (const ws of this.ctx.getWebSockets()) {
          if (ws.deserializeAttachment().id === permit.id) ws.close(4001,'Başka oturum açıldı');
        }
        this.ctx.acceptWebSocket(server);
        server.serializeAttachment({id:permit.id,session,openedAt:now,windowAt:now,count:0});
        await this.save();
        this.broadcast();
        return new Response(null,{status:101,webSocket:client});
      }
      const data = await request.json();
      if (url.pathname === '/create') {
        if (this.match) return reply({error:'Kod kullanılıyor.'},409);
        const seed = crypto.getRandomValues(new Uint32Array(1))[0] % 2147483646 + 1;
        const result = rules({roomId:data.room,seed,action:'join',id:data.id,name:data.name,now});
        if (result.error) return reply({error:result.error},400);
        this.match = result.state;
      } else if (url.pathname === '/join') {
        if (!this.match) return reply({error:'Oda bulunamadı veya süresi doldu.'},404);
        this.apply('advance',{},now);
        const result = this.apply('join',{id:data.id,name:data.name},now);
        if (result.error) return reply(result,409);
      } else return reply({error:'Bulunamadı.'},404);
      // Short-lived single-use socket ticket; the long-lived invite never goes
      // into a URL. Refresh obtains a fresh ticket with the same player identity.
      for (const [key,value] of Object.entries(this.tickets)) {
        if (value.expires < now || value.id === data.id) delete this.tickets[key];
      }
      const ticket = crypto.randomUUID() + crypto.randomUUID();
      this.tickets[ticket] = {id:data.id,expires:now+60000};
      await this.save();
      this.broadcast();
      return reply({room:this.match.roomId,me:data.id,ticket,state:this.match,serverNow:now});
    });
  }
  async webSocketMessage(ws, message) {
    return this.ctx.blockConcurrencyWhile(async () => {
      const a = ws.deserializeAttachment();
      if (!this.match || this.sessions[a.id] !== a.session) return;
      if (typeof message !== 'string' || message.length > 512) {ws.close(1009,'İstek çok büyük');return;}
      const now = Date.now();
      if (now-a.windowAt >= 1000) {a.windowAt=now;a.count=0;}
      if (++a.count > 12) {ws.close(1008,'Çok fazla istek');return;}
      ws.serializeAttachment(a);
      let data;
      try { data=JSON.parse(message); } catch { this.send(ws,{type:'ERROR',error:'Geçersiz mesaj.'});return; }
      if (!data || typeof data !== 'object' || Array.isArray(data)) {
        this.send(ws,{type:'ERROR',error:'Geçersiz mesaj.'});return;
      }
      let result;
      if (data.type === 'PLAYER_READY') result=this.apply('ready',{id:a.id},now);
      else if (data.type === 'RESIGN') result=this.apply('resign',{id:a.id},now);
      else if (data.type === 'PLACE_PIECE') {
        if (!['moveId','slot','row','col'].every(k => Number.isSafeInteger(data[k])) ||
            data.moveId<1 || data.moveId>1000000) {
          this.send(ws,{type:'ERROR',error:'Geçersiz hamle.'}); return;
        }
        result=this.apply('place',{id:a.id,moveId:data.moveId,slot:data.slot,row:data.row,col:data.col},now);
      } else if (data.type === 'RECONNECT') result=this.apply('advance',{},now);
      else { this.send(ws,{type:'ERROR',error:'Bilinmeyen mesaj.'}); return; }
      await this.save();
      if (result.error) this.send(ws,this.frame({type:'ERROR',error:result.error}));
      this.broadcast({events:result.events,move:result.move});
    });
  }
  async webSocketClose(ws) {
    return this.ctx.blockConcurrencyWhile(async () => {
      const a=ws.deserializeAttachment();
      if (!this.match || this.sessions[a.id]!==a.session) return;
      delete this.sessions[a.id];
      this.apply('disconnect',{id:a.id});
      await this.save();this.broadcast();
    });
  }
  async webSocketError(ws) { return this.webSocketClose(ws); }
  async alarm() {
    return this.ctx.blockConcurrencyWhile(async () => {
      if (!this.match) return;
      const now=Date.now();
      if (this.match.status==='finished' && now>=this.match.endedAt+600000) {
        for(const ws of this.ctx.getWebSockets()) ws.close(1000,'Maç arşivi sona erdi');
        await this.ctx.storage.deleteAll();this.match=null;this.tickets={};this.sessions={};return;
      }
      for(const ws of this.ctx.getWebSockets()) {
        const a=ws.deserializeAttachment();
        if (this.sessions[a.id]===a.session && now>=this.seen(ws)+10000) {
          delete this.sessions[a.id];
          this.apply('disconnect',{id:a.id},now);
          ws.close(4000,'Bağlantı yenilenmeli');
        }
      }
      const result=this.apply('advance',{},now);
      await this.save();this.broadcast({events:result.events});
    });
  }
}

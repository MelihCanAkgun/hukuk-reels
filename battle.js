'use strict';
(() => {
  const key='hukuk_battle_v1';
  let saved=null;
  try {saved=JSON.parse(localStorage.getItem(key)||'null');} catch {}
  let socket=null, listener=null, state=null, me=saved?.me, room=saved?.room;
  let pending=saved?.pending||null, retry=null, heartbeat=null, connecting=false;
  let lastSent=0, lastSentAt=0;
  let stopped=true, connected=false, generation=0, error=null, lastPong=0, attempts=0;
  const persist=()=>{
    try {
      if(room && state?.status!=='finished') localStorage.setItem(key,JSON.stringify({room,me,pending}));
      else localStorage.removeItem(key);
    } catch {}
  };
  const emit=extra=>listener?.(JSON.stringify({state,me,room,connected,pending:!!pending,error,...extra}));
  const social=async(action,data={})=>{
    const result=JSON.parse(await window.hukukSocialCall(action,JSON.stringify(data)));
    if(result.error) throw Object.assign(new Error(result.error),{status:result.status});
    return result;
  };
  const cancelTimers=()=>{clearTimeout(retry);clearInterval(heartbeat);retry=null;heartbeat=null;};
  function reconnect() {
    if(stopped || connecting || retry || state?.status==='finished') return;
    connected=false;emit({type:'CONNECTION'});
    retry=setTimeout(()=>{retry=null;void open(false);},Math.min(2500,350*2**attempts++));
  }
  function accept(frame) {
    if(frame.state && (!state || frame.state.revision>=state.revision)) state=frame.state;
    if(frame.type==='ERROR') {error=frame.error;pending=null;}
    else error=null;
    const mine=state?.players.find(p=>p.id===me);
    if(pending && (mine?.lastMove>=pending.moveId || state?.status==='finished')) pending=null;
    persist();emit(frame);
  }
  async function open(create=false) {
    if(connecting) return;
    connecting=true;stopped=false;error=null;socket=null;lastSent=0;
    const epoch=++generation;
    try {
      const permit=await social(create?'battleCreate':'battleJoin',{room});
      if(epoch!==generation || stopped) return;
      if(me!==permit.me) pending=null;
      me=permit.me;room=permit.room;state=permit.state;persist();
      const url=new URL(permit.url);url.protocol=url.protocol==='https:'?'wss:':'ws:';
      url.pathname='/battle/socket/'+room;url.search='?ticket='+encodeURIComponent(permit.ticket);
      const ws=new WebSocket(url.href);socket=ws;

      ws.onopen=()=>{
        if(epoch!==generation){ws.close();return;}
        connected=true;attempts=0;lastPong=Date.now();emit({type:'CONNECTION'});
        ws.send('ping');
        clearInterval(heartbeat);
        heartbeat=setInterval(()=>{
          if(Date.now()-lastPong>12000){ws.close();return;}
          if(ws.readyState===WebSocket.OPEN) {
            ws.send('ping');
            if(pending && Date.now()-lastSentAt>5000) {lastSentAt=Date.now();ws.send(JSON.stringify(pending));}
          }
        },5000);
      };
      ws.onmessage=event=>{
        if(epoch!==generation)return;
        if(event.data==='pong'){lastPong=Date.now();return;}
        let frame;try{frame=JSON.parse(event.data);}catch{return;}
        accept(frame);
        if(pending && lastSent!==pending.moveId && state?.status==='playing' && state.players.every(p=>p.connected)) {
          lastSent=pending.moveId;lastSentAt=Date.now();ws.send(JSON.stringify(pending));
        }
      };
      ws.onclose=event=>{
        if(epoch!==generation)return;
        connected=false;clearInterval(heartbeat);
        if(event.code===4001){stopped=true;error='Bu oyuncu başka bir sekmede açıldı.';emit({type:'CONNECTION'});return;}
        reconnect();
      };
      ws.onerror=()=>{if(epoch===generation)ws.close();};
      emit({type:'STATE_UPDATE',serverNow:permit.serverNow});
    } catch(e) {
      if(epoch!==generation)return;
      error=e.message;connected=false;emit({type:'ERROR'});
      if(create || [400,401,403,404,409].includes(e.status)) {
        stopped=true;saved=null;room=null;state=null;pending=null;persist();throw e;
      }
      reconnect();
    } finally {
      if(epoch===generation){connecting=false;if(!connected && !socket && !stopped)reconnect();}
    }
  }
  window.hukukBattleListen=fn=>{listener=fn;};
  window.hukukBattleCall=async(action,json)=>{
    const data=JSON.parse(json||'{}');
    try {
      if(action==='inspect')return JSON.stringify({room:state?.status==='finished'?null:room});
      if(action==='resume') {
        if(!room)return JSON.stringify({});
        await open();
      } else if(action==='create' || action==='join') {
        cancelTimers();stopped=true;++generation;socket?.close();socket=null;state=null;pending=null;
        room=action==='join'?String(data.room).trim().toUpperCase():null;
        connecting=false;await open(action==='create');
      } else if(action==='ready' || action==='place' || action==='resign') {
        if(!connected || socket?.readyState!==WebSocket.OPEN)throw new Error('Bağlantı yeniden kuruluyor.');
        let message={type:action==='ready'?'PLAYER_READY':'RESIGN'};
        if(action==='place') {
          if(pending)throw new Error('Önceki hamle doğrulanıyor.');
          const mine=state?.players.find(p=>p.id===me);
          if(state?.status!=='playing' || !state.players.every(p=>p.connected))throw new Error('Maç hazır değil.');
          message={type:'PLACE_PIECE',moveId:mine.lastMove+1,slot:data.slot,row:data.row,col:data.col};
          pending=message;lastSent=message.moveId;lastSentAt=Date.now();persist();
        }
        socket.send(JSON.stringify(message));emit({type:'PENDING'});
      } else if(action==='leave') {
        stopped=true;++generation;cancelTimers();socket?.close();socket=null;connected=false;
        saved=null;room=null;state=null;pending=null;persist();emit({type:'LEFT'});
      } else if(action==='detach') {
        // Closing a view is a disconnect, not a silent game reset. Resume is
        // available on refresh until the authoritative 15-second deadline.
        stopped=true;++generation;cancelTimers();socket?.close();socket=null;connected=false;listener=null;
      }
      return JSON.stringify({ok:true,state,me,room,connected,pending:!!pending,error});
    } catch(e) {return JSON.stringify({error:e.message});}
  };
  window.addEventListener('online',()=>{if(!stopped && !connected)reconnect();});
  document.addEventListener('visibilitychange',()=>{
    if(!document.hidden && !stopped){
      if(socket?.readyState===WebSocket.OPEN)socket.send('ping');else reconnect();
    }
  });
})();

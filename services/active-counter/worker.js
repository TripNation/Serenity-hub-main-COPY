// Cloudflare Worker: keep D1 binding DB -> serenity-presence.
// Execution = successful shared UI build, including reruns; not unique people.
// Calendar days/months use Philippine time (UTC+8). No historical backfill.
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
let ready;
async function accountKey(userId,secret){
 const key=await crypto.subtle.importKey('raw',new TextEncoder().encode(secret),{name:'HMAC',hash:'SHA-256'},false,['sign']);
 const signature=await crypto.subtle.sign('HMAC',key,new TextEncoder().encode('serenity-account-v1:'+userId));
 return Array.from(new Uint8Array(signature),b=>b.toString(16).padStart(2,'0')).join('');
}
const json=(v,status=200)=>Response.json(v,{status,headers:{'Cache-Control':'no-store'}});
const dayAt=ms=>new Date(ms+28800000).toISOString().slice(0,10);
async function init(db){
  if(!ready)ready=db.batch([
    db.prepare('CREATE TABLE IF NOT EXISTS account_presence(account TEXT PRIMARY KEY, expires INTEGER NOT NULL)'),
    db.prepare('CREATE INDEX IF NOT EXISTS account_presence_expiry ON account_presence(expires)'),
    db.prepare('CREATE TABLE IF NOT EXISTS execution_events(id TEXT PRIMARY KEY, day TEXT NOT NULL)'),
    db.prepare('CREATE TABLE IF NOT EXISTS execution_days(day TEXT PRIMARY KEY, executions INTEGER NOT NULL)'),
    db.prepare(`CREATE TRIGGER IF NOT EXISTS execution_day_insert AFTER INSERT ON execution_events BEGIN
      INSERT INTO execution_days(day,executions) VALUES(NEW.day,1)
      ON CONFLICT(day) DO UPDATE SET executions=executions+1; END`),
    db.prepare('CREATE TABLE IF NOT EXISTS analytics_meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)'),
    db.prepare("INSERT OR IGNORE INTO analytics_meta(key,value) VALUES('started',?)").bind(new Date().toISOString())
  ]).catch(e=>{ready=undefined;throw e;});
  await ready;
}
async function bodyOf(request){
  if(!request.body)return null;
  const reader=request.body.getReader(),chunks=[];let size=0;
  while(true){const {done,value}=await reader.read();if(done)break;size+=value.length;
    if(size>128){await reader.cancel();return null;}chunks.push(value);}
  const bytes=new Uint8Array(size);let offset=0;
  for(const c of chunks){bytes.set(c,offset);offset+=c.length;}
  try{const b=JSON.parse(new TextDecoder().decode(bytes));
    if(typeof b?.session!=='string'||!UUID.test(b.session))return null;
    if(b.execution!==undefined&&(typeof b.execution!=='string'||!UUID.test(b.execution)))return null;
    return {session:b.session.toLowerCase(),execution:b.execution?.toLowerCase()};
  }catch{return null;}
}
const PAGE=`<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Serenity · Activity</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#09090d;color:#f3f3fa;font:15px system-ui}main{max-width:1000px;margin:auto;padding:44px 22px}header{display:flex;justify-content:space-between;align-items:center;gap:12px}h1{font-size:18px;letter-spacing:2px;color:#b7a0ef}p,small{color:#aaa8b8;line-height:1.6}.metrics{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:28px 0}.card,section{background:#121218;border:1px solid #292832;border-radius:14px;padding:20px}.card:first-child{background:#211911;border-color:#654021}.card p{margin:0 0 10px}.value{font-size:36px;font-weight:700;font-variant-numeric:tabular-nums}.card:first-child .value{color:#f5a34e}button,select{font:inherit;color:#eee;background:#24222e;border:1px solid #464151;border-radius:9px;padding:10px 14px}button{cursor:pointer}button:disabled{opacity:.5}.tools{display:flex;justify-content:space-between;gap:12px;align-items:center}h2{font-size:17px}.chart{height:180px;display:flex;align-items:stretch;gap:4px;margin:24px 0 6px;overflow-x:auto}.column{flex:1;min-width:10px;display:flex;align-items:flex-end}.bar{width:100%;background:#ba94ec;border-radius:3px 3px 0 0;min-height:0}.axis{display:flex;justify-content:space-between;color:#aaa;font-size:12px}table{width:100%;border-collapse:collapse;margin-top:22px}td,th{text-align:left;padding:11px 4px;border-bottom:1px solid #292832}td:last-child,th:last-child{text-align:right}#rowsWrap{max-height:320px;overflow:auto}#status{min-height:24px}footer{margin-top:20px}@media(max-width:650px){.metrics{grid-template-columns:repeat(2,1fr)}main{padding:24px 14px}.value{font-size:30px}.tools{align-items:flex-start;flex-direction:column}}
</style></head><body><main>
<header><h1>SERENITY HUB</h1><button id="refresh">Refresh</button></header>
<p>Active accounts and script executions</p>
<div class="metrics">
<div class="card"><p>Active now</p><div class="value" id="active">—</div></div>
<div class="card"><p>Executions today</p><div class="value" id="today">—</div></div>
<div class="card"><p>This month</p><div class="value" id="month">—</div></div>
<div class="card"><p>All-time executions</p><div class="value" id="total">—</div></div>
</div><p id="status" role="status">Loading…</p>
<section><div class="tools"><h2>Executions over time</h2><select id="mode" aria-label="History interval"><option value="daily">Daily · last 30 days</option><option value="monthly">Monthly · last 12 months</option><option value="all">All time · cumulative by month</option></select></div>
<div id="chart" class="chart" aria-hidden="true"></div><div class="axis"><span id="first"></span><span id="last"></span></div>
<div id="rowsWrap"><table><thead><tr><th id="period">Day</th><th id="metric">Executions</th></tr></thead><tbody id="rows"></tbody></table></div></section>
<footer><small>Calendar: Philippine time (UTC+8). A rerun counts as another execution; heartbeats do not. These are reported executions, not unique people. Active now estimates unique Roblox accounts seen within 10 minutes. Rejoins and multiple devices using the same account count once.</small><p id="started"></p></footer>
</main><script>
const el=id=>document.getElementById(id),fmt=n=>Number(n).toLocaleString();let data,busy=false;
function render(){
 const daily=new Map(data.daily.map(r=>[r.day,Number(r.executions)]));const monthly=new Map();
 for(const [day,n]of daily){const m=day.slice(0,7);monthly.set(m,(monthly.get(m)||0)+n);}
 const mode=el('mode').value,series=[];const anchor=new Date(data.day+'T00:00:00Z');
 if(mode==='daily'){for(let i=29;i>=0;i--){const d=new Date(anchor);d.setUTCDate(d.getUTCDate()-i);const k=d.toISOString().slice(0,10);series.push([k,daily.get(k)||0]);}}
 else{let start=new Date(anchor);start.setUTCDate(1);
   if(mode==='monthly')start.setUTCMonth(start.getUTCMonth()-11);
   else{const first=data.daily[0]?.day||data.day;start=new Date(first.slice(0,7)+'-01T00:00:00Z');}
   let sum=0;for(let d=new Date(start);d<=anchor;d.setUTCMonth(d.getUTCMonth()+1)){const k=d.toISOString().slice(0,7),n=monthly.get(k)||0;sum+=n;series.push([k,mode==='all'?sum:n]);}}
 el('period').textContent=mode==='daily'?'Day':'Month';el('metric').textContent=mode==='all'?'Cumulative executions':'Executions';
 el('chart').replaceChildren();el('rows').replaceChildren();const max=Math.max(1,...series.map(r=>r[1]));
 for(const [k,n]of series){const col=document.createElement('div');col.className='column';col.title=k+': '+fmt(n);const bar=document.createElement('div');bar.className='bar';bar.style.height=(n/max*100)+'%';col.append(bar);el('chart').append(col);}
 for(const [k,n]of [...series].reverse()){const row=document.createElement('tr');for(const text of [k,fmt(n)]){const cell=document.createElement('td');cell.textContent=text;row.append(cell);}el('rows').append(row);}
 el('first').textContent=series[0]?.[0]||'';el('last').textContent=series.at(-1)?.[0]||'';
}
async function refresh(){if(busy)return;busy=true;el('refresh').disabled=true;const c=new AbortController(),timer=setTimeout(()=>c.abort(),10000);
 try{const r=await fetch('/stats',{cache:'no-store',signal:c.signal});if(!r.ok)throw Error();const next=await r.json();if(!Array.isArray(next.daily))throw Error();data=next;
 for(const key of ['active','today','month','total'])el(key).textContent=fmt(data[key]);render();
 el('status').textContent='Updated '+new Date().toLocaleTimeString();el('started').textContent='Tracking began '+new Date(data.started).toLocaleString('en-PH',{timeZone:'Asia/Manila'})+' (Philippine time). Earlier executions are unavailable.';
 }catch{for(const k of ['active','today','month','total'])el(k).textContent='—';el('status').textContent='Update failed. Any chart shown is the previous reading. Try Refresh.';}
 finally{clearTimeout(timer);busy=false;el('refresh').disabled=false;}}
 el('refresh').onclick=refresh;el('mode').onchange=()=>{if(data)render();};setInterval(()=>{if(!document.hidden)refresh();},300000);document.addEventListener('visibilitychange',()=>{if(!document.hidden)refresh();});refresh();
</script></body></html>`;
export default {async fetch(request,env){
 const path=new URL(request.url).pathname;
 if(path==='/'&&request.method==='GET')return new Response(PAGE,{headers:{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'}});
 const method=['/active','/stats'].includes(path)?'GET':['/heartbeat','/leave'].includes(path)?'POST':null;
 if(!method)return json({error:'Not found'},404);
 if(request.method!==method)return json({error:'Method not allowed'},405);
 let body;if(method==='POST'){body=await bodyOf(request);if(!body)return json({error:'Invalid session or execution UUID; body limit 128 bytes'},400);}
 const userId=request.headers.get('X-Serenity-Account');
 if(userId!==null&&(!/^[1-9][0-9]{0,15}$/.test(userId)||!Number.isSafeInteger(Number(userId))))return json({error:'Invalid account identifier'},400);
 if(typeof env.PRESENCE_HMAC_SECRET!=='string'||env.PRESENCE_HMAC_SECRET.length<32)return json({error:'Configure PRESENCE_HMAC_SECRET with at least 32 random characters'},503);
 if(!env.DB)return json({error:'D1 binding DB is missing'},503);
 try{await init(env.DB);const now=Math.floor(Date.now()/1000),day=dayAt(Date.now());
  if(path==='/leave')return json({ok:true}); // Expiry protects newer sessions and other devices on the same account.
  if(path==='/heartbeat'){
   const q=[env.DB.prepare('DELETE FROM account_presence WHERE expires<=?').bind(now)];
   if(userId!==null){const account=await accountKey(userId,env.PRESENCE_HMAC_SECRET);q.push(env.DB.prepare('INSERT INTO account_presence(account,expires) VALUES(?,?) ON CONFLICT(account) DO UPDATE SET expires=MAX(account_presence.expires,excluded.expires)').bind(account,now+600));}
   if(body.execution)q.push(env.DB.prepare('INSERT OR IGNORE INTO execution_events(id,day) VALUES(?,?)').bind(body.execution,day));
   q.push(env.DB.prepare('SELECT COUNT(*) AS active FROM account_presence WHERE expires>?').bind(now));
   const results=await env.DB.batch(q);
   return json({ok:true,interval:300,ttl:600,active:Number(results[results.length-1].results[0].active),executionRecorded:!!body.execution,presenceMode:"accounts",presenceRecorded:userId!==null});
  }
  // Dashboard/count requests are read-only; heartbeat cleanup removes expired rows.
  const q=[env.DB.prepare('SELECT COUNT(*) AS active FROM account_presence WHERE expires>?').bind(now)];
  if(path==='/stats'){q.push(env.DB.prepare('SELECT day,executions FROM execution_days ORDER BY day'));q.push(env.DB.prepare("SELECT value FROM analytics_meta WHERE key='started'"));}
  const r=await env.DB.batch(q),active=Number(r[0].results[0].active);
  if(path==='/active')return json({active});
  const daily=r[1].results;let today=0,month=0,total=0;
  for(const row of daily){const n=Number(row.executions);total+=n;if(row.day===day)today+=n;if(row.day.slice(0,7)===day.slice(0,7))month+=n;}
  return json({active,today,month,total,day,daily,started:r[2].results[0].value});
 }catch{return json({error:'Storage unavailable; retry shortly'},503);}
}};


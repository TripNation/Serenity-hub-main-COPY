import fs from 'node:fs';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {webcrypto} from 'node:crypto';
const sql=new DatabaseSync(':memory:');
sql.exec("CREATE TABLE presence(session TEXT PRIMARY KEY,expires INTEGER NOT NULL); INSERT INTO presence VALUES('old',9999999999); CREATE TABLE execution_days(day TEXT PRIMARY KEY,executions INTEGER NOT NULL); INSERT INTO execution_days VALUES('2026-01-01',7)");
let clock=1800000000; Date.now=()=>clock*1000;let queries=[];
function execute(s){queries.push(s.query);let p=sql.prepare(s.query);if(s.query.startsWith('SELECT'))return {results:p.all(...s.args)};p.run(...s.args);return {results:[]}}
const DB={prepare(query){return {query,args:[],bind(...a){this.args=a;return this},async run(){return execute(this)}}},async batch(q){sql.exec('BEGIN');try{let r=q.map(execute);sql.exec('COMMIT');return r}catch(e){sql.exec('ROLLBACK');throw e}}};
const env={DB,PRESENCE_HMAC_SECRET:'test-secret-not-for-production-123456789'};
const src=fs.readFileSync(new URL('./worker.js',import.meta.url),'utf8');
const {default:w}=await import('data:text/javascript;base64,'+Buffer.from(src).toString('base64'));
const id=n=>`${String(n).padStart(8,'0')}-1111-4111-8111-111111111111`;
async function call(path,body,userId,config=env,status=200){let r=await w.fetch(new Request('https://example.com'+path,{method:body?'POST':'GET',headers:userId===undefined?{}:{'X-Serenity-Account':userId},...(body?{body:JSON.stringify(body)}:{})}),config);assert.equal(r.status,status);return r.json()}
const beat=(session,event)=>({session:id(session),...(event?{execution:id(event)}:{})});
assert.equal((await call('/heartbeat',beat(1,10),'12345')).active,1);
for(let n=2;n<22;n++)assert.equal((await call('/heartbeat',beat(n,n+100),'12345')).active,1);
assert.equal((await call('/stats')).total,28);
await call('/heartbeat',beat(21,121),'12345');assert.equal((await call('/stats')).total,28);
assert.equal((await call('/heartbeat',beat(22,122),'67890')).active,2);
await call('/leave',beat(21),'12345');assert.equal((await call('/active')).active,2);
assert.equal((await call('/heartbeat',beat(23,123))).active,2); // Old clients never inflate account count.
queries=[];await call('/stats');await call('/active');assert(queries.every(q=>q.startsWith('SELECT')));
clock+=300;let r=await call('/heartbeat',beat(24),'12345');assert.equal(r.interval,300);assert.equal(r.ttl,600);
clock+=300;assert.equal((await call('/active')).active,1);clock+=300;assert.equal((await call('/active')).active,0);
await call('/heartbeat',beat(25),'12345');let rows=sql.prepare('SELECT * FROM account_presence').all();assert.equal(rows.length,1);assert.match(rows[0].account,/^[a-f0-9]{64}$/);assert(!JSON.stringify(rows).includes('12345'));
for(let bad of ['0','01','-1','abc','9007199254740992'])await call('/heartbeat',beat(26),bad,env,400);
await call('/heartbeat',beat(26),'12345',{DB},503);
assert.equal(sql.prepare('SELECT executions FROM execution_days WHERE day=?').get('2026-01-01').executions,7);
let html=await (await w.fetch(new Request('https://example.com/'),env)).text();new Function(html.match(/<script>([\s\S]*?)<\/script>/)[1]);
console.log('PASS: 20 rejoins, two accounts, event deduplication, legacy migration, leave race, expiry, HMAC-only storage, missing secret, validation, history, read-only counts, dashboard syntax.');

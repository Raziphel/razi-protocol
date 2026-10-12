"use strict";
// Dependency-free helper smoke tests; no running Factorio or Discord needed.
const assert=require("node:assert/strict");
const fs=require("node:fs");
const os=require("node:os");
const path=require("node:path");
const child=require("node:child_process");
const root=path.resolve(__dirname,"..");
const companion=path.join(root,"tools","razi-presence.js");
const dir=fs.mkdtempSync(path.join(os.tmpdir(),"razi-presence-test-"));
const file=path.join(dir,"state.json");
function run(){
  const result=child.spawnSync(process.execPath,
    [companion,"--preview","--file",file],{encoding:"utf8"});
  assert.equal(result.status,0,result.stderr);
  return JSON.parse(result.stdout);
}
try{
  assert.equal(run().fresh,false,"Absent state must not publish presence");
  fs.writeFileSync(file,JSON.stringify({schema:1,enabled:true,
    chapter:"vibrant",chapter_number:4,
    chapter_title:"Vibrant | The Broken Spectrum",
    quest:"Through the falling stones",quest_id:"asteroid-belt",
    completed:26,total:180,elapsed_ticks:3600,
    location:"Fulgora",region:"vibrant"}));
  const good=run();
  assert.equal(good.fresh,true);
  assert.match(good.activity.details,/Chapter 4.*Vibrant/);
  assert.match(good.activity.state,/Through the falling stones/);
  assert.match(good.activity.assets.large_text,/Fulgora/);
  assert.equal(typeof good.activity.timestamps.start,"number");
  fs.writeFileSync(file,'{"schema":1,"enabled":false}');
  assert.equal(run().fresh,false,"Opting out must stop updates");
  fs.writeFileSync(file,'{"schema":1,"enabled":true');
  assert.equal(run().fresh,false,"Truncated JSON must be ignored");
  fs.writeFileSync(file,JSON.stringify({schema:999,enabled:true}));
  assert.equal(run().fresh,false,"Unknown schema must be rejected");
  fs.writeFileSync(file,JSON.stringify({schema:1,enabled:true,
    chapter_number:1,chapter_title:"Calidus",quest:"First Signal"}));
  const old=new Date(Date.now()-120000);
  fs.utimesSync(file,old,old);
  assert.equal(run().fresh,false,"Stale sessions must clear");
  console.log("Razi presence desktop preview fixtures passed");
}finally{
  fs.rmSync(dir,{recursive:true,force:true});
}

#!/usr/bin/env node
"use strict";
// Razi Protocol local Discord Rich Presence companion. Node 18+, no packages.
const fs=require("node:fs"),net=require("node:net"),os=require("node:os"),path=require("node:path");
const argv=process.argv.slice(2);
function arg(flag){const i=argv.indexOf("--"+flag);return i>=0?argv[i+1]:null}
const folder=process.platform==="win32"
  ?path.join(process.env.APPDATA||path.join(os.homedir(),"AppData","Roaming"),"Factorio")
  :path.join(os.homedir(),".factorio");
const file=path.resolve(arg("file")||process.env.RAZI_PRESENCE_FILE||
  path.join(folder,"script-output","razi-presence","state.json"));
const appId=arg("app-id")||process.env.RAZI_DISCORD_APP_ID||"";
const preview=argv.includes("--preview");
function clean(v,fallback,max=128){
  const s=typeof v==="string"?v:fallback;
  return(s||fallback).replace(/[\x00-\x1f\x7f]/g," ").trim().slice(0,max);
}
function readState(){
  try{
    const stat=fs.statSync(file);
    if(Date.now()-stat.mtimeMs>60000||Date.now()<stat.mtimeMs-60000)return null;
    const value=JSON.parse(fs.readFileSync(file,"utf8"));
    if(!value||value.schema!==1||value.enabled!==true)return null;
    return{state:value,modified:stat.mtimeMs};
  }catch(_){return null}
}
function format(data){
  const p=data.state;
  const count=Number.isInteger(p.chapter_number)?p.chapter_number:1;
  const chapter=clean(p.chapter_title,"Unknown frontier",95);
  const details=clean("Chapter "+count+" | "+chapter,"Exploring the galaxy");
  const progress=(Number(p.completed)||0)+"/"+(Number(p.total)||0)+" milestones";
  const quest=clean(p.quest,"",90);
  const state=clean(quest?"Quest: "+quest:progress,progress);
  const location=clean(p.location,"",65);
  const region=clean(p.region,"",35);
  const tooltip=clean(location?
    "Razi Protocol | "+location+(region&&region!=="unassigned"?" ("+region+")":"")
    :"Razi Protocol","Razi Protocol");
  const start=Math.floor(data.modified/1000-Math.max(0,Number(p.elapsed_ticks)||0)/60);
  const activity={details,state,timestamps:{start},
    assets:{large_image:"razi-logo",large_text:tooltip},instance:false};
  const signature=JSON.stringify({details,state,location,region,chapter:p.chapter,
    quest:p.quest_id,done:p.completed,total:p.total});
  return{activity,signature};
}
function socketPaths(){
  const paths=[];
  for(let i=0;i<10;i++){
    if(process.platform==="win32"){
      paths.push("\\\\.\\pipe\\discord-ipc-"+i);
    }else{
      for(const dir of [process.env.XDG_RUNTIME_DIR,process.env.TMPDIR,"/tmp"]){
        if(!dir)continue;
        paths.push(path.join(dir,"discord-ipc-"+i));
        paths.push(path.join(dir,"app","com.discordapp.Discord","discord-ipc-"+i));
      }
    }
  }
  return [...new Set(paths)];
}
function packet(op,body){
  const content=Buffer.from(JSON.stringify(body),"utf8");
  const result=Buffer.alloc(8+content.length);
  result.writeUInt32LE(op,0);
  result.writeUInt32LE(content.length,4);
  content.copy(result,8);
  return result;
}
class Bridge{
  constructor(id){this.id=id;this.socket=null;this.ready=false;this.buffer=Buffer.alloc(0);
    this.signature=null;this.lastSent=0;this.lastAttempt=0;this.nonce=0}
  send(op,body){if(this.socket&&!this.socket.destroyed)this.socket.write(packet(op,body))}
  command(activity){
    this.nonce++;
    this.send(1,{cmd:"SET_ACTIVITY",args:{pid:process.pid,activity},
      nonce:"razi-"+this.nonce});
  }
  connect(){
    if(this.socket||Date.now()-this.lastAttempt<5000)return;
    this.lastAttempt=Date.now();
    const paths=socketPaths();
    let i=0;
    const attempt=()=>{
      if(this.socket||i>=paths.length)return;
      const sock=net.createConnection({path:paths[i++]});
      let connected=false;
      sock.once("connect",()=>{
        connected=true;this.socket=sock;this.ready=false;this.buffer=Buffer.alloc(0);
        sock.on("data",chunk=>this.consume(chunk));
        sock.on("close",()=>{
          if(this.socket===sock){this.socket=null;this.ready=false;
            this.signature=null;this.lastSent=0}
        });
        this.send(0,{v:1,client_id:this.id});
      });
      sock.once("error",()=>{if(!connected)attempt()});
      sock.once("close",()=>{if(!connected)attempt()});
    };
    attempt();
  }
  consume(chunk){
    this.buffer=Buffer.concat([this.buffer,chunk]);
    if(this.buffer.length>1048576){this.socket.destroy();return}
    while(this.buffer.length>=8){
      const op=this.buffer.readUInt32LE(0);
      const len=this.buffer.readUInt32LE(4);
      if(len>524288){this.socket.destroy();return}
      if(this.buffer.length<len+8)break;
      let body={};
      try{body=JSON.parse(this.buffer.toString("utf8",8,8+len))}catch(_){}
      this.buffer=this.buffer.subarray(8+len);
      if(op===3)this.send(4,body);
      if(op===2){this.socket.destroy();break}
      if(op===1&&body.evt==="READY"){
        this.ready=true;console.log("Discord connected: Razi Protocol presence enabled.");
      }
      if(op===1&&body.evt==="ERROR"){
        console.error("Discord rejected activity:",body.data&&body.data.message);
      }
    }
  }
  sync(data){
    if(!data){
      if(this.ready&&this.signature!==null){
        this.command(null);this.signature=null;
        console.log("Razi presence cleared (disabled or stale state).");
      }
      return;
    }
    this.connect();
    if(!this.ready)return;
    const next=format(data);
    if(next.signature===this.signature)return;
    if(this.lastSent&&Date.now()-this.lastSent<15000)return;
    this.command(next.activity);this.lastSent=Date.now();
    this.signature=next.signature;
    console.log(next.activity.details+" | "+next.activity.state);
  }
}
if(preview){
  const state=readState();
  console.log(JSON.stringify({file,fresh:!!state,activity:state?format(state).activity:null},null,2));
}else if(!/^\d{17,22}$/.test(appId)){
  console.error("Set --app-id YOUR_DISCORD_APPLICATION_ID (or RAZI_DISCORD_APP_ID).");
  console.error("Read docs/DISCORD_PRESENCE.md. No Discord bot token is required.");
  process.exitCode=2;
}else{
  console.log("Razi Protocol Rich Presence. Local file: "+file);
  const bridge=new Bridge(appId);
  const poll=()=>bridge.sync(readState());
  poll();setInterval(poll,5000);
  for(const signal of ["SIGINT","SIGTERM"]){
    process.once(signal,()=>{
      bridge.sync(null);
      if(bridge.socket)bridge.socket.end();
      process.exit(0);
    });
  }
}

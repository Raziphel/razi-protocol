// Compact Space Age-inspired starmap icons for Razi Protocol.
// Regenerates all eleven navigation markers and four route PNG/SVG pairs.
// No external graphics dependencies or runtime drawing work.
// Usage from the repository root: node scripts/generate_navigation_markers.js
const fs=require("node:fs"),path=require("node:path");
const specs={
  "calidus-gate": {
    "kind": "gate",
    "style": "home",
    "tilt": 0.44,
    "core": "#ffc54b",
    "accent": "#cba05c"
  },
  "solaris-gate": {
    "kind": "gate",
    "style": "heat",
    "tilt": -0.3,
    "core": "#ffb148",
    "accent": "#cc7c4c"
  },
  "nyxaris-gate": {
    "kind": "gate",
    "style": "biosignal",
    "tilt": 0.17,
    "core": "#eac36b",
    "accent": "#75baa0"
  },
  "vibrant-gate": {
    "kind": "gate",
    "style": "electric",
    "tilt": 1.01,
    "core": "#ffd77b",
    "accent": "#799acb"
  },
  "vespera-gate": {
    "kind": "gate",
    "style": "frost",
    "tilt": -0.12,
    "core": "#f9da98",
    "accent": "#b6c7d7"
  },
  "beetlejuice-gate": {
    "kind": "gate",
    "style": "binary",
    "tilt": 0.62,
    "core": "#ffd06c",
    "accent": "#c8887c"
  },
  "umbra-gate": {
    "kind": "gate",
    "style": "eclipse",
    "tilt": -0.61,
    "core": "#edaa53",
    "accent": "#af7d65"
  },
  "vibrant-rim-inner": {
    "kind": "rim",
    "style": "metal",
    "inner": true,
    "tilt": -0.31,
    "core": "#f3c66c",
    "accent": "#9eafbd"
  },
  "vibrant-rim-outer": {
    "kind": "rim",
    "style": "metal",
    "inner": false,
    "tilt": 0.34,
    "core": "#f3c66c",
    "accent": "#7da1bb"
  },
  "umbra-rim-inner": {
    "kind": "rim",
    "style": "shattered",
    "inner": true,
    "tilt": 0.82,
    "core": "#eab05e",
    "accent": "#b99074"
  },
  "umbra-rim-outer": {
    "kind": "rim",
    "style": "shattered",
    "inner": false,
    "tilt": -0.67,
    "core": "#efb369",
    "accent": "#a47c6c"
  },
  "planetary-route": {
    "kind": "route",
    "style": "local",
    "tilt": 0.37,
    "core": "#e5c17a",
    "accent": "#9dbeae"
  },
  "interstellar-route": {
    "kind": "route",
    "style": "stellar",
    "tilt": -0.48,
    "core": "#ffda91",
    "accent": "#96aac5"
  },
  "asteroid-route": {
    "kind": "route",
    "style": "asteroid",
    "tilt": 0.22,
    "core": "#f5b86b",
    "accent": "#c6a082"
  },
  "deep-space-route": {
    "kind": "route",
    "style": "deep",
    "tilt": 0.65,
    "core": "#dfcaac",
    "accent": "#a5a0c6"
  }
};
function rgb(value){return [1,3,5].map(i=>parseInt(value.slice(i,i+2),16))}
function makePainter(){
 const S=3,N=64*S,bytes=new Uint8Array(N*N*4),vectors=[];
 const fmt=n=>Number(n.toFixed(3)),color=c=>typeof c==="string"?c:"#"+c.map(v=>Math.round(v).toString(16).padStart(2,"0")).join("");
 function paint(x,y,c,a=1){x=Math.floor(x);y=Math.floor(y);if(x<0||y<0||x>=N||y>=N||a<=0)return;const i=(y*N+x)*4,old=bytes[i+3]/255,next=a+old*(1-a);for(let k=0;k<3;k++)bytes[i+k]=Math.round((c[k]*a+bytes[i+k]*old*(1-a))/next);bytes[i+3]=Math.round(next*255)}
 function disc(x,y,r,c,a=1){
   const col=rgb(c);for(let py=Math.floor((y-r)*S);py<=Math.ceil((y+r)*S);py++)for(let px=Math.floor((x-r)*S);px<=Math.ceil((x+r)*S);px++){let dx=(px+.5)/S-x,dy=(py+.5)/S-y;if(dx*dx+dy*dy<=r*r)paint(px,py,col,a)}
   vectors.push(`<circle cx="${fmt(x)}" cy="${fmt(y)}" r="${fmt(r)}" fill="${c}" opacity="${fmt(a)}"/>`);
 }
 function line(ax,ay,bx,by,w,c,a=1){
   const col=rgb(c),vx=bx-ax,vy=by-ay,vsq=vx*vx+vy*vy||1;
   const x0=Math.max(0,Math.floor((Math.min(ax,bx)-w)*S)),x1=Math.min(N-1,Math.ceil((Math.max(ax,bx)+w)*S));
   const y0=Math.max(0,Math.floor((Math.min(ay,by)-w)*S)),y1=Math.min(N-1,Math.ceil((Math.max(ay,by)+w)*S));
   for(let py=y0;py<=y1;py++)for(let px=x0;px<=x1;px++){const x=(px+.5)/S,y=(py+.5)/S,t=Math.max(0,Math.min(1,((x-ax)*vx+(y-ay)*vy)/vsq)),dx=x-ax-t*vx,dy=y-ay-t*vy;if(dx*dx+dy*dy<=w*w/4)paint(px,py,col,a)}
   vectors.push(`<path d="M${fmt(ax)} ${fmt(ay)}L${fmt(bx)} ${fmt(by)}" fill="none" stroke="${c}" stroke-width="${fmt(w)}" stroke-linecap="round" opacity="${fmt(a)}"/>`);
 }
 function path(points,w,c,a=1){
   for(let i=1;i<points.length;i++)line(...points[i-1],...points[i],w,c,a);
 }
 function ellipse(cx,cy,rx,ry,tilt,start,end,w,c,a=1,dash=0){
   const count=Math.max(12,Math.ceil((Math.abs(end-start)*(rx+ry)/2)*1.85)),pts=[];
   for(let i=0;i<=count;i++){const t=start+(end-start)*i/count,x=Math.cos(t)*rx,y=Math.sin(t)*ry;pts.push([cx+x*Math.cos(tilt)-y*Math.sin(tilt),cy+x*Math.sin(tilt)+y*Math.cos(tilt)])}
   if(dash){for(let i=1;i<pts.length;i++)if(Math.floor(i/dash)%2===0)line(...pts[i-1],...pts[i],w,c,a)}
   else path(pts,w,c,a);
 }
 function arc(r,start,end,w,c,a=1){ellipse(32,32,r,r,0,start,end,w,c,a)}
 function poly(pts,c,a=1){
   const col=rgb(c),xs=pts.map(p=>p[0]),ys=pts.map(p=>p[1]);
   for(let py=Math.floor(Math.min(...ys)*S);py<=Math.ceil(Math.max(...ys)*S);py++)for(let px=Math.floor(Math.min(...xs)*S);px<=Math.ceil(Math.max(...xs)*S);px++){
    const x=(px+.5)/S,y=(py+.5)/S;let inside=false;
    for(let i=0,j=pts.length-1;i<pts.length;j=i++){const u=pts[i],v=pts[j];if((u[1]>y)!==(v[1]>y)&&x<(v[0]-u[0])*(y-u[1])/(v[1]-u[1])+u[0])inside=!inside}
    if(inside)paint(px,py,col,a)
   }
   vectors.push(`<path d="${pts.map((p,i)=>(i?"L":"M")+fmt(p[0])+" "+fmt(p[1])).join("")}Z" fill="${c}" opacity="${fmt(a)}"/>`);
 }
 function rgba(){
  const out=new Uint8Array(64*64*4);for(let y=0;y<64;y++)for(let x=0;x<64;x++){let alpha=0,sums=[0,0,0];for(let iy=0;iy<S;iy++)for(let ix=0;ix<S;ix++){let n=((y*S+iy)*N+(x*S+ix))*4,a=bytes[n+3]/255;alpha+=a;for(let k=0;k<3;k++)sums[k]+=bytes[n+k]*a}let p=(y*64+x)*4;out[p+3]=Math.round(alpha/(S*S)*255);for(let k=0;k<3;k++)out[p+k]=alpha?Math.round(sums[k]/alpha):0}return out
 }
 function svg(){return `<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 64 64">\n${vectors.join("\n")}\n</svg>\n`}
 return{disc,line,path,ellipse,arc,poly,rgba,svg};
}
function orbitPoint(t,rx,ry,tilt,cx=32,cy=32){
 const x=rx*Math.cos(t),y=ry*Math.sin(t);
 return[cx+x*Math.cos(tilt)-y*Math.sin(tilt),cy+x*Math.sin(tilt)+y*Math.cos(tilt)]
}
function drawIcon(name,spec){
 const p=makePainter(),{disc,line,path,ellipse,arc,poly}=p;
 const a=spec.accent,core=spec.core,gold="#b98b3c",light="#ffe7a3",tilt=spec.tilt,PI=Math.PI;
 // Thin, individually shaded ring and black disc; the reference is an orbit, not a badge.
 disc(32,32,29.2,"#060a0e",.24);
 disc(32,32,27.6,"#22272a");
 disc(32,32,26.5,"#6d7375");
 disc(32,32,25.45,"#34393b");
 disc(32,32,24.6,"#0a0e13");
 disc(32,32,23.9,"#020408");
 arc(26.25,-2.65,-.46,1.3,"#c9c9c4",.67);
 arc(26.12,.18,1.37,.95,"#858a89",.62);
 arc(25.4,2.6,3.85,.6,a,.29);
 if(spec.kind==="gate"){
  // Different orbital geometry, central bodies and moon/flare arrangements.
  ellipse(32,32,18.0,8.8,tilt,0,PI*2,1.25,"#795727",.98);
  ellipse(32,32,18.0,8.8,tilt,-PI*.2,PI*.75,1.45,gold,.96);
  const moon=(theta,size,col)=>{const q=orbitPoint(theta,18,8.8,tilt);disc(...q,size+1.2,"#211a10",.7);disc(...q,size,col,.92)};
  if(spec.style==="home"){
    moon(PI*.19,2.5,"#ffce73");
    line(13,45,20,42,1.5,a,.80);arc(22.6,2.21,2.65,.9,gold,.58);
  }else if(spec.style==="heat"){
    ellipse(32,32,21,11,tilt,PI*.16,PI*.99,1.0,a,.92);
    moon(PI*1.20,2.1,"#f5a05e");
    for(let t of [0,PI/2,PI,1.5*PI]){const q=orbitPoint(t,7.8,7.8,0);line(32+q[0]-32,32+q[1]-32,32+(q[0]-32)*1.33,32+(q[1]-32)*1.33,1.25,"#f3b461",.80)}
  }else if(spec.style==="biosignal"){
    ellipse(32,32,10,20,-.72,.2,PI*1.68,1.0,a,.78);
    moon(.49,2.3,"#8bd8b3");moon(PI*1.30,1.8,"#d5f1b2");
    arc(22.7,-2.0,-1.48,1.3,a,.72);
  }else if(spec.style==="electric"){
    ellipse(32,32,20.5,6.8,-.64,.08,PI*1.57,1.2,a,.75);
    moon(PI*.82,2.5,"#b4cbff");moon(PI*1.72,1.25,"#f5d87b");
    line(42,40,46,35,1.3,"#99badf",.95);
  }else if(spec.style==="frost"){
    ellipse(32,32,21.6,5.3,-.10,0,PI*2,.9,"#b5bbc4",.72);
    moon(PI*1.33,2.5,"#e1f5fb");
    disc(45,15,1.6,"#c8dfec",.85);arc(22.5,.95,1.45,.9,a,.6);
  }else if(spec.style==="binary"){
    ellipse(32,32,10.3,19.7,.85,0,PI*2,.95,a,.7);
    moon(PI*.31,2.1,"#ffb981");moon(PI*1.30,2.25,"#f3d8a4");
    disc(38.2,28.9,2.55,"#a6664e",.9);disc(38.0,28.5,1.2,"#eec2a6");
  }else if(spec.style==="eclipse"){
    ellipse(32,32,20.0,8.0,tilt,.38,PI*1.83,1.7,a,.9);
    disc(32,32,7.25,"#8e4c25",.62);
    disc(35.2,29.1,7.1,"#020408");
    arc(22.6,PI*.47,PI*.77,1.4,a,.78);
    moon(PI*1.2,2,"#c99367");
  }
  if(spec.style!=="eclipse"){
    disc(32,32,7.0,"#925312",.35);
    disc(32,32,4.65,"#b86f20",.68);
    disc(32,32,3.15,core);
    disc(30.95,30.83,1.3,light,.85);
  }else{
    disc(29.0,34.1,2.2,core,.9);
  }
 }else if(spec.kind==="rim"){
   // Belt markers use broad entry/exit chevrons, visible at 24px, and three rocks.
   const umbra=spec.style==="shattered",left=spec.inner,base=umbra?"#ba895f":"#a8bac2";
   ellipse(32,32,17.1,9.7,tilt,0,PI*2,1.2,"#926b2e",.83);
   ellipse(32,32,17.1,9.7,tilt,-PI*.27,PI*.6,1.3,"#dbc086",.9);
   const rocks=umbra?[[18,18,3.2],[21,45,2.4],[47,18,2.1],[46,43,3.2]]:
     [[19,20,2.8],[20,42,2.2],[46,19,2.3],[44,45,2.1]];
   for(const [x,y,r]of rocks){poly([[x-r,y-.6*r],[x-.13*r,y-r],[x+r,y-.3*r],[x+.62*r,y+r],[x-r*.69,y+r*.56]],base,.76);line(x-r,y-r*.5,x,y-r,0.7,"#edce9a",.34)}
   if(umbra){
     arc(25.3,PI*.13,PI*.32,1.5,"#ad7353",.85);
     arc(25.3,PI*1.10,PI*1.32,1.3,"#ad7353",.75);
   }else{
     arc(25.3,PI*.13,PI*.30,1.3,"#869fb9",.85);
   }
   const cx=left?16.4:47.6,dir=left?-1:1;
   poly([[cx-dir*4.2,26.7],[cx+dir*2.6,32],[cx-dir*4.2,37.3]],a,.92);
   path([[cx-dir*4.8,27],[cx+dir*1.6,32],[cx-dir*4.8,37]],1.05,"#eee4c9",.8);
   disc(32,32,5.2,"#935d22",.45);
   disc(32,32,3.1,core,.95);disc(31.2,31,1.15,light,.85);
 }else{
   // Four genuinely different route pictures, not remapped badges.
   if(spec.style==="local"){
     ellipse(31,32,19,11,.39,PI*.25,PI*1.89,1.55,a,.94);
     ellipse(31,32,14.8,6.5,.39,PI*.83,PI*1.65,.9,gold,.7);
     disc(18.3,38.4,4.3,"#6b917f",.65);disc(18.1,37.6,2.5,"#c6e1c4");
     disc(45.3,26.5,4.0,"#a47432",.7);disc(44.7,25.8,2.4,core);
     arc(23.1,PI*.05,PI*.36,1.0,a,.58);
   }else if(spec.style==="stellar"){
     const start=[16.3,43.2],end=[47.9,19.6];
     disc(...start,5.4,"#375b79",.75);disc(...start,2.8,"#d5eaff");disc(...end,5.6,"#89684e",.82);disc(...end,3.2,core);
     path([[17.6,42.3],[22.2,38.7],[29,35.7],[35.1,29.3],[41,24.1],[46.2,20.7]],1.55,a,.96);
     disc(31.3,33.9,1.2,light,.8);
     disc(23,19,1.3,"#d5e4f1",.66);
     disc(43,42,1.05,"#d5e4f1",.55);
   }else if(spec.style==="asteroid"){
     const rock=rgb("#877362");
     path([[15.1,45.3],[23,37.8],[31,31.4],[39,25.1],[49,17.4]],1.35,"#d6aa6b",.93);
     for(const [x,y]of [[17,43],[27,34],[38,26],[47,19]])disc(x,y,1.5,light,.92);
     for(const [x,y,r] of [[23,21,3.5],[40,38,4.6],[29,45,2.5],[42,15,2.3]]){
       poly([[x-r,y-r*.3],[x-r*.15,y-r],[x+r,y-r*.45],[x+r*.67,y+r*.7],[x-r*.65,y+r*.7]],"#766d67",.85);
       line(x-r*.7,y-r*.3,x-r*.15,y-r,.85,"#c3a588",.65);
     }
     arc(25.2,-2.0,-1.0,1.3,"#bc8a58",.7);
   }else{
     disc(16.5,45.2,4.1,"#799da9",.7);disc(16.5,45.2,2.3,"#e2eef2");
     path([[19.8,42],[26,36],[32,30],[38,25]],1.3,a,.72);
     path([[39.8,23],[45.9,17.5]],1.05,"#d7bded",.9);
     disc(48.6,14.3,3.4,"#786e9b",.7);disc(48.3,13.9,1.9,light);
     disc(30.9,31.1,1.3,"#aea4c9",.66);
     disc(21,18.5,1,"#8998be",.6);disc(44.7,43.8,.9,"#bac4e3",.65);
     arc(25.1,PI*.46,PI*.68,1.1,a,.65);
   }
 }
 return p
}
function pngEncode(rgba,width=64,height=64){
 const out=[137,80,78,71,13,10,26,10];
 const be32=n=>[(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255];
 function crc(data){let a=0xffffffff;for(const b of data){a^=b;for(let k=0;k<8;k++)a=(a>>>1)^((a&1)?0xedb88320:0)}return(a^0xffffffff)>>>0}
 function chunk(type,data){const body=Array.from(type).map(c=>c.charCodeAt(0)).concat(data);out.push(...be32(data.length));for(const b of body)out.push(b);out.push(...be32(crc(body)))}
 const raw=[];for(let y=0;y<height;y++){raw.push(0);for(let x=0;x<width*4;x++)raw.push(rgba[y*width*4+x])}
 const z=[0x78,0x01];for(let p=0;p<raw.length;){const n=Math.min(65535,raw.length-p);z.push(p+n===raw.length?1:0,n&255,(n>>>8)&255,(~n)&255,((~n)>>>8)&255);for(let k=p;k<p+n;k++)z.push(raw[k]);p+=n}
 let a=1,b=0;for(const v of raw){a=(a+v)%65521;b=(b+a)%65521}z.push(...be32((b*65536+a)>>>0));
 chunk("IHDR",[...be32(width),...be32(height),8,6,0,0,0]);
 for(let p=0;p<z.length;p+=10000)chunk("IDAT",z.slice(p,p+10000));
 chunk("IEND",[]);return Uint8Array.from(out)
}
const nav=path.join(__dirname,"..","graphics/icons/navigation");
const routes=path.join(__dirname,"..","graphics/icons/routes");
fs.mkdirSync(nav,{recursive:true});fs.mkdirSync(routes,{recursive:true});
for(const [name,spec] of Object.entries(specs)){
 const paint=drawIcon(name,spec);
 const dir=spec.kind==="route"?routes:nav;
 fs.writeFileSync(path.join(dir,name+".png"),Buffer.from(pngEncode(paint.rgba())));
 if(spec.kind==="route")fs.writeFileSync(path.join(dir,name+".svg"),paint.svg());
}

// The factorio-mod source-of-truth for 11 navigation and 4 route icons.
// Clean silhouette-first marks with the subdued Space Age steel/amber palette.
// No common circular badge; every marker must remain recognizable at 32 px.
// Rebuild: node scripts/generate_navigation_markers.js
const fs=require("node:fs"),path=require("node:path");
const specs={
  "calidus-gate": {
    "kind": "gate",
    "style": "origin",
    "accent": "#dfa750"
  },
  "solaris-gate": {
    "kind": "gate",
    "style": "solar",
    "accent": "#ec9750"
  },
  "nyxaris-gate": {
    "kind": "gate",
    "style": "living",
    "accent": "#80c2a3"
  },
  "vibrant-gate": {
    "kind": "gate",
    "style": "magnetic",
    "accent": "#88b0d9"
  },
  "vespera-gate": {
    "kind": "gate",
    "style": "frozen",
    "accent": "#d4dbe4"
  },
  "beetlejuice-gate": {
    "kind": "gate",
    "style": "binary",
    "accent": "#d4a08f"
  },
  "umbra-gate": {
    "kind": "gate",
    "style": "eclipse",
    "accent": "#c78b66"
  },
  "vibrant-rim-inner": {
    "kind": "rim",
    "style": "metal",
    "inner": true,
    "accent": "#91b9c8"
  },
  "vibrant-rim-outer": {
    "kind": "rim",
    "style": "metal",
    "inner": false,
    "accent": "#a7bac3"
  },
  "umbra-rim-inner": {
    "kind": "rim",
    "style": "broken",
    "inner": true,
    "accent": "#d5a174"
  },
  "umbra-rim-outer": {
    "kind": "rim",
    "style": "broken",
    "inner": false,
    "accent": "#b88a6d"
  },
  "planetary-route": {
    "kind": "route",
    "style": "planetary",
    "accent": "#aac2aa"
  },
  "interstellar-route": {
    "kind": "route",
    "style": "interstellar",
    "accent": "#99b4d0"
  },
  "asteroid-route": {
    "kind": "route",
    "style": "asteroid",
    "accent": "#d4ac72"
  },
  "deep-space-route": {
    "kind": "route",
    "style": "deep",
    "accent": "#a8a6cd"
  }
};
function rgb(s){return [1,3,5].map(n=>parseInt(s.slice(n,n+2),16))}
function orbitPoint(t,rx,ry,tilt,cx=32,cy=32){
 const a=Math.cos(t)*rx,b=Math.sin(t)*ry;
 return [cx+a*Math.cos(tilt)-b*Math.sin(tilt),cy+a*Math.sin(tilt)+b*Math.cos(tilt)];
}
function makePainter(){
 const S=3,W=64*S,raw=new Uint8Array(W*W*4),svg=[];
 const f=x=>Math.round(x*100)/100;
 function dot(x,y,c,a=1){
  x|=0;y|=0;if(x<0||y<0||x>=W||y>=W||a<=0)return;
  let i=(y*W+x)*4,o=raw[i+3]/255,n=a+o*(1-a);if(n===0)return;
  for(let k=0;k<3;k++)raw[i+k]=Math.round((c[k]*a+raw[i+k]*o*(1-a))/n);raw[i+3]=Math.round(n*255);
 }
 function disk(cx,cy,r,color,opacity=1){
  const col=rgb(color);
  for(let y=Math.max(0,Math.floor((cy-r)*S));y<=Math.min(W-1,Math.ceil((cy+r)*S));y++)
   for(let x=Math.max(0,Math.floor((cx-r)*S));x<=Math.min(W-1,Math.ceil((cx+r)*S));x++){
    let dx=(x+.5)/S-cx,dy=(y+.5)/S-cy;if(dx*dx+dy*dy<=r*r)dot(x,y,col,opacity);
   }
  svg.push(`<circle cx="${f(cx)}" cy="${f(cy)}" r="${f(r)}" fill="${color}" opacity="${f(opacity)}"/>`);
 }
 function ray(a,b,c,d,w,color,opacity=1,log=true){
  const col=rgb(color);
  let minx=Math.max(0,Math.floor((Math.min(a,c)-w)*S)),maxx=Math.min(W-1,Math.ceil((Math.max(a,c)+w)*S));
  let miny=Math.max(0,Math.floor((Math.min(b,d)-w)*S)),maxy=Math.min(W-1,Math.ceil((Math.max(b,d)+w)*S));
  let vx=c-a,vy=d-b,n=vx*vx+vy*vy||1;
  for(let y=miny;y<=maxy;y++)for(let x=minx;x<=maxx;x++){
   let xx=(x+.5)/S,yy=(y+.5)/S,t=Math.max(0,Math.min(1,((xx-a)*vx+(yy-b)*vy)/n)),dx=xx-a-t*vx,dy=yy-b-t*vy;
   if(dx*dx+dy*dy<=(w*w)/4)dot(x,y,col,opacity);
  }
  if(log)svg.push(`<path d="M${f(a)} ${f(b)}L${f(c)} ${f(d)}" stroke="${color}" stroke-width="${f(w)}" opacity="${f(opacity)}" stroke-linecap="round" fill="none"/>`);
 }
 function stroke(points,w,color,opacity=1,closed=false){
  for(let i=1;i<points.length;i++)ray(...points[i-1],...points[i],w,color,opacity,false);
  if(closed)ray(...points[points.length-1],...points[0],w,color,opacity,false);
  svg.push(`<path d="${points.map((p,i)=>(i?"L":"M")+f(p[0])+" "+f(p[1])).join("")}${closed?"Z":""}" stroke="${color}" stroke-width="${f(w)}" opacity="${f(opacity)}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>`);
 }
 function polygon(points,color,opacity=1){
  const c=rgb(color);
  let xs=points.map(p=>p[0]),ys=points.map(p=>p[1]);
  for(let y=Math.max(0,Math.floor(Math.min(...ys)*S));y<=Math.min(W-1,Math.ceil(Math.max(...ys)*S));y++)
   for(let x=Math.max(0,Math.floor(Math.min(...xs)*S));x<=Math.min(W-1,Math.ceil(Math.max(...xs)*S));x++){
    let xx=(x+.5)/S,yy=(y+.5)/S,within=false;
    for(let i=0,j=points.length-1;i<points.length;j=i++){
      let u=points[i],v=points[j];
      if((u[1]>yy)!==(v[1]>yy)&&xx<(v[0]-u[0])*(yy-u[1])/(v[1]-u[1])+u[0])within=!within;
    }
    if(within)dot(x,y,c,opacity);
   }
  svg.push(`<path d="${points.map((p,i)=>(i?"L":"M")+f(p[0])+" "+f(p[1])).join("")}Z" fill="${color}" opacity="${f(opacity)}"/>`);
 }
 function elliptical(cx,cy,rx,ry,tilt,a,b,w,color,opacity=1){
  const count=Math.max(14,Math.ceil((b-a)*(rx+ry)*.75)),pts=[];
  for(let i=0;i<=count;i++)pts.push(orbitPoint(a+(b-a)*i/count,rx,ry,tilt,cx,cy));
  stroke(pts,w,color,opacity);
 }
 function arc(cx,cy,r,a,b,w,color,opacity=1){elliptical(cx,cy,r,r,0,a,b,w,color,opacity)}
 function speck(x,y,r,col,opacity=1){disk(x,y,r,col,opacity)}
 function glow(x,y,r,accent){disk(x,y,r+3,accent,.11);disk(x,y,r+1.2,accent,.45);disk(x,y,r,"#ffd98d",.96);disk(x-.65,y-.8,r*.43,"#fff0bd",.92)}
 function asteroid(x,y,r,base="#736c66"){
  let p=[[x-r*.9,y-r*.23],[x-r*.5,y-r*.83],[x+r*.3,y-r],[x+r,y-r*.2],[x+r*.66,y+r*.77],[x-r*.35,y+r]];
  polygon(p,base);stroke([p[0],p[1],p[2],p[3]],1.1,"#c0af96",.73);
  ray(x-r*.23,y-r*.25,x+r*.37,y+r*.34,.7,"#34363a",.52);
 }
 function rgba(){
  const out=new Uint8Array(64*64*4);
  for(let y=0;y<64;y++)for(let x=0;x<64;x++){
   let a=0,sums=[0,0,0];
   for(let iy=0;iy<S;iy++)for(let ix=0;ix<S;ix++){let src=((y*S+iy)*W+x*S+ix)*4,v=raw[src+3]/255;a+=v;for(let c=0;c<3;c++)sums[c]+=raw[src+c]*v}
   let dst=(y*64+x)*4;out[dst+3]=Math.round(a/(S*S)*255);for(let c=0;c<3;c++)out[dst+c]=a?Math.round(sums[c]/a):0;
  }return out;
 }
 function svgText(){return `<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 64 64">\n${svg.join("\n")}\n</svg>\n`;}
 return{disk,ray,stroke,polygon,elliptical,arc,speck,glow,asteroid,rgba,svg:svgText}
}
function iconPaint(name,spec){
 const p=makePainter(),{disk,ray,stroke,polygon,elliptical,arc,speck,glow,asteroid}=p;
 const a=spec.accent,amber="#d7a555",steel="#9b9f9b",lite="#f2d092",PI=Math.PI;
 // Instead of a repeated circular badge, each special location has a
 // distinctive silhouette. Shared visual language = thin metal/orbit lines
 // and carefully limited brass/stellar lighting.
 if(spec.kind==="gate"){
  if(spec.style==="origin"){
   elliptical(32,32,24,10,-.37,.11,PI*1.86,2.5,"#6d7370");
   elliptical(32,32,24,10,-.37,PI*.08,PI*.96,1.4,amber);
   disk(32,32,8.3,"#503e23",.67);glow(32,32,5.4,a);
   asteroid(49,23,3.1,"#8f8470");speck(19,18,1.3,"#ddc589");
  }else if(spec.style==="solar"){
   for(const [r,t]of [[22,-.4],[17,.4],[12,-.4]]){
      arc(32,32,r,-2.33,-.29,2.7,r===22?"#776b5d":a,.91);
      arc(32,32,r,.39,2.34,2.0,"#b7a085",.72);
   }
   for(const ang of [-.45,.7,2.12,3.6,4.7]){let x=32+Math.cos(ang)*27,y=32+Math.sin(ang)*27;ray(32+Math.cos(ang)*22,32+Math.sin(ang)*22,x,y,1.4,"#ee9b54",.89)}
   glow(32,32,6.1,a);
  }else if(spec.style==="living"){
   elliptical(32,32,14,23,.34,0,PI*2,2.3,a,.92);
   elliptical(32,32,22,10,-.52,PI*.12,PI*1.72,1.9,"#9aab95",.88);
   disk(32,32,6.6,"#244333");glow(32,32,4.8,"#8fc9a1");
   for(let [x,y,r]of [[15,40,3.1],[46,18,2.6],[39,47,2]]){disk(x,y,r+1,"#213d38");disk(x,y,r,"#97d1b2");}
  }else if(spec.style==="magnetic"){
   arc(32,32,24,-2.3,-.25,2.4,a);
   arc(32,32,24,.76,2.80,2.4,a);
   // Big angular magnetic discharge, readable against the starfield.
   polygon([[34,10],[24,32],[34,31],[28,53],[46,26],[35,27],[40,14]],"#33485d");
   polygon([[35,13],[26,31],[35,29],[30,48],[43,27],[33,29],[38,16]],"#9dcaed");
   stroke([[16,21],[21,18],[24,24]],1.8,"#aec4d9");
   disk(47,41,3.1,"#e6d6a8");
  }else if(spec.style==="frozen"){
   disk(32,32,17,"#343b44");disk(32,32,15.4,"#a6b8c3");
   disk(28,28,9.4,"#d8e0e2",.78);disk(37,35,5.2,"#78899d",.78);
   elliptical(32,32,26,8.2,.19,.20,PI*1.89,2.7,"#8798a9");
   elliptical(32,32,26,8.2,.19,PI*.96,PI*1.45,1.6,"#f0dfac");
   disk(52,21,3.1,"#c6d7db");speck(12,42,1.8,"#d4dcd9");
  }else if(spec.style==="binary"){
   elliptical(32,32,24,14,-.20,-PI*.37,PI*.49,2.2,"#a79388");
   elliptical(32,32,24,14,-.20,PI*.58,PI*1.69,2.1,a);
   elliptical(32,32,10,25,.76,PI*.24,PI*1.60,1.5,"#a78d79");
   glow(23,37,5.6,"#d7a15c");glow(42,25,4.4,"#ebb7aa");
   speck(16,18,1.6,"#d9c0a7");
  }else{ // Umbra: single unmistakable black eclipse and molten crescent.
   disk(31,32,19.5,"#8b5033",.78);disk(31,32,17,"#ca915d");
   disk(38,27,17.8,"#05070b");
   arc(31,32,24,-2.65,-.46,2.7,a,.88);
   arc(31,32,24,.58,1.91,2.1,"#846f64",.82);
   elliptical(31,32,29,6.3,-.56,.12,PI*.81,2.0,"#bb8d66");
   speck(19,45,2.6,"#f8c88f");
  }
 }else if(spec.kind==="rim"){
  let isUmbra=spec.style==="broken",base=isUmbra?"#745e54":"#738087";
  // Vertical arc of fragmented rocks + a large arrow; never another planet.
  if(isUmbra){
    for(let [x,y,r]of [[20,16,5.4],[15,30,6.7],[22,47,5.7],[47,16,3.7],[48,47,4.1]])asteroid(x,y,r,base);
    arc(32,32,23.5,-1.04,.94,2.3,"#9c6955",.65);
  }else{
    for(let [x,y,r]of [[17,18,5.0],[13,32,5.5],[19,47,5.8],[47,24,3.4],[46,43,2.9]])asteroid(x,y,r,base);
    arc(32,32,23.3,-1.26,1.13,2.1,"#9cabb1",.62);
  }
  let right=!!spec.inner;
  // Bright chevron is the primary map-level silhouette, rock field secondary.
  if(right){
   polygon([[26,23],[38,23],[38,17],[52,32],[38,47],[38,41],[26,41]],"#3c3731");
   polygon([[25,25],[37,25],[37,21],[48,32],[37,43],[37,39],[25,39]],a);
   stroke([[30,29],[39,29],[43,32],[39,35],[30,35]],1.5,"#ffe0ad",.83);
  }else{
   polygon([[41,23],[29,23],[29,17],[14,32],[29,47],[29,41],[41,41]],"#3c3731");
   polygon([[42,25],[30,25],[30,21],[18,32],[30,43],[30,39],[42,39]],a);
   stroke([[38,29],[28,29],[23,32],[28,35],[38,35]],1.5,"#ffe0ad",.83);
  }
 }else if(spec.kind==="route"){
  // The ordinary route types have visibly different paths and endpoint art.
  if(spec.style==="planetary"){
   disk(18,39,10,"#233a3e");disk(18,39,8,"#80a4a4");disk(15.7,36,3,"#cadbd6",.86);
   disk(46,24,7.6,"#4b3727");disk(46,24,5.8,"#d9ad6e");disk(44,22,1.9,"#fff0bf");
   elliptical(31,31,21,13,-.4,PI*.12,PI*1.22,2.8,a);
   stroke([[36,18],[42,20],[41,26]],2.6,"#ece1b8");
   speck(25,18,1.2,"#c1cbd3");
  }else if(spec.style==="interstellar"){
   // Long straight navigation vector with 2 large, four-point star endpoints.
   stroke([[17,46],[47,18]],3.6,"#5b6978");
   stroke([[17,46],[47,18]],1.75,a);
   for(let [x,y,r]of [[17,46,7],[47,18,7]]){
    polygon([[x,y-r-3],[x+2.6,y-2.6],[x+r+3,y],[x+2.6,y+2.6],[x,y+r+3],[x-2.6,y+2.6],[x-r-3,y],[x-2.6,y-2.6]],x===17?"#8ca4bb":"#dcc392");
    disk(x,y,3.4,"#fff0c9");
    disk(x-1,y-.9,1,"#ffffff");
   }
   for(let [x,y]of [[27,18],[39,47],[16,20],[48,43]])speck(x,y,1.2,"#8b95a2",.72);
  }else if(spec.style==="asteroid"){
   stroke([[10,43],[22,36],[32,33],[41,24],[54,19]],3,"#6d5842");
   stroke([[10,43],[22,36],[32,33],[41,24],[54,19]],1.6,"#e4ac62");
   for(let [x,y,r]of [[17,20,7.7],[42,42,8.2],[34,15,3.6],[23,53,4.2]])asteroid(x,y,r,"#79695c");
   polygon([[30,26],[38,31],[31,36]],"#f6cb83");
   disk(12,44,3.1,"#ffe1a0");disk(54,19,3.2,"#f4ba62");
  }else{
   // Deep-space is a fading outbound signal toward a distant violet target.
   glow(16,45,5.1,"#84bbc2");
   stroke([[20,41],[26,35],[32,29]],2.3,"#8ba4bc",.9);
   stroke([[35,26],[40,21]],1.75,"#d5c1e8",.85);
   for(let [x,y]of [[32,29],[38,23],[45,16]])disk(x,y,1.25,"#d8d0e5",.83);
   disk(47,15,11.5,"#534960",.67);
   disk(47,15,8.3,"#9887ba");
   disk(50.3,12.3,7.8,"#03050c");
   arc(47,15,14.0,-2.2,-.05,1.5,"#c2a8e2");
   speck(19,15,1.3,"#bfc7dc",.8);
  }
  // Sparse stellar dust supports category art, no decorative panel.
  for(let [x,y,r]of [[8,15,.9],[58,47,.8],[32,56,.7],[55,8,.65]])speck(x,y,r,"#a6a4a2",.62);
 }
 return p;
}
function pngRGBA(pixels){
 const size=64,bytes=[137,80,78,71,13,10,26,10],be=n=>[(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255];
 function crc(data){let c=0xffffffff;for(const v of data){c^=v;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(c^0xffffffff)>>>0}
 function chunk(kind,data){const body=[...kind].map(c=>c.charCodeAt(0)).concat(data);bytes.push(...be(data.length));for(const b of body)bytes.push(b);bytes.push(...be(crc(body)))}
 const raw=[];for(let y=0;y<size;y++){raw.push(0);for(let x=0;x<size*4;x++)raw.push(pixels[y*size*4+x])}
 const z=[0x78,0x01];for(let off=0;off<raw.length;){let n=Math.min(65535,raw.length-off);z.push(off+n===raw.length?1:0,n&255,(n>>8)&255,(~n)&255,((~n)>>8)&255);for(let i=off;i<off+n;i++)z.push(raw[i]);off+=n}
 let a=1,b=0;for(const v of raw){a=(a+v)%65521;b=(b+a)%65521}z.push(...be((b*65536+a)>>>0));
 chunk("IHDR",[...be(size),...be(size),8,6,0,0,0]);for(let i=0;i<z.length;i+=10000)chunk("IDAT",z.slice(i,i+10000));chunk("IEND",[]);
 return Uint8Array.from(bytes);
}
const nav=path.join(__dirname,"../graphics/icons/navigation");
const routes=path.join(__dirname,"../graphics/icons/routes");
fs.mkdirSync(nav,{recursive:true});fs.mkdirSync(routes,{recursive:true});
for(const [name,spec] of Object.entries(specs)){
 const paint=iconPaint(name,spec);
 const directory=spec.kind==="route"?routes:nav;
 fs.writeFileSync(path.join(directory,name+".png"),Buffer.from(pngRGBA(paint.rgba())));
 if(spec.kind==="route")fs.writeFileSync(path.join(directory,name+".svg"),paint.svg());
}

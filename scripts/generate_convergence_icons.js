// Hand-constructed Factorio-style Convergence mandate icons.
// Five distinct pieces of machinery, no universal glowing circular badge.
// Rebuild: node scripts/generate_convergence_icons.js
// Only Node built-ins; output is deterministic, RGBA 64x64 PNG.
const fs=require('node:fs'),path=require('node:path');
const palette={
  "ink": "#11171d",
  "dark": "#27313a",
  "low": "#394650",
  "steel": "#53646d",
  "edge": "#88999b",
  "bright": "#bac4bd",
  "ivory": "#e0d9bd",
  "bolt": "#b9b4a0",
  "copper": "#a66a3b",
  "copperLite": "#d89b5e",
  "fire": "#eda23c",
  "fireLite": "#ffe2a0",
  "blue": "#50849a",
  "ice": "#8cbfcc",
  "purple": "#8474ac",
  "purpleLite": "#b6a2d8"
};
function makePainter(){
 const S=4,N=64*S,pixels=new Uint8Array(N*N*4),vectors=[];
 function rgb(c){return [1,3,5].map(i=>parseInt(c.slice(i,i+2),16))}
 function set(x,y,c,a){x|=0;y|=0;if(x<0||y<0||x>=N||y>=N||a<=0)return;const p=(y*N+x)*4,b=pixels[p+3]/255,n=a+b*(1-a);for(let k=0;k<3;k++)pixels[p+k]=Math.round((c[k]*a+pixels[p+k]*b*(1-a))/n);pixels[p+3]=Math.round(n*255)}
 function poly(pts,color,opacity=1){
  const c=rgb(color),xs=pts.map(p=>p[0]),ys=pts.map(p=>p[1]);
  const x0=Math.max(0,Math.floor(Math.min(...xs)*S)),x1=Math.min(N-1,Math.ceil(Math.max(...xs)*S)),y0=Math.max(0,Math.floor(Math.min(...ys)*S)),y1=Math.min(N-1,Math.ceil(Math.max(...ys)*S));
  for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++){
    const xx=(x+.5)/S,yy=(y+.5)/S;let inside=false;
    for(let i=0,j=pts.length-1;i<pts.length;j=i++){
      const a=pts[i],b=pts[j];
      if(((a[1]>yy)!==(b[1]>yy))&&(xx<(b[0]-a[0])*(yy-a[1])/(b[1]-a[1])+a[0]))inside=!inside;
    }
    if(inside)set(x,y,c,opacity);
  }
  vectors.push(`<path d="${pts.map((p,i)=>(i?"L":"M")+p[0]+" "+p[1]).join("")}Z" fill="${color}" opacity="${opacity}"/>`);
 }
 function rect(x,y,w,h,c,a=1){poly([[x,y],[x+w,y],[x+w,y+h],[x,y+h]],c,a)}
 function ellipse(cx,cy,rx,ry,color,opacity=1){
  const col=rgb(color);for(let y=Math.max(0,Math.floor((cy-ry)*S));y<=Math.min(N-1,Math.ceil((cy+ry)*S));y++)for(let x=Math.max(0,Math.floor((cx-rx)*S));x<=Math.min(N-1,Math.ceil((cx+rx)*S));x++){const dx=((x+.5)/S-cx)/rx,dy=((y+.5)/S-cy)/ry;if(dx*dx+dy*dy<=1)set(x,y,col,opacity)}
  vectors.push(`<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${color}" opacity="${opacity}"/>`);
 }
 function circ(x,y,r,c,a=1){ellipse(x,y,r,r,c,a)}
 function line(x1,y1,x2,y2,w,color,opacity=1){
  const c=rgb(color),dx=x2-x1,dy=y2-y1,l=dx*dx+dy*dy||1;
  for(let y=Math.max(0,Math.floor((Math.min(y1,y2)-w)*S));y<=Math.min(N-1,Math.ceil((Math.max(y1,y2)+w)*S));y++)for(let x=Math.max(0,Math.floor((Math.min(x1,x2)-w)*S));x<=Math.min(N-1,Math.ceil((Math.max(x1,x2)+w)*S));x++){const xx=(x+.5)/S,yy=(y+.5)/S,t=Math.max(0,Math.min(1,((xx-x1)*dx+(yy-y1)*dy)/l)),qx=xx-x1-t*dx,qy=yy-y1-t*dy;if(qx*qx+qy*qy<=w*w/4)set(x,y,c,opacity)}
  vectors.push(`<path d="M${x1} ${y1}L${x2} ${y2}" stroke="${color}" stroke-width="${w}" stroke-linecap="round" opacity="${opacity}" fill="none"/>`);
 }
 function path(pts,w,c,a=1){for(let i=1;i<pts.length;i++)line(...pts[i-1],...pts[i],w,c,a)}
 function bolt(x,y){circ(x+.5,y+.7,1.8,palette.ink);circ(x,y,1.35,palette.bolt);circ(x-.4,y-.4,.45,palette.ivory)}
 function raster(){let result=new Uint8Array(64*64*4);for(let y=0;y<64;y++)for(let x=0;x<64;x++){let sum=0,cols=[0,0,0];for(let oy=0;oy<S;oy++)for(let ox=0;ox<S;ox++){const q=((y*S+oy)*N+x*S+ox)*4,alpha=pixels[q+3]/255;sum+=alpha;for(let c=0;c<3;c++)cols[c]+=pixels[q+c]*alpha}const d=(y*64+x)*4;result[d+3]=Math.round(sum/(S*S)*255);for(let c=0;c<3;c++)result[d+c]=sum?Math.round(cols[c]/sum):0}return result}
 function svg(){return `<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 64 64">\n${vectors.join("\n")}\n</svg>\n`}
 return {poly,rect,ellipse,circ,line,path,bolt,raster,svg};
}
function draw(stage){
 const p=makePainter(),{poly:P,rect:R,ellipse:E,circ:C,line:L,path:S,bolt:V}=p,c=palette;
 if(stage==="stellar"){
   // A shielded solar collector, its coupling spars and faceted amber cell.
   P([[10,24],[16,20],[22,23],[22,44],[17,48],[10,44]],c.ink);
   P([[12,25],[17,22],[20,24],[20,43],[17,46],[12,43]],c.steel);
   P([[43,19],[49,17],[55,24],[54,43],[49,47],[43,43]],c.ink);
   P([[45,21],[49,20],[52,25],[52,42],[48,45],[45,42]],c.low);
   P([[14,19],[23,13],[40,13],[50,20],[46,27],[19,27]],c.ink);
   P([[18,19],[25,15],[39,15],[47,20],[43,24],[20,24]],c.steel);
   L(25,17,39,17,1.3,c.bright);
   P([[13,42],[25,47],[42,47],[50,40],[54,45],[43,53],[23,53],[9,45]],c.ink);
   P([[15,44],[26,49],[42,49],[49,44],[44,40],[22,40]],c.low);
   P([[27,20],[36,20],[43,25],[46,33],[41,42],[33,45],[24,41],[19,35],[20,26]],c.ink);
   P([[27,22],[35,22],[41,27],[43,32],[39,39],[33,42],[26,40],[22,34],[23,27]],c.copper);
   P([[28,24],[35,24],[39,28],[40,32],[37,38],[31,39],[27,36],[25,31]],c.copperLite);
   P([[29,26],[34,26],[38,30],[37,35],[32,37],[28,34]],c.fire);
   C(32,31,3.7,c.fireLite);C(30.7,30,1.4,"#fff3d6");
   P([[8,29],[19,27],[22,31],[18,35],[8,34]],c.dark);R(11,30,8,3,c.edge);
   P([[42,28],[56,25],[56,30],[43,34]],c.dark);L(46,29,55,28,1.7,c.edge);
   V(15,24);V(49,41);V(30,49);
 }else if(stage==="industry"){
   // Foundry die press with a moving platen, cast billets and conveyor.
   P([[11,17],[17,11],[47,11],[53,17],[53,48],[47,54],[11,54],[7,49],[7,22]],c.ink);
   P([[12,18],[18,13],[46,13],[51,19],[51,48],[45,52],[12,52],[9,48],[9,23]],c.low);
   P([[14,18],[20,14],[43,14],[47,18],[47,22],[15,22]],c.steel);L(19,16,43,16,1.2,c.bright);
   R(27,7,11,8,c.ink);R(29,9,7,11,c.edge);R(30,11,5,8,c.bright);
   P([[19,20],[45,20],[47,26],[18,26]],c.dark);P([[19,24],[46,24],[43,29],[22,29]],c.copperLite);
   for(let x of [15,26,37]){
     P([[x,30],[x+8,30],[x+10,34],[x+10,42],[x+7,45],[x,43]],c.ink);
     P([[x+1,31],[x+7,31],[x+9,34],[x+9,41],[x+7,43],[x+1,42]],c.copper);
     P([[x+1,31],[x+7,31],[x+8,34],[x+2,34]],c.fireLite);
     L(x+2,37,x+7,37,1.1,c.copperLite);
   }
   P([[7,44],[55,44],[57,49],[51,55],[12,55],[6,50]],c.ink);
   P([[8,46],[54,46],[52,51],[10,51]],c.steel);L(12,47,52,47,1.3,c.bright);
   for(let x of [15,26,37,48]){C(x,51,1.9,c.ink);C(x,50.8,1.05,c.edge)}
   V(13,21);V(49,21);
 }else if(stage==="deep-space"){
   // Long receiver mast and actual faceted radio dish, blue signal face.
   P([[7,49],[17,45],[30,48],[28,55],[9,57],[6,53]],c.ink);
   P([[9,49],[17,47],[27,49],[26,53],[10,54]],c.low);
   L(13,51,25,51,1.5,c.edge);V(13,51);
   P([[18,45],[22,39],[37,22],[42,27],[27,45],[26,51]],c.ink);
   P([[20,44],[24,40],[38,24],[40,27],[25,45]],c.steel);L(25,39,37,26,1.3,c.bright);
   P([[27,11],[33,8],[45,12],[54,24],[56,33],[49,39],[39,36],[31,28]],c.ink);
   P([[29,12],[34,10],[44,14],[52,24],[54,32],[49,36],[39,33],[33,27]],c.low);
   P([[31,12],[39,15],[48,23],[51,31],[48,32],[40,27]],c.blue);
   P([[31,12],[39,15],[47,23],[48,25],[40,22]],c.ice);
   L(38,19,47,28,1.1,"#d2e2df");L(45,29,52,17,2,c.edge);
   C(52,16,2.3,c.copperLite);C(52,16,.8,c.fireLite);
   L(18,42,10,33,1.8,c.copper);C(10,32,1.8,c.fireLite);
   L(27,48,33,44,2,c.dark);V(24,46);
 }else if(stage==="resonance"){
   // Three visible wound electromagnets: busbars, ferrite and capacitors.
   P([[9,15],[13,11],[51,11],[56,16],[55,23],[9,23]],c.ink);
   P([[11,16],[15,13],[50,13],[53,16],[53,21],[11,21]],c.steel);
   L(14,16,51,16,1.1,c.bright);V(13,19);V(51,19);
   P([[9,43],[55,43],[56,50],[51,54],[14,54],[8,50]],c.ink);
   P([[11,45],[53,45],[51,51],[14,51]],c.low);L(14,47,51,47,1.3,c.edge);
   for(let x of [13,27,41]){
     P([[x,22],[x+10,22],[x+12,26],[x+12,39],[x+9,43],[x,42],[x-2,38],[x-2,27]],c.ink);
     P([[x+1,23],[x+9,23],[x+10,27],[x+10,39],[x+8,41],[x+1,40]],c.steel);
     P([[x+3,25],[x+7,25],[x+9,30],[x+8,38],[x+3,39],[x+1,34]],c.purple);
     for(let i=0;i<3;i++)L(x+1,29+i*4,x+10,29+i*4,1.7,c.purpleLite);
     L(x+1,27,x+8,27,1,c.ivory,.78);
   }
   S([[24,27],[28,24],[32,27],[35,23],[38,26]],1.3,"#cfb9ed");
   R(16,52,7,4,c.dark);R(42,52,7,4,c.dark);V(30,49);
 }else if(stage==="ignition"){
   // Cylindrical thruster, cast heat collar and asymmetric pale exhaust plume.
   P([[23,8],[39,8],[44,13],[44,30],[20,30],[20,13]],c.ink);
   P([[25,10],[38,10],[42,14],[42,28],[22,28],[22,14]],c.steel);
   P([[27,12],[36,12],[39,16],[38,29],[25,29],[24,16]],c.dark);L(27,13,36,13,1.2,c.bright);
   for(let [x,y] of [[17,16],[43,16]]){
     P([[x,y],[x+4,y-3],[x+7,y-1],[x+7,y+12],[x+4,y+14],[x,y+11]],c.ink);
     P([[x+2,y+2],[x+5,y],[x+5,y+11],[x+2,y+10]],c.low);
   }
   P([[14,27],[49,27],[55,34],[52,42],[43,46],[21,46],[11,41],[10,33]],c.ink);
   P([[15,30],[48,30],[52,35],[49,40],[42,43],[22,43],[15,39],[13,34]],c.steel);
   P([[20,34],[43,34],[46,39],[41,45],[23,45],[18,39]],c.copper);
   P([[23,36],[40,36],[42,40],[38,43],[25,43],[21,40]],c.copperLite);L(17,32,48,32,1.3,c.bright);
   P([[24,44],[40,44],[42,51],[37,59],[33,55],[28,62],[23,55],[21,51]],c.copper);
   P([[26,44],[39,44],[40,50],[36,57],[33,53],[29,59],[26,52]],c.fire);
   P([[29,44],[36,44],[37,50],[34,54],[32,51],[30,56],[28,50]],c.fireLite);
   P([[31,45],[35,45],[34,51],[32,49]],"#fff3d1");
   V(17,37);V(46,37);
 }
 return p
}
function pngEncode(data){
 const out=[137,80,78,71,13,10,26,10],be32=n=>[(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255];
 function crc(bytes){let c=0xffffffff;for(const d of bytes){c^=d;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(c^0xffffffff)>>>0}
 function chunk(kind,bytes){const body=[...kind].map(c=>c.charCodeAt(0)).concat(bytes);out.push(...be32(bytes.length));for(let b of body)out.push(b);out.push(...be32(crc(body)))}
 const raw=[];for(let y=0;y<64;y++){raw.push(0);for(let j=0;j<256;j++)raw.push(data[y*256+j])}
 const z=[0x78,0x01];for(let i=0;i<raw.length;){let n=Math.min(65535,raw.length-i);z.push(i+n===raw.length?1:0,n&255,(n>>8)&255,(~n)&255,((~n)>>8)&255);for(let j=i;j<i+n;j++)z.push(raw[j]);i+=n}
 let a=1,b=0;for(const d of raw){a=(a+d)%65521;b=(b+a)%65521}z.push(...be32((b*65536+a)>>>0));
 chunk("IHDR",[...be32(64),...be32(64),8,6,0,0,0]);for(let i=0;i<z.length;i+=10000)chunk("IDAT",z.slice(i,i+10000));chunk("IEND",[]);
 return Uint8Array.from(out)
}
const out=path.join(__dirname,'..','graphics','icons','convergence');
fs.mkdirSync(out,{recursive:true});
for(const stage of ['stellar','industry','deep-space','resonance','ignition']){
 const painter=draw(stage);
 fs.writeFileSync(path.join(out,'razi-convergence-'+stage+'.png'),Buffer.from(pngEncode(painter.raster())));
 fs.writeFileSync(path.join(out,'razi-convergence-'+stage+'.svg'),painter.svg());
}

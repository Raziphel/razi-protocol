// Deterministic, standalone white 64px native-route difficulty marker.
// Regenerate: node scripts/generate_quality_route_marker.js
// Tint at data stage via scripts/razi_asteroid_difficulty.lua's 10 colors.
const fs=require("node:fs"),path=require("node:path");
function pngEncode(pixels) {
 const B=[137,80,78,71,13,10,26,10],u32=n=>[(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255];
 function crc(v){let x=0xffffffff;for(const b of v){x^=b;for(let i=0;i<8;i++)x=(x>>>1)^((x&1)?0xedb88320:0)}return(x^0xffffffff)>>>0}
 function chunk(t,v){const body=[...t].map(x=>x.charCodeAt(0)).concat(v);B.push(...u32(v.length));for(const q of body)B.push(q);B.push(...u32(crc(body)))}
 const raw=[];for(let y=0;y<64;y++){raw.push(0);for(let x=0;x<256;x++)raw.push(pixels[y*256+x])}
 let z=[0x78,0x01];for(let i=0;i<raw.length;){const count=Math.min(65535,raw.length-i);z.push(i+count===raw.length?1:0,count&255,count>>8,(~count)&255,((~count)>>8)&255);for(let j=i;j<i+count;j++)z.push(raw[j]);i+=count}
 let a=1,b=0;for(const n of raw){a=(a+n)%65521;b=(b+a)%65521}z.push(...u32(((b<<16)|a)>>>0));
 chunk("IHDR",[...u32(64),...u32(64),8,6,0,0,0]);for(let i=0;i<z.length;i+=10000)chunk("IDAT",z.slice(i,i+10000));chunk("IEND",[]);return Uint8Array.from(B);
}
function drawMarker() {
 const S=4,N=S*64,raw=new Uint8Array(N*N*4);
 function dot(x,y,c,a=1){if(x<0||y<0||x>=N||y>=N||a<=0)return;let i=(y*N+x)*4,old=raw[i+3]/255,next=a+old*(1-a);for(let k=0;k<3;k++)raw[i+k]=Math.round((c[k]*a+raw[i+k]*old*(1-a))/next);raw[i+3]=Math.round(next*255)}
 function polygon(pts,c,a=1){
  const xx=pts.map(p=>p[0]),yy=pts.map(p=>p[1]);
  for(let y=Math.max(0,Math.floor(Math.min(...yy)*S));y<=Math.min(N-1,Math.ceil(Math.max(...yy)*S));y++)for(let x=Math.max(0,Math.floor(Math.min(...xx)*S));x<=Math.min(N-1,Math.ceil(Math.max(...xx)*S));x++){
   const px=(x+.5)/S,py=(y+.5)/S;let inside=false;
   for(let i=0,j=pts.length-1;i<pts.length;j=i++){const u=pts[i],v=pts[j];if((u[1]>py)!==(v[1]>py)&&px<(v[0]-u[0])*(py-u[1])/(v[1]-u[1])+u[0])inside=!inside}
   if(inside)dot(x,y,c,a);
  }
 }
 // White-only signal pip: tint maps EXACTLY to the chosen level color.
 // No duplicated path/line, no ornamental ring, no gradient or dark frame.
 polygon([[9,32],[22,20],[42,20],[55,32],[42,44],[22,44]],[255,255,255],.22);
 polygon([[13,32],[24,24],[40,24],[51,32],[40,40],[24,40]],[255,255,255],.99);
 polygon([[19,32],[26,28],[38,28],[45,32],[38,36],[26,36]],[255,255,255],.56);
 let out=new Uint8Array(64*64*4);
 for(let y=0;y<64;y++)for(let x=0;x<64;x++){
  let w=0,sum=[0,0,0];
  for(let dy=0;dy<S;dy++)for(let dx=0;dx<S;dx++){let p=((y*S+dy)*N+x*S+dx)*4,v=raw[p+3]/255;w+=v;for(let c=0;c<3;c++)sum[c]+=raw[p+c]*v}
  let k=(y*64+x)*4;out[k+3]=Math.round(w/(S*S)*255);for(let c=0;c<3;c++)out[k+c]=w?Math.round(sum[c]/w):0;
 }
 return out;
}
const output=path.join(__dirname,"..","graphics/route-highlights");
fs.mkdirSync(output,{recursive:true});
fs.writeFileSync(path.join(output,"quality-risk-marker.png"),Buffer.from(pngEncode(drawMarker())));

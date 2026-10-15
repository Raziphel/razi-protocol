// Thin white oriented route ribbons, painted by the Factorio sprite atlas.
// Regenerate from repo root: node scripts/generate_route_ribbons.js
// The 128 orientations use antialiasing and transparent join overlaps, so
// short route chords render continuously with no dotted or square joins.
// Runtime only reads this image; no script, entity or per-frame drawing.
const fs=require("node:fs"),path=require("node:path");
const bearings=128,cell=64,columns=16,rows=8;
const width=columns*cell,height=rows*cell;
function renderAtlas(){
 const pixels=new Uint8Array(width*height*4),ss=3;
 for(let index=0;index<bearings;index++){
  const angle=index*Math.PI/bearings,c=Math.cos(angle),s=Math.sin(angle),tx=(index%columns)*cell,ty=Math.floor(index/columns)*cell;
  for(let y=0;y<cell;y++)for(let x=0;x<cell;x++){
   let alpha=0;
   for(let sy=0;sy<ss;sy++)for(let sx=0;sx<ss;sx++){
    let px=x+(sx+.5)/ss-cell/2,py=y+(sy+.5)/ss-cell/2;
    const along=px*c+py*s,cross=Math.abs(-px*s+py*c);
    // A soft joined hairline with a small overlap at each endpoint.
    const cutoff=Math.min(1,Math.max(0,27.5-Math.abs(along)));
    let coverage=cross<=.78?1:cross<=1.95?(1.95-cross)/1.17*.20:0;
    alpha+=coverage*cutoff;
   }
   const off=((ty+y)*width+tx+x)*4;
   pixels[off]=255;pixels[off+1]=255;pixels[off+2]=255;
   pixels[off+3]=Math.round(alpha/(ss*ss)*255);
  }
 }
 return pixels;
}
function encodePNG(pixels){
 const bytes=[137,80,78,71,13,10,26,10],u32=n=>[(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255];
 function crc(data){let c=0xffffffff;for(let v of data){c^=v;for(let k=0;k<8;k++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(c^0xffffffff)>>>0}
 function chunk(type,data){const body=Array.from(type).map(ch=>ch.charCodeAt(0)).concat(data);bytes.push(...u32(data.length));for(const b of body)bytes.push(b);bytes.push(...u32(crc(body)))}
 const raw=[];for(let y=0;y<height;y++){raw.push(0);for(let x=0;x<width*4;x++)raw.push(pixels[y*width*4+x])}
 const z=[0x78,0x01];
 for(let i=0;i<raw.length;){let n=Math.min(65535,raw.length-i);z.push(i+n===raw.length?1:0,n&255,(n>>>8)&255,(~n)&255,((~n)>>>8)&255);for(let k=0;k<n;k++)z.push(raw[i+k]);i+=n}
 let a=1,b=0;for(const v of raw){a=(a+v)%65521;b=(b+a)%65521}z.push(...u32((b*65536+a)>>>0));
 chunk("IHDR",[...u32(width),...u32(height),8,6,0,0,0]);for(let i=0;i<z.length;i+=16000)chunk("IDAT",z.slice(i,i+16000));chunk("IEND",[]);
 return Uint8Array.from(bytes);
}
const output=path.join(__dirname,"../graphics/route-highlights/route-ribbons.png");
fs.mkdirSync(path.dirname(output),{recursive:true});
fs.writeFileSync(output,Buffer.from(encodePNG(renderAtlas())));

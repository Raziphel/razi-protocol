// Builds the 64-bearing, pale-alpha stroke atlas used by the built-in
// data-stage starmap route renderer. This is artwork, not runtime Lua.
// Each continuous line tapers gently at its tips and has no dash pattern.
// Usage: node scripts/generate_route_stroke_atlas.js
const fs=require("node:fs");
const path=require("node:path");
const CELL=128,COLUMNS=8,BEARINGS=64,LENGTH=110;
const WIDTH=CELL*COLUMNS,HEIGHT=CELL*(BEARINGS/COLUMNS);
const alpha=new Uint8Array(WIDTH*HEIGHT);

for(let bearing=0;bearing<BEARINGS;bearing++){
  const theta=(bearing/BEARINGS)*Math.PI;
  const dx=Math.cos(theta),dy=Math.sin(theta);
  const tx=(bearing%COLUMNS)*CELL,ty=Math.floor(bearing/COLUMNS)*CELL;
  for(let y=0;y<CELL;y++)for(let x=0;x<CELL;x++){
    const xx=x+.5-CELL/2,yy=y+.5-CELL/2;
    const along=xx*dx+yy*dy,offset=-xx*dy+yy*dx;
    const width=Math.max(0,Math.min(1,1.55-Math.abs(offset)));
    const ends=Math.max(0,Math.min(1,(LENGTH/2+.8-Math.abs(along))/2.7));
    alpha[(ty+y)*WIDTH+tx+x]=Math.max(0,
      Math.min(15,Math.round(width*ends*.92*15)));
  }
}
function be32(n){return [(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255]}
function crc32(bytes){
  let state=0xffffffff;
  for(const b of bytes){
    state^=b;
    for(let i=0;i<8;i++)state=(state>>>1)^((state&1)?0xedb88320:0);
  }
  return(state^0xffffffff)>>>0;
}
const data=[137,80,78,71,13,10,26,10];
function chunk(name,values){
  const tag=[...name].map(c=>c.charCodeAt(0));
  data.push(...be32(values.length),...tag);
  for(const v of values)data.push(v);
  data.push(...be32(crc32([...tag,...values])));
}
chunk("IHDR",[...be32(WIDTH),...be32(HEIGHT),4,3,0,0,0]);
chunk("PLTE",Array.from({length:16},()=>[255,255,255]).flat());
chunk("tRNS",Array.from({length:16},(_,i)=>i*17));
const scanlines=[];
for(let y=0;y<HEIGHT;y++){
  scanlines.push(0); // PNG filter: None
  for(let x=0;x<WIDTH;x+=2)
    scanlines.push((alpha[y*WIDTH+x]<<4)|alpha[y*WIDTH+x+1]);
}
// zlib stream of standard stored DEFLATE blocks and Adler-32.
const compressed=[0x78,0x01];
for(let offset=0;offset<scanlines.length;){
  const length=Math.min(65535,scanlines.length-offset);
  compressed.push(offset+length===scanlines.length?1:0,
    length&255,(length>>8)&255,(~length)&255,((~length)>>8)&255);
  for(let i=offset;i<offset+length;i++)compressed.push(scanlines[i]);
  offset+=length;
}
let a=1,b=0;
for(const v of scanlines){a=(a+v)%65521;b=(b+a)%65521}
compressed.push(...be32((b*65536+a)>>>0));
for(let i=0;i<compressed.length;i+=16000)
  chunk("IDAT",compressed.slice(i,i+16000));
chunk("IEND",[]);
const target=path.join(__dirname,"..","graphics/route-highlights/continuous-strokes.png");
fs.mkdirSync(path.dirname(target),{recursive:true});
fs.writeFileSync(target,Buffer.from(data));
console.log("Wrote",target,WIDTH+"x"+HEIGHT,"bearing tiles:",BEARINGS);

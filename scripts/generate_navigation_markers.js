// Clean 64px navigation markers inspired by Space Age's solar-system-edge
// proportions and palette, not copies of its art. No additional dependencies.
// Usage: node scripts/generate_navigation_markers.js
const fs=require("node:fs"),path=require("node:path");
const specs={
  "calidus-gate": {
    "kind": "gate",
    "index": 0,
    "edge": "#b79a67"
  },
  "solaris-gate": {
    "kind": "gate",
    "index": 1,
    "edge": "#b08065"
  },
  "nyxaris-gate": {
    "kind": "gate",
    "index": 2,
    "edge": "#83aaa1"
  },
  "vibrant-gate": {
    "kind": "gate",
    "index": 3,
    "edge": "#849dc5"
  },
  "vespera-gate": {
    "kind": "gate",
    "index": 4,
    "edge": "#b8bbc1"
  },
  "beetlejuice-gate": {
    "kind": "gate",
    "index": 5,
    "edge": "#bc9697"
  },
  "umbra-gate": {
    "kind": "gate",
    "index": 6,
    "edge": "#aa8475"
  },
  "vibrant-rim-inner": {
    "kind": "rim",
    "index": 0,
    "edge": "#899eaf",
    "inner": true,
    "system": "vibrant"
  },
  "vibrant-rim-outer": {
    "kind": "rim",
    "index": 1,
    "edge": "#899eaf",
    "inner": false,
    "system": "vibrant"
  },
  "umbra-rim-inner": {
    "kind": "rim",
    "index": 2,
    "edge": "#ae8c76",
    "inner": true,
    "system": "umbra"
  },
  "umbra-rim-outer": {
    "kind": "rim",
    "index": 3,
    "edge": "#ae8c76",
    "inner": false,
    "system": "umbra"
  }
};
function rgb(hex){return [1,3,5].map(x=>parseInt(hex.slice(x,x+2),16))}
function draw(name, spec) {
  const S=3,W=64*S,raw=new Uint8Array(W*W*4),shade=rgb(spec.edge);
  const cBlack=[6,8,10],cGold=[189,140,49];
  function blend(x,y,c,a=1) {
    x|=0;y|=0;if(x<0||y<0||x>=W||y>=W||a<=0)return;
    let k=(y*W+x)*4,o=raw[k+3]/255,n=a+o*(1-a);if(n<=0)return;
    for(let j=0;j<3;j++)raw[k+j]=Math.round((c[j]*a+raw[k+j]*o*(1-a))/n);
    raw[k+3]=Math.min(255,Math.round(n*255));
  }
  function disk(cx,cy,r,c,a=1){
    for(let y=Math.floor((cy-r)*S);y<=Math.ceil((cy+r)*S);y++)
      for(let x=Math.floor((cx-r)*S);x<=Math.ceil((cx+r)*S);x++){
        const dx=(x+.5)/S-cx,dy=(y+.5)/S-cy;
        if(dx*dx+dy*dy<=r*r)blend(x,y,c,a);
      }
  }
  function segment(ax,ay,bx,by,thickness,c,a=1){
    const minX=Math.max(0,Math.floor((Math.min(ax,bx)-thickness)*S)),
      maxX=Math.min(W-1,Math.ceil((Math.max(ax,bx)+thickness)*S)),
      minY=Math.max(0,Math.floor((Math.min(ay,by)-thickness)*S)),
      maxY=Math.min(W-1,Math.ceil((Math.max(ay,by)+thickness)*S));
    const vx=bx-ax,vy=by-ay,len=vx*vx+vy*vy||1;
    for(let y=minY;y<=maxY;y++)for(let x=minX;x<=maxX;x++){
      const xx=(x+.5)/S,yy=(y+.5)/S,
        t=Math.max(0,Math.min(1,((xx-ax)*vx+(yy-ay)*vy)/len)),
        dx=xx-(ax+t*vx),dy=yy-(ay+t*vy);
      if(dx*dx+dy*dy<=thickness*thickness/4)blend(x,y,c,a);
    }
  }
  function curve(points,w,c,a=1){
    for(let i=1;i<points.length;i++)segment(...points[i-1],...points[i],w,c,a);
  }
  function circleArc(cx,cy,r,from,to,w,c,a=1){
    const steps=Math.ceil(Math.abs(to-from)*r*1.5)+1,points=[];
    for(let i=0;i<=steps;i++){
      const t=from+(to-from)*i/steps;
      points.push([cx+Math.cos(t)*r,cy+Math.sin(t)*r]);
    }
    curve(points,w,c,a);
  }
  function orbitPoint(t,tilt,rad=1){
    const ex=Math.cos(t)*17.7*rad,ey=Math.sin(t)*7.4*rad;
    return [32+ex*Math.cos(tilt)-ey*Math.sin(tilt),32+ex*Math.sin(tilt)+ey*Math.cos(tilt)];
  }
  // Match the quiet Space Age locator language: thin rim, dark center.
  disk(32,32,28.1,[7,8,10],.6);
  disk(32,32,27,[23,25,27]);
  disk(32,32,26.2,[88,89,89]);
  disk(32,32,24.8,[29,31,33]);
  disk(32,32,23.7,cBlack);
  circleArc(32,32,25.8,-2.7,-.75,1.25,[163,166,166],.65);
  circleArc(32,32,25.8,.58,2.15,.85,[106,107,108],.36);
  circleArc(32,32,22.95,-2.2,-.65,.7,shade,.16);
  const tilt=(spec.kind==="rim"?.43:.50)+((spec.kind==="gate"?spec.index:0)-3)*.022;
  const ellipse=[];
  for(let i=0;i<=136;i++)ellipse.push(orbitPoint(i*Math.PI*2/136,tilt));
  curve(ellipse,1.65,[111,82,33],.84);
  const lit=[];for(let i=15;i<=72;i++)lit.push(orbitPoint(i*Math.PI*2/136,tilt));
  curve(lit,.9,cGold,.88);
  disk(32,32,5.35,[101,62,17],.31);
  disk(32,32,3.75,[222,139,23],.78);
  disk(32,32,2.25,[255,196,62]);
  disk(31.45,31.25,1,[255,249,200],.92);
  if(spec.kind==="gate"){
    // Small star-specific accent mark and satellite, no complex emblems.
    const pos=[-1.55,-.72,.12,.95,1.79,2.61,3.46][spec.index];
    circleArc(32,32,25.85,pos-.15,pos+.15,1.8,shade,.9);
    const satellite=orbitPoint(pos*1.8+1.2,tilt,.98);
    disk(...satellite,2.2,[87,62,25],.75);
    disk(...satellite,1.15,shade,.94);
  }else{
    const rock=spec.system==="umbra"?[105,88,78]:[91,98,104];
    disk(21.8,19.5,2.1,rock,.96);
    disk(19.5,22.2,1.25,shade,.77);
    disk(23.3,18.4,.7,[173,166,145],.75);
    if(spec.inner){
      curve([[20.1,34.4],[16.8,31.7],[20.1,28.9]],1.55,shade,.94);
      circleArc(32,32,25.85,2.82,3.44,1.55,shade,.68);
    }else{
      curve([[43.9,28.9],[47.2,31.7],[43.9,34.4]],1.55,shade,.94);
      circleArc(32,32,25.85,-.32,.32,1.55,shade,.68);
    }
  }
  const result=new Uint8Array(64*64*4);
  for(let y=0;y<64;y++)for(let x=0;x<64;x++){
    let i=(y*64+x)*4,a=0,sum=[0,0,0];
    for(let py=0;py<S;py++)for(let px=0;px<S;px++){
      const j=((y*S+py)*W+(x*S+px))*4,alpha=raw[j+3]/255;
      a+=alpha;for(let k=0;k<3;k++)sum[k]+=raw[j+k]*alpha;
    }
    result[i+3]=Math.round(a/(S*S)*255);
    for(let k=0;k<3;k++)result[i+k]=a?Math.round(sum[k]/a):0;
  }
  return result;
}
function pngRGBA(pixels,width=64,height=64){
 const bytes=[137,80,78,71,13,10,26,10];
 const be32=n=>[(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255];
 function crc(buf){let c=0xffffffff;for(const b of buf){c^=b;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(c^0xffffffff)>>>0}
 function chunk(kind,data){const payload=[...kind].map(c=>c.charCodeAt(0)).concat(data);bytes.push(...be32(data.length));for(const b of payload)bytes.push(b);bytes.push(...be32(crc(payload)))}
 let raw=[];for(let y=0;y<height;y++){raw.push(0);for(let i=0;i<width*4;i++)raw.push(pixels[y*width*4+i])}
 const z=[0x78,0x01];for(let p=0;p<raw.length;){const len=Math.min(65535,raw.length-p),end=p+len===raw.length;z.push(end?1:0,len&255,(len>>8)&255,(~len)&255,((~len)>>8)&255);for(let j=p;j<p+len;j++)z.push(raw[j]);p+=len}
 let a=1,b=0;for(let i=0;i<raw.length;i++){a=(a+raw[i])%65521;b=(b+a)%65521}
 z.push(...be32((b*65536+a)>>>0));
 chunk("IHDR",[...be32(width),...be32(height),8,6,0,0,0]);
 for(let i=0;i<z.length;i+=12000)chunk("IDAT",z.slice(i,i+12000));
 chunk("IEND",[]);
 return Uint8Array.from(bytes);
}
const output=path.join(__dirname,"..","graphics","icons","navigation");
fs.mkdirSync(output,{recursive:true});
for(const [name,spec] of Object.entries(specs)) {
  fs.writeFileSync(path.join(output,name+".png"),Buffer.from(pngRGBA(draw(name,spec))));
}

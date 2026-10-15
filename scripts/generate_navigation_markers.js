// Regenerate 11 Razi-owned static Factorio-style navigation textures.

// Run: node scripts/generate_navigation_markers.js

// No external libraries. This does not run inside Factorio.

const fs=require('node:fs'),path=require('node:path');

const specs={
  "calidus-gate": [
    "gate",
    0,
    "#edb969",
    "#ffe0a0"
  ],
  "solaris-gate": [
    "gate",
    1,
    "#e78344",
    "#ffd482"
  ],
  "nyxaris-gate": [
    "gate",
    2,
    "#4dc4a2",
    "#bbf9d3"
  ],
  "vibrant-gate": [
    "gate",
    3,
    "#7aa5ec",
    "#d6e4ff"
  ],
  "vespera-gate": [
    "gate",
    4,
    "#acbfd7",
    "#fff0cb"
  ],
  "beetlejuice-gate": [
    "gate",
    5,
    "#d88776",
    "#ffd2a0"
  ],
  "umbra-gate": [
    "gate",
    6,
    "#a56d56",
    "#eeb777"
  ],
  "vibrant-rim-inner": [
    "rim",
    7,
    "#a5b8c6",
    "#dae6ea"
  ],
  "vibrant-rim-outer": [
    "rim",
    8,
    "#7e9ab1",
    "#ebcdaa"
  ],
  "umbra-rim-inner": [
    "rim",
    9,
    "#bc8a68",
    "#f4d0a0"
  ],
  "umbra-rim-outer": [
    "rim",
    10,
    "#9d6b61",
    "#ffd0ae"
  ]
};

function rgb(s){return [parseInt(s.slice(1,3),16),parseInt(s.slice(3,5),16),parseInt(s.slice(5,7),16)]}

function paint(id,setting){
 const [kind,num,color,accent]=setting,C=rgb(color),A=rgb(accent),N=128,S=2,pixels=new Uint8Array(N*N*4);
 function dot(x,y,c,a=1){x|=0;y|=0;if(x<0||y<0||x>=N||y>=N||a<=0)return;let k=(y*N+x)*4,o=pixels[k+3]/255,alpha=a+o*(1-a);for(let j=0;j<3;j++)pixels[k+j]=Math.round((c[j]*a+pixels[k+j]*o*(1-a))/alpha);pixels[k+3]=Math.round(alpha*255)}
 function circle(cx,cy,r,c,a=1){for(let y=Math.floor((cy-r)*S);y<=Math.ceil((cy+r)*S);y++)for(let x=Math.floor((cx-r)*S);x<=Math.ceil((cx+r)*S);x++){let dx=(x+.5)/S-cx,dy=(y+.5)/S-cy;if(dx*dx+dy*dy<=r*r)dot(x,y,c,a)}}
 function line(x,y,u,v,w,c,a=1){let dx=u-x,dy=v-y,d=dx*dx+dy*dy||1;for(let j=Math.floor((Math.min(y,v)-w)*S);j<=Math.ceil((Math.max(y,v)+w)*S);j++)for(let i=Math.floor((Math.min(x,u)-w)*S);i<=Math.ceil((Math.max(x,u)+w)*S);i++){let xx=(i+.5)/S,yy=(j+.5)/S,t=Math.max(0,Math.min(1,((xx-x)*dx+(yy-y)*dy)/d));let ex=xx-x-t*dx,ey=yy-y-t*dy;if(ex*ex+ey*ey<=(w*w)/4)dot(i,j,c,a)}}
 function stroke(pts,w,c,a=1,closed=false){for(let j=1;j<pts.length;j++)line(...pts[j-1],...pts[j],w,c,a);if(closed)line(...pts[pts.length-1],...pts[0],w,c,a)}
 function polygon(pts,c,a=1){let xs=pts.map(p=>p[0]),ys=pts.map(p=>p[1]);for(let y=Math.floor(Math.min(...ys)*S);y<=Math.ceil(Math.max(...ys)*S);y++)for(let x=Math.floor(Math.min(...xs)*S);x<=Math.ceil(Math.max(...xs)*S);x++){let xx=(x+.5)/S,yy=(y+.5)/S,inside=false;for(let i=0,j=pts.length-1;i<pts.length;j=i++){let p=pts[i],q=pts[j];if((p[1]>yy)!==(q[1]>yy))if(xx<(q[0]-p[0])*(yy-p[1])/(q[1]-p[1])+p[0])inside=!inside}if(inside)dot(x,y,c,a)}}
 function arc(r,start,end,w,c,a=1){let steps=Math.ceil(Math.abs(end-start)*r/2)+2,last=null;for(let i=0;i<=steps;i++){let theta=start+(end-start)*i/steps,p=[32+Math.cos(theta)*r,32+Math.sin(theta)*r];if(last)line(...last,...p,w,c,a);last=p}}
 function oct(r){return Array.from({length:8},(_,i)=>[32+Math.cos(Math.PI/8+i*Math.PI/4)*r,32+Math.sin(Math.PI/8+i*Math.PI/4)*r])}
 // Bolted octagonal, worn Factorio-inspired steel navigation instrument.
 polygon(oct(30.6),rgb("#16191b"));polygon(oct(28.8),rgb("#778083"));
 polygon(oct(27.1),rgb("#394248"));polygon(oct(24.9),rgb("#1c252c"));
 circle(32,32,19.4,rgb("#0b1319"));
 arc(22.5,.12,2.92,1.2,rgb("#c2c3be"),.36);
 arc(22.5,3.26,6.08,1.2,rgb("#06090e"),.65);
 for(let i=0;i<8;i++){let t=Math.PI/8+i*Math.PI/4,x=32+Math.cos(t)*26,y=32+Math.sin(t)*26;circle(x,y,2.35,rgb("#1b2429"));circle(x-.4,y-.4,1.2,rgb("#9da39d"));circle(x+.3,y+.3,.58,rgb("#15191c"))}
 for(let i=-3;i<=3;i++){line(17,32+i*4,47,32+i*4,.4,rgb("#73889c"),.11);line(32+i*4,18,32+i*4,46,.4,rgb("#73889c"),.08)}
 if(kind==="gate"){
    arc(16.1,.15,2.86,2.8,C,.79);arc(16.1,3.3,5.97,2.8,C,.75);
    arc(13.3,.2,2.8,1.1,A,.62);arc(13.3,3.3,5.9,1.1,A,.6);
    let angle=2*Math.PI*num/7;for(let i=0;i<3;i++){let t=angle+i*2*Math.PI/3;let x=32+Math.cos(t)*25,y=32+Math.sin(t)*25;circle(x,y,2.15,rgb("#262a29"));circle(x,y,1.45,A,.9)}
    if(num===0){stroke([[23,25],[32,32],[23,39]],3.4,C);stroke([[32,25],[41,32],[32,39]],3.4,A)}
    if(num===1){for(let k=-1;k<=1;k++)polygon([[32+k*9,22],[36+k*9,32],[32+k*9,42],[28+k*9,32]],k===0?A:C)}
    if(num===2){polygon([[20,32],[28,22],[36,27],[32,32]],C);polygon([[44,32],[36,42],[28,37],[32,32]],A);line(25,39,39,25,2,rgb("#dbebc6"))}
    if(num===3){polygon([[34,20],[24,34],[33,33],[29,44],[43,28],[34,29]],A);line(23,40,20,43,1.5,C)}
    if(num===4){polygon([[32,20],[40,32],[32,44],[24,32]],A);polygon([[32,21],[32,42],[24,32]],rgb("#7893a7"));line(23,32,41,32,1.1,rgb("#ffffff"),.68)}
    if(num===5){polygon([[32,20],[42,26],[42,38],[32,44],[22,38],[22,26]],C);polygon([[32,20],[37,30],[32,42],[27,30]],A,.8);stroke([[23,28],[32,33],[41,28]],1.2,rgb("#ffe5b6"))}
    if(num===6){circle(32,32,10,C);circle(36,28,10,rgb("#0b1319"));stroke([[23,42],[28,37]],3,A);stroke([[38,25],[42,20]],3,A)}
    circle(32,32,2.1,A);circle(31.5,31.5,.8,rgb("#fff9e5"));
 }else{
    const umbra=id.startsWith("umbra"),inner=id.endsWith("inner");
    const verts=[[-18,-17,6],[-17,16,5],[16,-17,6],[18,17,5]];
    for(let i=0;i<verts.length;i++){let [dx,dy,r]=verts[i],x=32+dx,y=32+dy;
      let pts=[[x-r,y-r*.25],[x-r*.2,y-r],[x+r*.6,y-r*.7],[x+r,y+r*.25],[x,y+r],[x-r*.85,y+r*.4]];
      polygon(pts,rgb(umbra?(i%2?"#665452":"#574d48"):(i%2?"#606e77":"#566269")));
      stroke(pts.slice(0,3),1.3,rgb(umbra?"#be9172":"#a8b9c5"),.63);
    }
    let arrow=inner?[[42,24],[30,24],[30,19],[19,32],[30,45],[30,40],[42,40]]:
      [[22,24],[34,24],[34,19],[45,32],[34,45],[34,40],[22,40]];
    polygon(arrow,C);stroke(inner?[[37,27],[27,27],[23,32],[27,37],[37,37]]:[[27,27],[37,27],[41,32],[37,37],[27,37]],1.5,A);
    if(inner){line(18,18,25,18,2.3,A);line(39,46,46,46,2.3,A)}
    else{arc(18.4,-.5,.5,2.2,A,.85);arc(18.4,2.65,3.65,2.2,A,.85)}
 }
 let seed=0;for(let j=0;j<id.length;j++)seed=(Math.imul(seed,31)+id.charCodeAt(j))>>>0;
 for(let i=0;i<20;i++){seed=(Math.imul(seed,1664525)+1013904223)>>>0;let t=(seed%628)/100,r=23+((seed>>>12)%6),x=32+Math.cos(t)*r,y=32+Math.sin(t)*r;line(x,y,x+1.4,y-.4,.35,rgb("#d7c6a8"),.18)}
 const result=new Uint8Array(64*64*4);
 for(let y=0;y<64;y++)for(let x=0;x<64;x++){let index=(y*64+x)*4,alpha=0,sum=[0,0,0];for(let oy=0;oy<2;oy++)for(let ox=0;ox<2;ox++){let p=((y*2+oy)*N+x*2+ox)*4,a=pixels[p+3]/255;alpha+=a;for(let i=0;i<3;i++)sum[i]+=pixels[p+i]*a}result[index+3]=Math.round(alpha/4*255);for(let i=0;i<3;i++)result[index+i]=alpha?Math.round(sum[i]/alpha):0}
 return result;
}

function encodePNG(pixels){
 const be32=n=>[(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255],chunks=[137,80,78,71,13,10,26,10];
 function crc(v){let c=0xffffffff;for(let b of v){c^=b;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(c^0xffffffff)>>>0}
 function chunk(t,p){let d=[...t].map(c=>c.charCodeAt(0)).concat(p);chunks.push(...be32(p.length),...d,...be32(crc(d)))}
 const raw=[];for(let y=0;y<64;y++){raw.push(0);for(let x=0;x<256;x++)raw.push(pixels[y*256+x])}
 const z=[0x78,0x01];for(let i=0;i<raw.length;){let n=Math.min(65535,raw.length-i),last=i+n===raw.length;z.push(last?1:0,n&255,n>>>8,(~n)&255,((~n)>>>8)&255);for(let j=i;j<i+n;j++)z.push(raw[j]);i+=n}
 let a=1,b=0;for(let value of raw){a=(a+value)%65521;b=(b+a)%65521}z.push(...be32((b*65536+a)>>>0));
 chunk("IHDR",[...be32(64),...be32(64),8,6,0,0,0]);chunk("IDAT",z);chunk("IEND",[]);
 return Uint8Array.from(chunks);
}

const directory=path.join(__dirname,'..','graphics','icons','navigation');

fs.mkdirSync(directory,{recursive:true});

for(const [name,spec] of Object.entries(specs)) fs.writeFileSync(path.join(directory,name+'.png'),Buffer.from(encodePNG(paint(name,spec))));

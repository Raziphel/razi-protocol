-- New Razi atlas fixture. No Factorio process required.
package.path="./?.lua;./?/init.lua;"..package.path
local function ok(v,msg) if not v then error(msg,2) end end
package.loaded["prototypes.system.galaxy_layout"]={
  anchor_position=function(name)
    local points={
      solaris={52,90},nyxaris={-52,90},vibrant={104,0},
      vespera={-104,0},beetlejuice={52,-90},umbra={-52,-90},
      ["solar-system-edge"]={0,-190},
    }
    local p=points[name];if p then return p[1],p[2] end
  end
}
local bg=require("prototypes.system.starmap_background")
local native={filename="__native__/starmap-star.png",size=512}
local sprites={layers={native}}
rawset(_G,"data",{raw={["utility-sprites"]={default={starmap_star=sprites}}}})
rawset(_G,"settings",{startup={
  ["razi-starmap-background-style"]={value="subtle"},
  ["razi-starmap-system-halos"]={value=true},
  ["razi-starmap-belt-atmosphere"]={value=true},
  ["razi-starmap-fine-details"]={value=true},
  ["razi-starmap-galactic-ornaments"]={value=true},
  ["razi-starmap-micro-details"]={value=true},
  ["razi-starmap-cartography"]={value=false}
}})
rawset(_G,"mods",{})
local parts=bg.make_layers("subtle",true,true,true,false)
ok(parts[1].tint.a>.65 and parts[1].tint.a<.8,
  "Pinpoint sky should use visible tiny dots instead of faded giant blobs")
ok(#parts==54,"Subtle atlas uses 36 sky tiles, 8 halos, 2 unique belts, 8 dust pockets")
local counts={sky=0,halo=0,belt=0,dust=0}
for _,layer in ipairs(parts) do
  local side=layer.filename:find("atlas%-starfield%-") and 1024 or 512
  ok(layer.size[1]==side and layer.size[2]==side,"Unexpected texture size")
  ok(layer.filename:find("graphics/starmap/razi/",1,true),"Foreign sprite")
  ok(layer.tint.a<=.94,"Atlas alpha too bright")
  if layer.filename:find("atlas%-starfield%-") then counts.sky=counts.sky+1 end
  if layer.filename:find("atlas%-halo") or
    layer.filename:find("glow%-") then counts.halo=counts.halo+1 end
  if layer.filename:find("belt%-vespera") or layer.filename:find("debris%-vespera")
    or layer.filename:find("debris%-umbra") or layer.filename:find("belt%-umbra") then counts.belt=counts.belt+1 end
  if layer.filename:find("atlas%-dust") then counts.dust=counts.dust+1 end
end
ok(counts.sky==36 and counts.halo==8 and counts.belt==2 and counts.dust==8,
  "Expected restrained per-system artwork")
local unique={}
for _,layer in ipairs(parts) do
  local name=layer.filename:match("glow%-(%a+)%.png$")
  if name then unique[name]=layer end
end
ok(unique.nyxaris and unique.vibrant and unique.vespera,
  "Use dedicated system glows instead of identical atlas halos")
ok(unique.nyxaris.tint.b>unique.nyxaris.tint.g and
  unique.nyxaris.tint.g>unique.nyxaris.tint.r,
  "Nyxaris blue must carry into its halo")
ok(unique.vibrant.tint.r>unique.vibrant.tint.g,
  "Vibrant should be purple, not another cyan star")
local nyxaris_star={filename="__razi-protocol__/graphics/icons/NyxarisStar.png"}
bg.tint_star_art({nyxaris_star})
local first_tint=nyxaris_star.tint.g
bg.tint_star_art({nyxaris_star})
ok(nyxaris_star.tint.g==first_tint and nyxaris_star.tint.b==1,
  "Stellar art tint should not accumulate after repeated final fixes")
-- The dedicated Vibrant ring belongs to asteroid_belt_integration,
-- not this generic atlas. Only Vespera and Umbra receive the two new
-- distinct artwork layers, with no dependence on optional planets.
local belt_names={}
for _,layer in ipairs(parts) do
  if layer.filename:find("belt%-vespera") or layer.filename:find("belt%-umbra") or
    layer.filename:find("debris%-vespera") or
    layer.filename:find("debris%-umbra") then
    belt_names[#belt_names+1]=layer.filename
    ok(layer.tint.a<=.25,"Belt haze should not overpower the native star map")
  end
end
ok(#belt_names==2,"Subtle should use exactly one regional image per outer belt")
local extra=bg.make_layers("cinematic",true,true,true,false)
local cin_fragments=0
for _,layer in ipairs(extra) do
  if layer.filename:find("debris%-vespera") or
    layer.filename:find("debris%-umbra") then
    cin_fragments=cin_fragments+1
  end
end
ok(cin_fragments==2,"Cinematic should add only two faint fragments")
local original=bg.make_layers("subtle",true,true,true,false)
local repeats={}
for i,layer in ipairs(original) do
  if layer.filename:find("atlas%-starfield%-") then
    repeats[#repeats+1]=layer.tint.a
  end
end
ok(repeats[1]~=repeats[2] and repeats[1]~=repeats[7],
  "Repeated sky tiles need restrained per-cell exposure variation")
bg.data_final_fixes()
ok(#sprites.layers==55,"Clean atlas was not attached")
ok(sprites.layers[1].filename:find("atlas%-starfield%-"),"Atlas not behind native art")
ok(sprites.layers[#sprites.layers]==native,"Source star art changed")
bg.data_final_fixes()
ok(#sprites.layers==55,"Duplicate background layer registration")
ok(#bg.make_layers("off",true,true,true,false)==0,"Off mode still draws")
ok(#bg.make_layers("subtle",false,false,false,false)==36,
  "Turning off optional layers must leave native map alone")
ok(#bg.make_layers("subtle",true,true,false,false)==46,
  "Disabling detail pockets should leave 8 halos and 2 belt layers")
ok(#bg.make_layers("subtle",true,true,true,true)==55,
  "Cartography adds only a single distant dust pocket")
local cine=bg.make_layers("cinematic",true,true,true,false)
ok(#cine==#parts+2 and cine[1].tint.a>parts[1].tint.a,
  "Cinematic should be brighter without extra clutter")
settings.startup["razi-starmap-galactic-ornaments"].value=false
ok(#bg.make_layers("subtle",true,true,true,false)==50,
  "Turning off ornaments removes four star pockets")
settings.startup["razi-starmap-galactic-ornaments"].value=true
settings.startup["razi-starmap-micro-details"].value=false
ok(#bg.make_layers("subtle",true,true,true,false)==52,
  "Turning off micro-details removes four star pockets")
sprites.layers={native}
settings.startup["razi-starmap-background-style"].value="off"
bg.data_final_fixes()
ok(#sprites.layers==1,"Off mode affected source art")
settings.startup["razi-starmap-background-style"].value="subtle"
mods["Better_Starmap_Background"]=true
bg.data_final_fixes()
ok(#sprites.layers==1,"External artwork conflict")
print("Seam-free Razi star atlas fixtures passed")

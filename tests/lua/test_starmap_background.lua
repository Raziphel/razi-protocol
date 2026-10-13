-- New Razi atlas fixture. No Factorio process required.
package.path="./?.lua;./?/init.lua;"..package.path
local function ok(v,msg) if not v then error(msg,2) end end
package.loaded["prototypes.system.galaxy_layout"]={
  anchor_position=function(name)
    local points={
      solaris={52,90},nyxaris={-52,90},vibrant={104,0},
      vespera={-104,0},beetlejuice={52,-90},umbra={-52,-90},
      ["solar-system-edge"]={0,-190},
      ["razi-calidus-drift"]={-19.799,19.799}
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
ok(#parts==40,"Clean atlas should use 9 halos, 3 belts, 12 dust pockets")
local counts={sky=0,halo=0,belt=0,dust=0}
for _,layer in ipairs(parts) do
  local side=layer.filename:find("atlas%-starfield%-") and 512 or 128
  ok(layer.size[1]==side and layer.size[2]==side,"Unexpected texture size")
  ok(layer.filename:find("graphics/starmap/razi/",1,true),"Foreign sprite")
  ok(layer.tint.a<=.87,"Atlas alpha too bright")
  if layer.filename:find("atlas%-starfield%-") then counts.sky=counts.sky+1 end
  if layer.filename:find("atlas%-halo") then counts.halo=counts.halo+1 end
  if layer.filename:find("atlas%-belt") then counts.belt=counts.belt+1 end
  if layer.filename:find("atlas%-dust") then counts.dust=counts.dust+1 end
end
ok(counts.sky==16 and counts.halo==9 and counts.belt==3 and counts.dust==12,
  "Expected restrained per-system artwork")
bg.data_final_fixes()
ok(#sprites.layers==41,"Clean atlas was not attached")
ok(sprites.layers[1].filename:find("atlas%-starfield%-"),"Atlas not behind native art")
ok(sprites.layers[#sprites.layers]==native,"Source star art changed")
bg.data_final_fixes()
ok(#sprites.layers==25,"Duplicate background layer registration")
ok(#bg.make_layers("off",true,true,true,false)==0,"Off mode still draws")
ok(#bg.make_layers("subtle",false,false,false,false)==16,
  "Turning off optional layers must leave native map alone")
ok(#bg.make_layers("subtle",true,true,false,false)==28,
  "Disabling detail pockets should leave 9 halos and 3 belts")
ok(#bg.make_layers("subtle",true,true,true,true)==41,
  "Cartography adds only a single distant dust pocket")
local cine=bg.make_layers("cinematic",true,true,true,false)
ok(#cine==#parts and cine[1].tint.a>parts[1].tint.a,
  "Cinematic should be brighter without extra clutter")
settings.startup["razi-starmap-galactic-ornaments"].value=false
ok(#bg.make_layers("subtle",true,true,true,false)==32,
  "Turning off ornaments removes eight star pockets")
settings.startup["razi-starmap-galactic-ornaments"].value=true
settings.startup["razi-starmap-micro-details"].value=false
ok(#bg.make_layers("subtle",true,true,true,false)==36,
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

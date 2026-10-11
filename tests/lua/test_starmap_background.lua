-- Pure Razi star-map backdrop fixture, without a Factorio process.
package.path="./?.lua;./?/init.lua;"..package.path
local function ok(v,msg) if not v then error(msg,2) end end
package.loaded["prototypes.system.galaxy_layout"]={
  anchor_position=function(name)
    local points={
      solaris={52,90},nyxaris={-52,90},vibrant={104,0},
      vespera={-104,0},beetlejuice={52,-90},umbra={-52,-90},
      ["solar-system-edge"]={0,-190}
    }
    local p=points[name];if p then return p[1],p[2] end
  end
}
local bg=require("prototypes.system.starmap_background")
local original={filename="__native__/starmap-star.png",size=512}
local sprites={layers={original}}
rawset(_G,"data",{raw={["utility-sprites"]={default={starmap_star=sprites}}}})
rawset(_G,"settings",{startup={
  ["razi-starmap-background-style"]={value="subtle"},
  ["razi-starmap-system-halos"]={value=true},
  ["razi-starmap-belt-atmosphere"]={value=true},
  ["razi-starmap-fine-details"]={value=true},
  ["razi-starmap-cartography"]={value=false}
}})
rawset(_G,"mods",{})
local parts=bg.make_layers("subtle",true,true)
ok(#parts==38,"Fine details should include six reused hub coronas")
for _,layer in ipairs(parts) do
  ok(layer.size[1]<=1024 and layer.size[2]<=1024,"oversized atlas sprite")
  ok(layer.filename:find("graphics/starmap/razi",1,true),"foreign texture")
end
local coronas=0
for _,layer in ipairs(parts) do
  if layer.filename:find("filament%-") and layer.scale==6.15 then
    coronas=coronas+1
  end
end
ok(coronas==6,"Six outer-star coronas must use the already loaded art")
bg.data_final_fixes()
ok(#sprites.layers==39,"Fine-detail artwork layers absent")
ok(sprites.layers[1].filename:find("sky%-1"),"Background not underneath")
ok(sprites.layers[39]==original,"Source sprite replaced")
bg.data_final_fixes()
ok(#sprites.layers==39,"Idempotence failed")
ok(#bg.make_layers("off",true,true)==0,"Off mode still draws")
ok(#bg.make_layers("subtle",false,false,false,false)==5,
  "Optional layers did not disable")
ok(#bg.make_layers("subtle",true,true,false,false)==16,
  "Disabling fine details should restore original 16 layers")
ok(#bg.make_layers("subtle",true,true,true,true)==39,
  "Opt-in cartography must add only one chart")
ok(#bg.make_layers("cinematic",true,true,true,false)==40,
  "Cinematic should add eight faint expanded filaments")
local cine=bg.make_layers("cinematic",true,true)
ok(cine[1].tint.a>parts[1].tint.a,"Cinematic brightness not increased")
sprites.layers={original}
settings.startup["razi-starmap-background-style"].value="off"
bg.data_final_fixes()
ok(#sprites.layers==1,"Off mode edited source")
settings.startup["razi-starmap-background-style"].value="subtle"
mods["Better_Starmap_Background"]=true
bg.data_final_fixes()
ok(#sprites.layers==1,"External background conflict")
print("Razi starmap background fixtures passed")

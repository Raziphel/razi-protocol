-- RP3 add-on enemies must be planet-scoped, additive and mod-guarded.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(test,msg) if not test then error(msg,2) end end
table.deepcopy=table.deepcopy or function(x)
 if type(x)~="table" then return x end
 local y={}
 for k,v in pairs(x) do y[k]=table.deepcopy(v) end
 return y
end
local function world(tiles)
 local t={}
 for _,name in ipairs(tiles) do t[name]={} end
 return {map_gen_settings={
   autoplace_controls={["enemy-base"]={frequency=1}},
   autoplace_settings={tile={settings=t},
     entity={settings={["biter-spawner"]={frequency=1},
       ["small-worm-turret"]={frequency=1}}}
   }
 }}
end
rawset(_G,"settings",{startup={
 ["razi-difficulty-preset"]={value="normal"},
 ["razi-enable-enemy-routing"]={value=true}
}})
rawset(_G,"mods",{ArmouredBiters21Compat="2.1",Toxic_biters="2.1",
  Electric_flying_enemies="2.1",Explosive_biters="2.1",
  Arachnids_enemy="2.1"})
local originals={
 armor={type="unit-spawner",name="armoured-biter-spawner",
  autoplace={control="enemy-base",
    probability_expression="native_armor_noise",
    tile_restriction={"hyarion-cracks"}}},
 toxin={type="unit-spawner",name="toxic-biter-spawner",
  autoplace={control="enemy-base",
    probability_expression="native_toxin_noise",
    tile_restriction={"cubium-soil"}}},
 electric={type="unit-spawner",name="flying-electric-unit-spawner",
  autoplace={control="enemy-base",
    probability_expression="native_electric_noise",
    tile_restriction={"fulgoran-dust"}}},
 explosive={type="unit-spawner",name="explosive-biter-spawner",
  autoplace={control="enemy-base",
    probability_expression="native_explosive_noise"}},
 arachnid={type="unit-spawner",name="arachnid-spawner-unitspawner",
  autoplace={control="enemy-base",
    probability_expression="native_arachnid_noise"}}
}
rawset(_G,"data",{raw={
 planet={
   ferrum=world({"ferrum-scrap","ferrum-rock","oil-ocean-deep"}),
   obsidiax=world({"obsidiax-ash","obsidiax-rock","lava-hot"}),
   panglia=world({"panglia-grass","panglia-sand","water"}),
   alchemy_ignored=world({"mud"}),
   ["alchemy-planet"]=world({"alchemy-soil","acid-lake"}),
   gleba=world({"gleba-mud","gleba-grass","water"}),
   nexus=world({"nexus-sand","nexus-rock","oil-ocean-shallow"})
 },
 tile={
   ["ferrum-scrap"]={},["ferrum-rock"]={},
   ["oil-ocean-deep"]={},["oil-ocean-shallow"]={},
   ["obsidiax-ash"]={},["obsidiax-rock"]={},["lava-hot"]={},
   ["panglia-grass"]={},["panglia-sand"]={},water={},
   ["alchemy-soil"]={},["acid-lake"]={},
   ["gleba-mud"]={},["gleba-grass"]={},
   ["nexus-sand"]={},["nexus-rock"]={},mud={}
 },
 ["autoplace-control"]={["enemy-base"]={}},
 ["unit-spawner"]={
   ["armoured-biter-spawner"]=originals.armor,
   ["toxic-biter-spawner"]=originals.toxin,
   ["flying-electric-unit-spawner"]=originals.electric,
   ["explosive-biter-spawner"]=originals.explosive,
   ["arachnid-spawner-unitspawner"]=originals.arachnid
 },
 turret={}
},extend=function(_,items)
 for _,item in ipairs(items) do
  check(item.type and item.name,"Every clone needs type and ID")
  data.raw[item.type]=data.raw[item.type] or {}
  check(not data.raw[item.type][item.name],"Duplicate clone: "..item.name)
  data.raw[item.type][item.name]=item
 end
end})
package.loaded["prototypes.compat.enemy_autoplace"]=nil
package.loaded["prototypes.compat.razi_enemy_ecology"]=nil
local eco=require("prototypes.compat.razi_enemy_ecology")
local placed=eco.data_final_fixes()
check(placed>=7,"Expected multiple themed families on newly integrated planets")
local ferrum=data.raw.planet.ferrum.map_gen_settings
local e=ferrum.autoplace_settings.entity.settings
check(e["razi-ferrum-armoured-biter-spawner"]~=nil,
 "Ferrum must get armored biters")
check(e["razi-ferrum-flying-electric-unit-spawner"]~=nil,
 "Ferrum's conductive scrap needs electric enemies")
check(e["armoured-biter-spawner"]==nil,
 "Source and cloned armored nests must not double spawn")
check(e["biter-spawner"] and e["biter-spawner"].frequency==1,
 "Specialists must never suppress native biter nests")
local obs=data.raw.planet.obsidiax.map_gen_settings
check(obs.autoplace_settings.entity.settings[
 "razi-obsidiax-explosive-biter-spawner"]~=nil,
 "Obsidiax must receive volcanic explosive biters")
check(data.raw.planet.panglia.map_gen_settings.autoplace_settings
 .entity.settings["razi-panglia-arachnid-spawner-unitspawner"],
 "Panglia should support arachnid nests")
check(data.raw.planet.gleba.map_gen_settings.autoplace_settings
 .entity.settings["razi-gleba-toxic-biter-spawner"],
 "Toxic biters must coexist with Gleba native ecology")
check(data.raw.planet["alchemy-planet"].map_gen_settings
 .autoplace_settings.entity.settings[
 "razi-alchemy-planet-toxic-biter-spawner"],
 "Khemia's actual prototype must be used")
local clone=data.raw["unit-spawner"]["razi-ferrum-armoured-biter-spawner"]
check(clone.autoplace.control=="enemy-base",
 "Cloned nest needs registered mapgen control")
check(clone.autoplace.tile_restriction[1]=="ferrum-rock",
 "Scoped nests must use actual planet terrain")
check(not data.raw["unit-spawner"]["razi-ferrum-flying-electric-unit-spawner"]
 .autoplace.tile_restriction[1]:find("ocean"),
 "Electric fauna may not spawn on the oil ocean")
check(originals.armor.autoplace.probability_expression=="native_armor_noise"
 and originals.armor.autoplace.tile_restriction[1]=="hyarion-cracks",
 "New planets must not modify the source nest's global terrain rules")
local first=placed
eco.data_final_fixes()
check(data.raw["unit-spawner"]["razi-ferrum-armoured-biter-spawner"],
 "Repeat final pass must reuse the same clone")
settings.startup["razi-enable-enemy-routing"].value=false
check(eco.data_final_fixes()==false,
 "Turning off enemy routing must disable the final ecology pass")
print("RP3 themed habitats, Nexus safety, mod guards and clone identity passed")

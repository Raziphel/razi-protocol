-- The orbital catapult recipe is opened by Razi's technology, only when the mod is there.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local catapult=require("prototypes.compat.orbital_catapult")

local function raw()
  local cards={{"calidus-tech-card",1},{"solaris-tech-card",1},{"nyxaris-tech-card",1}}
  return {
    recipe={["orbital-cannon"]={name="orbital-cannon",enabled=false}},
    technology={
      ["planet-discovery-rubia"]={name="planet-discovery-rubia",
        unit={count=950,time=60,ingredients=cards}},
      ["electromagnetic-plant"]={name="electromagnetic-plant",
        research_trigger={type="craft-item",item="holmium-plate",count=50}},
      ["efficiency-module-2"]={name="efficiency-module-2",
        unit={count=200,time=30,ingredients={{"space-science-pack",1}}}}
    }
  }
end

local technology=assert(catapult.technology(raw(),true))
check(technology and technology.name=="razi-orbital-catapult","The catapult technology must be created")
check(#technology.effects==1 and technology.effects[1].type=="unlock-recipe"
  and technology.effects[1].recipe=="orbital-cannon","It must unlock the catapult recipe only")
local prerequisites={}
for _,name in ipairs(technology.prerequisites) do prerequisites[name]=true end
check(prerequisites["planet-discovery-rubia"] and prerequisites["electromagnetic-plant"]
  and prerequisites["efficiency-module-2"] and #technology.prerequisites==3,
  "Rubia, superconductors and efficiency modules must come first")
check(technology.unit.count==500 and technology.unit.time==60,"500 units of 60 s")
check(#technology.unit.ingredients==3 and technology.unit.ingredients[1][1]=="calidus-tech-card",
  "Its science must follow the Rubia discovery")
local source=raw()
local copy=assert(catapult.technology(source,true))
copy.unit.ingredients[1][2]=99
check(source.technology["planet-discovery-rubia"].unit.ingredients[1][2]==1,
  "The Rubia discovery's ingredients must not be shared")

check(catapult.technology(raw(),nil)==nil,"Nothing without Orbital Catapult")
local missing=raw()
missing.recipe["orbital-cannon"]=nil
check(catapult.technology(missing,true)==nil,"Nothing without the catapult recipe")
missing=raw()
missing.technology["electromagnetic-plant"]=nil
check(catapult.technology(missing,true)==nil,"Nothing with a missing prerequisite")
local opened=raw()
opened.technology["other-planet"]={name="other-planet",
  effects={{type="unlock-recipe",recipe="orbital-cannon"}}}
check(catapult.technology(opened,true)==nil,"Leave it to another mod that already unlocks it")

local added={}
data={raw=raw(),extend=function(_,rows) for _,row in ipairs(rows) do added[#added+1]=row end end}
mods={["orbital-cannon"]="0.15.0"}
catapult.data_final_fixes()
check(#added==1 and added[1].name=="razi-orbital-catapult","data-final-fixes must add the technology")
data.raw.technology["razi-orbital-catapult"]=added[1]
catapult.data_final_fixes()
check(#added==1,"A second pass must not add it twice")
print("Orbital Catapult unlock technology passed")

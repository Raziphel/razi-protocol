-- Golden Science must follow Steam Recycler, never form a research cycle.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,why) if not ok then error(why,2) end end

local function fixture(reverse)
  rawset(_G,"data",{raw={technology={
    ["planet-discovery-secretas"]={prerequisites={}},
    ["steam-recycler"]={
      prerequisites={"planet-discovery-secretas",reverse or "golden-science-pack"},
      research_trigger={type="mine-entity",entities={"spaceship-scrap"}},
      effects={{type="unlock-recipe",recipe="steam-recycler"},
        {type="unlock-recipe",recipe="gold-plate"}},
    },
    ["golden-science-pack"]={
      prerequisites={"planet-discovery-secretas","steam-recycler"},
      research_trigger={type="craft-item",item="gold-plate",count=20},
      effects={{type="unlock-recipe",recipe="golden-science-pack"}},
    },
    ["unrelated"]={prerequisites={"planet-discovery-secretas"}}
  }}})
end
package.loaded["prototypes.compat.prototype_sanity"]=nil
local module=require("prototypes.compat.prototype_sanity")
local athos=require("prototypes.compat.athos_cycle_guard")

fixture()
check(athos.find_cycle(data.raw.technology)~=nil,"Original Steam/Golden cycle missing")
check(module.restore_secretas_science_bootstrap(),
  "Must prune directly reversed Secretas science edge")
check(athos.find_cycle(data.raw.technology)==nil,"Direct golden/recycler loop must be gone")
check(#data.raw.technology["steam-recycler"].prerequisites==1
  and data.raw.technology["steam-recycler"].prerequisites[1]=="planet-discovery-secretas",
  "Original planet discovery prerequisite must remain")
check(data.raw.technology["golden-science-pack"].prerequisites[2]=="steam-recycler",
  "Gold science must remain downstream of mining source scrap")
check(data.raw.technology["golden-science-pack"].research_trigger.count==20
  and data.raw.technology["golden-science-pack"].research_trigger.item=="gold-plate",
  "Craft 20 gold plate trigger must remain source-owned")
check(not module.restore_secretas_science_bootstrap()
  and athos.find_cycle(data.raw.technology)==nil,
  "Second fix pass must be idempotent")

-- A longer reverse path must not produce a cycle if another mod rewrites
-- the direct prerequisite into an intermediate research.
fixture("gold-precursor")
data.raw.technology["gold-precursor"]={prerequisites={"golden-science-pack"}}
check(athos.find_cycle(data.raw.technology)~=nil,
  "Extended precondition must initially be cyclic")
check(not module.restore_secretas_science_bootstrap(),
  "Unexpected indirect reverse path is handled without arbitrary cuts")
check(athos.find_cycle(data.raw.technology)==nil,
  "Must omit Razi's late steam gate if it creates a longer cycle")
check(#data.raw.technology["golden-science-pack"].prerequisites==1,
  "Do not append cyclic source gates")
check(data.raw.technology["steam-recycler"].prerequisites[1]=="gold-precursor",
  "Do not alter the unrelated indirect prerequisite")

-- If the source research triggers are changed, do not rewrite arbitrary
-- similarly named technology prototypes.
fixture()
data.raw.technology["steam-recycler"].research_trigger={type="craft-item",item="unrelated"}
check(not module.restore_secretas_science_bootstrap(),
  "Unknown source revision should skip speculative changes")
check(athos.find_cycle(data.raw.technology)~=nil,
  "Unknown source revision must remain unmodified for diagnosis")
print("Secretas golden science/bootstrap regressions passed")

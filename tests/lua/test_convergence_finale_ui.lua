---@diagnostic disable: unnecessary-assert, param-type-mismatch, need-check-nil, inject-field, missing-fields, assign-type-mismatch, redundant-parameter
-- The Convergence page at the last shipment: every gate is met except the
-- Dyson receiver, so the hint names the receiver. The page never mentions an
-- Array Core or final subassemblies, which the finale does not use.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local story=require("scripts.razi_story")
local W=require("tests.lua.journal_window")
local defs=require("prototypes.technology.convergence")
local convergence=require("scripts.razi_convergence")
local ctx=W.setup()
local force,player=ctx.force,ctx.player
story.configure(false)

local function tech() return {researched=true,enabled=true,prerequisites={},
  localised_name={"technology-name.x"},prototype={hidden=false,effects={}}} end
force.technologies[defs.commission]=tech()
force.technologies[defs.authorization]=tech()
force.technologies[defs.ignition]=tech()
force.technologies["razi-convergence-witness-network"]=tech()

-- Four shipments delivered; the fifth is current.
local delivered={}
for index=1,4 do delivered[convergence.stages[index].id]=convergence.stages[index].count end
storage.razi_convergence={[1]={delivered=delivered,victory=false}}
-- All nine Nexus bosses are defeated.
local defeated={}
for _,id in ipairs(require("scripts.razi_nexus_trials").order) do defeated[id]=true end
rawset(_G,"remote",{interfaces={["nexus-bosses"]={get_state=true}},
  call=function() return {defeated={[force.name]=defeated}} end})
-- A powered radar in each of the seven star systems.
local radar_surface=function(world)
  return {valid=true,planet={name=world},
    find_entities_filtered=function() return {{valid=true,energy=1}} end}
end
game.surfaces={}
for _,world in ipairs({"nauvis","vulcanus","gleba","fulgora","muria","cubium",
  "tenebris"}) do game.surfaces[#game.surfaces+1]=radar_surface(world) end
-- Every Deep Space destination visited.
prototypes.space_location={
  ["solar-system-edge"]={localised_name="Edge"},nexus={localised_name="Nexus"}}
prototypes.space_connection={edge_nexus={from="solar-system-edge",to="nexus"}}
storage.razi_deep_space_visits={[1]={["solar-system-edge"]={by="Tester"},
  nexus={by="Tester"}}}
-- A Dyson receiver prototype exists, but none is placed yet.
prototypes.item["ds-energy-loader-mk1"]={place_result={name="test-receiver"}}
prototypes.entity={["test-receiver"]={}}
local receivers=0
force.get_entity_count=function(name)
  if name=="radar" then return 7 end
  if name=="test-receiver" then return receivers end
  return 0
end
force.recipes={[convergence.stages[5].item]={enabled=true}}
player.character={valid=true,surface={platform={valid=true,force=force,
  space_location={name="solar-system-edge"}}}}

local function convergence_page()
  local p=ctx.journal.preferences(1)
  p.view="projects";p.project="convergence"
  ctx.journal.draw(player)
  return W.flat(ctx.shown())
end
local FORBIDDEN={"razi-ops.convergence-core-ready","razi-ops.convergence-core-missing",
  "razi-ops.convergence-next-action-core","razi-ops.convergence-component-heading",
  "journal-ui.project-next-convergence-core"}
local function check_clean(keys,label)
  for _,key in ipairs(FORBIDDEN) do
    check(not keys[key],label..": removed text is shown: "..key)
  end
end

local keys=convergence_page()
check(keys["razi-ops.convergence-next-action-receiver"],
  "Without a receiver the page must name the receiver")
check(keys["journal-ui.project-next-convergence-receiver"],
  "Without a receiver the project step must name the receiver")
check_clean(keys,"no receiver")

receivers=1
keys=convergence_page()
check(not keys["razi-ops.convergence-next-action-receiver"],
  "A placed receiver must clear the receiver hint")
check(keys["razi-ops.convergence-next-action-freight"],
  "With every gate met the page asks for the final cargo")
check(keys["journal-ui.project-next-convergence-deliver"],
  "With every gate met the project step is the final delivery")
check_clean(keys,"receiver placed")
print("Convergence finale page: receiver hint, no Array Core, no subassemblies")

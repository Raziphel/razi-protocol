-- Read-only diagnosis of the actual loaded Factorio 2.1 modpack.
-- Runs only on /razi-audit; no tick handlers, mutation or saved state.
local M={}
local defs=require("prototypes.technology.convergence")
local convergence=require("scripts.razi_convergence")
local research={defs.commission,defs.authorization,defs.ignition}
local function table_contains(items,name)
 for _,item in ipairs(items or {}) do
  if item==name then return true end
 end
 return false
end
local function laboratories(registry)
 local result={}
 if registry.get_entity_filtered then
  for id,entity in pairs(registry.get_entity_filtered{
    {filter="type",type="lab"}}) do
   result[#result+1]={name=id,inputs=entity.lab_inputs or {}}
  end
 else
  -- Plain Lua fixture support; the live game always has the filtered API.
  for id,entity in pairs(registry.entity or {}) do
   if entity.type=="lab" then
    result[#result+1]={name=id,inputs=entity.lab_inputs or {}}
   end
  end
 end
 table.sort(result,function(a,b) return a.name<b.name end)
 return result
end
local function lab_for(ingredients,labs)
 for _,lab in ipairs(labs) do
  local all=true
  for _,ingredient in ipairs(ingredients or {}) do
   if not table_contains(lab.inputs,ingredient.name or ingredient[1]) then
    all=false
    break
   end
  end
  if all then return lab.name end
 end
end
local function producers(registry)
 local index={}
 -- One index across loaded recipes, not one full recipe scan per material.
 for _,recipe in pairs(registry.recipe or {}) do
  if not recipe.hidden then
   for _,product in ipairs(recipe.products or {}) do
    if product.type~="fluid" and product.name then
     index[product.name]=(index[product.name] or 0)+1
    end
   end
  end
 end
 return index
end
local function cyclic_research(force)
 local visiting,done={},{}
 local function walk(tech)
  if not tech then return nil end
  local name=tech.name
  if visiting[name] then return name end
  if done[name] then return nil end
  visiting[name]=true
  for _,parent in pairs(tech.prerequisites or {}) do
   local cycle=walk(parent)
   if cycle then return cycle end
  end
  visiting[name]=nil
  done[name]=true
  return nil
 end
 for _,id in ipairs(research) do
  local cycle=walk(force.technologies and force.technologies[id])
  if cycle then return cycle end
 end
end
function M.inspect(force,registry)
 local result={errors={},notes={},labs=0,stages=0,
  missing_producers=0,unlocked=0}
 if not (force and force.technologies and force.recipes and registry) then
  result.errors[1]="No force or runtime prototype registry available"
  return result
 end
 local labs=laboratories(registry)
 local produced=producers(registry)
 result.labs=#labs
 local function error_line(line) result.errors[#result.errors+1]=line end
 local function note(line) result.notes[#result.notes+1]=line end
 if not convergence.available(force) then
  error_line("Convergence technology registration is incomplete")
 end
 for _,id in ipairs(research) do
  local technology=force.technologies[id]
  if not technology then
   error_line("Missing research: "..id)
  else
   local packs=technology.research_unit_ingredients or {}
   local lab=lab_for(packs,labs)
   if #packs==0 then
    note("Research has no science-pack unit: "..id)
   elseif not lab then
    error_line("No installed lab accepts all packs for "..id)
   else
    note(id..": compatible lab "..lab)
   end
   if technology.researched then result.unlocked=result.unlocked+1 end
  end
 end
 local cycle=cyclic_research(force)
 if cycle then error_line("Research prerequisite cycle: "..cycle) end
 for _,stage in ipairs(defs.shipments) do
  local recipe=force.recipes[stage.item]
  local unlock=force.technologies[stage.unlock or defs.commission]
  if not recipe then
   error_line("Missing Mandate recipe: "..stage.item)
  elseif unlock and unlock.researched and not recipe.enabled then
   error_line("Researched but recipe locked: "..stage.item)
  else
   result.stages=result.stages+1
  end
  -- Check the ACTUAL source producers, not just product item definitions.
  -- Scripts/mining may produce items without a recipe, so report those
  -- conservatively as advisory, never a proven hard progression lock.
  if recipe then
   for _,part in ipairs(recipe.ingredients or {}) do
    if part.type~="fluid" and not produced[part.name] then
     result.missing_producers=result.missing_producers+1
     note("No visible crafting recipe for "..part.name..
       " ("..stage.id.."); inspect native scripted/mined sources")
    end
   end
  end
 end
 local ready,receivers=convergence.dyson_readiness(force)
 if receivers==nil then
  note("Dyson receiver prototype unavailable; physical gate omitted")
 elseif not ready then
  note("Dyson receiver exists but this force has not deployed one")
 else
  note("Native Dyson receiver entities: "..receivers)
 end
 -- Intentionally do not call convergence.progress(): that method creates
 -- first-use save records. An audit must be genuinely read-only.
 local saved=storage and storage.razi_convergence
  and storage.razi_convergence[force.index]
 local won=saved and saved.victory==true or false
 local delivered=0
 for _,stage in ipairs(defs.shipments) do
  if won or (saved and saved.delivered
    and (saved.delivered[stage.id] or 0)>=stage.count) then
   delivered=delivered+1
  end
 end
 note("Physical Convergence stages: "..delivered.."/"..#defs.shipments..
   (won and " (victory saved)" or ""))
 note("Diagnostic does not prove optional planet access or entire craft chains")
 return result
end
function M.command(event)
 local player=event.player_index and game.get_player(event.player_index)
 if player and not player.admin then
  player.print("[Razi Audit] Available to server administrators only")
  return
 end
 local force=player and player.force or game.forces.player
 if not force then return end
 local report=M.inspect(force,prototypes)
 local output=player or game
 output.print("[Razi Audit] "..force.name..
  ": "..#report.errors.." blockers, "..report.stages.."/"..
   #defs.shipments.." Mandate recipes, "..report.labs.." native labs")
 for i=1,math.min(16,#report.errors) do
  output.print("[Razi Audit] BLOCKER: "..report.errors[i])
 end
 if #report.errors>16 then
  output.print("[Razi Audit] "..(#report.errors-16)..
    " additional blockers (review configuration)")
 end
 for i=1,math.min(12,#report.notes) do
  output.print("[Razi Audit] "..report.notes[i])
 end
 output.print("[Razi Audit] Read-only; no technologies, recipes or saves modified")
end
return M

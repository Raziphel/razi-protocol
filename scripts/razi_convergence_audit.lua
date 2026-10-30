-- Lightweight, read-only audit of existing native Convergence cargo.
local M={}
local defs=require("prototypes.technology.convergence")
function M.inspect(force,registry)
 local report={errors={},notes={},labs=0,stages=0,components=0,
  missing_producers=0,locked_sources=0,unlocked=0}
 if not (force and force.technologies and force.recipes and registry) then
  report.errors[1]={"razi-audit.no-registry"}
  return report
 end
 for _,id in ipairs({defs.commission,defs.authorization,defs.ignition,
   "razi-convergence-witness-network"}) do
  local technology=force.technologies[id]
  if not technology then
   report.errors[#report.errors+1]={"razi-audit.missing-research",id}
  elseif technology.researched then report.unlocked=report.unlocked+1 end
 end
 for _,shipment in ipairs(defs.shipments) do
  local item=(registry.item or {})[shipment.item]
   or (registry.tool or {})[shipment.item]
  if not item then
   report.errors[#report.errors+1]={"razi-audit.missing-cargo",shipment.item}
  else report.stages=report.stages+1 end
  local recipe=force.recipes[shipment.item]
  if not recipe then
   report.notes[#report.notes+1]={"razi-audit.no-recipe",shipment.item}
  elseif not recipe.enabled then
   report.notes[#report.notes+1]={"razi-audit.recipe-locked",shipment.item}
  end
 end
 return report
end
function M.command(event)
 local player=event.player_index and game.get_player(event.player_index)
 if player and not player.admin then
  player.print({"razi-audit.admin-only"}) return
 end
 local force=player and player.force or game.forces.player
 if not force then return end
 local report=M.inspect(force,prototypes)
 local output=player or game
 output.print({"razi-audit.summary",tostring(report.stages),
  tostring(#defs.shipments),tostring(#report.errors)})
 for _,entry in ipairs(report.errors) do
  output.print({"razi-audit.blocker",entry})
 end
 for _,entry in ipairs(report.notes) do
  output.print({"razi-audit.note",entry})
 end
 output.print({"razi-audit.read-only"})
end
return M

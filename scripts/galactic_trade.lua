-- Read-only orientation for Planet Express and the Razi manufacturing network.
-- Planet Express owns dispatch/schedules. We never reach into its storage.
local M={}
local function L(key,...) return {"razi-ops."..key,...} end
function M.summary(force)
  local tech=force.technologies and force.technologies["interplanetary-trade-logistics"]
  local ships,unscheduled,transit=0,0,0
  for _,ship in pairs(force.platforms or {}) do
    if ship.valid and not ship.hidden and ship.scheduled_for_deletion==0 then
      ships=ships+1
      local schedule=ship.schedule
      if not schedule or not schedule.records or #schedule.records==0 then
        unscheduled=unscheduled+1
      end
      if ship.space_connection then transit=transit+1 end
    end
  end
  return {
    research=tech,
    unlocked=tech and tech.researched or false,
    ships=ships,unscheduled=unscheduled,transit=transit
  }
end
function M.render(parent,player)
  local title=parent.add{type="label",caption=L("trade-title")}
  title.style.font="heading-2"
  parent.add{type="label",caption=L("trade-intro")}
  local data=M.summary(player.force)
  parent.add{type="label",caption=data.unlocked
    and L("trade-researched") or L("trade-not-researched")}
  if data.research and not data.research.researched then
    local items={}
    for _,prior in pairs(data.research.prerequisites or {}) do
      if not prior.researched then items[#items+1]=prior end
    end
    table.sort(items,function(a,b) return a.name<b.name end)
    for i=1,math.min(3,#items) do
      parent.add{type="label",caption={"",L("trade-needs"),
        " ",items[i].localised_name}}
    end
  end
  local status=parent.add{type="frame",style="inside_shallow_frame",
    direction="vertical"}
  status.style.horizontally_stretchable=true
  status.add{type="label",caption=L("trade-fleet-counts",tostring(data.ships),
    tostring(data.transit),tostring(data.unscheduled))}
  status.add{type="label",caption=L("trade-hub-setup")}
  status.add{type="label",caption=L("trade-pad-setup")}
  status.add{type="label",caption=L("trade-ship-autonomy")}
  -- Read only existing ForceTechnology and prototype objects. Research
  -- and shipping remain managed by Factorio and Planet Express.
  local parts={
    {id="razi-network-precision-matrix",worlds=4},
    {id="razi-network-extreme-lattice",worlds=8}
  }
  local shown=false
  for _,part in ipairs(parts) do
    local technology=player.force.technologies[part.id]
    if technology then
      if not shown then
        local heading=parent.add{type="label",caption=L("trade-components")}
        heading.style.font="default-bold"
        shown=true
      end
      parent.add{type="label",caption={"",
        technology.researched and L("trade-component-ready")
          or L("trade-component-locked"),"  ",
        technology.localised_name}}
      parent.add{type="label",caption=L("trade-component-description",
        tostring(part.worlds))}
    end
  end
  if shown then
    parent.add{type="label",caption=L("trade-component-hint")}
  end
  local count=0
  local next_techs={}
  for _,tech in pairs(player.force.technologies or {}) do
    if tech.name:sub(1,13)=="razi-network-" and not tech.prototype.hidden then
      count=count+1
      if not tech.researched then next_techs[#next_techs+1]=tech end
    end
  end
  table.sort(next_techs,function(a,b) return a.name<b.name end)
  local headline=parent.add{type="label",
    caption=L("trade-network",tostring(count))}
  headline.style.font="default-bold"
  parent.add{type="label",caption=L("trade-network-caption")}
  for i=1,math.min(5,#next_techs) do
    parent.add{type="label",caption={"• ",next_techs[i].localised_name}}
  end
end
return M

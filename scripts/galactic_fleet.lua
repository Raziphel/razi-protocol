-- Read-only platform diagnostics and personal Fleet Operations notes.
-- Nothing in this file changes ship schedules, fuel, cargo or destinations.
local M={}
local function L(key,...) return {"razi-ops."..key,...} end
function M.snapshot(platform)
  local hub=platform.hub
  local has_hub=hub and hub.valid
  local schedule=platform.schedule
  local unscheduled=not schedule or not schedule.records
    or #schedule.records==0
  local damaged=platform.damaged_tiles
  local damage=damaged and #damaged or 0
  local hold=false
  if has_hub and platform.space_location and not platform.space_connection
    and not platform.can_leave_current_location() then
    hold=true
  end
  local alerts={}
  if not has_hub then alerts[#alerts+1]="building" end
  if platform.paused then alerts[#alerts+1]="paused" end
  if unscheduled then alerts[#alerts+1]="unscheduled" end
  if damage>0 then alerts[#alerts+1]="damage" end
  if hold then alerts[#alerts+1]="hold" end
  local progress=platform.distance
  return {
    warnings=alerts,warning_count=#alerts,damage=damage,held=hold,
    speed=platform.speed or 0,weight=platform.weight or 0,
    progress=type(progress)=="number"
      and math.floor(math.max(0,math.min(1,progress))*100+0.5) or nil,
    trips=platform.completed_trips or 0,
    has_hub=not not has_hub
  }
end
local function label(parent,caption)
  return parent.add{type="label",caption=caption}
end
local function bold(parent,caption)
  local e=label(parent,caption)
  e.style.font="default-bold"
  return e
end
function M.render(parent,platform,id,p)
  if not platform or not platform.valid or platform.hidden
    or platform.scheduled_for_deletion~=0 then return end
  local d=M.snapshot(platform)
  local frame=parent.add{type="frame",direction="vertical",style="inside_shallow_frame"}
  frame.style.horizontally_stretchable=true
  local top=frame.add{type="flow",direction="horizontal"}
  bold(top,L("fleet-inspector"))
  label(top,platform.name)
  top.add{type="button",caption="×",
    tags={razi_ops_action="details-close"}}
  if #d.warnings==0 then
    label(frame,L("fleet-clear"))
  else
    for _,warn in ipairs(d.warnings) do
      label(frame,L("fleet-warning-"..warn))
    end
  end
  local conn=platform.space_connection
  if conn then
    label(frame,L("flight-route",conn.from.localised_name,conn.to.localised_name))
    if d.progress then
      label(frame,L("fleet-progress",tostring(d.progress)))
    end
  elseif platform.space_location then
    label(frame,L("fleet-current",platform.space_location.localised_name))
  end
  label(frame,L("fleet-speed",string.format("%.1f",d.speed)))
  label(frame,L("fleet-weight",string.format("%.0f",d.weight)))
  label(frame,L("fleet-trips",tostring(d.trips)))
  label(frame,L("fleet-damage",tostring(d.damage)))
  local schedule=platform.schedule
  label(frame,L("fleet-stops",tostring(schedule and schedule.records
    and #schedule.records or 0)))
  local hub=platform.hub
  if hub and hub.valid then
    local inventory=hub.get_inventory(defines.inventory.hub_main)
    if inventory and inventory.valid then
      local content=inventory.get_contents()
      table.sort(content,function(a,b)
        if a.count~=b.count then return a.count>b.count end
        return a.name<b.name
      end)
      bold(frame,L("fleet-cargo",tostring(#content)))
      for i=1,math.min(6,#content) do
        local item=content[i]
        local proto=prototypes.item[item.name]
        label(frame,{"",proto and proto.localised_name or item.name,
          "  × ",tostring(item.count)})
      end
      if #content==0 then label(frame,L("fleet-empty-cargo")) end
    end
  end
  bold(frame,L("fleet-personal-notes"))
  local note=frame.add{type="textfield",text=p.notes[id] or "",
    tooltip=L("fleet-notes-tooltip"),
    tags={razi_ops_note_id=id}}
  note.style.horizontally_stretchable=true
  label(frame,L("fleet-notes-private"))
end
return M

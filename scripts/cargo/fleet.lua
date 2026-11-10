-- Space platforms of a force at a glance: how many there are, how many have no schedule
-- and how many are travelling. Read when the project is drawn; nothing is stored.
local M={}
-- The technology that opens Planet Express dispatch.
M.technology="interplanetary-trade-logistics"
local function counted(platform)
  return platform.valid and not platform.hidden
    and platform.scheduled_for_deletion==0
end
local function unscheduled(platform)
  local schedule=platform.schedule
  return not (schedule and schedule.records and #schedule.records>0)
end
function M.snapshot(force)
  local result={platforms=0,unscheduled=0,in_transit=0}
  for _,platform in pairs(force.platforms or {}) do
    if counted(platform) then
      result.platforms=result.platforms+1
      if unscheduled(platform) then result.unscheduled=result.unscheduled+1 end
      if platform.space_connection~=nil then
        result.in_transit=result.in_transit+1
      end
    end
  end
  local technologies=force.technologies
  result.research=technologies and technologies[M.technology] or nil
  result.unlocked=result.research~=nil and result.research.researched==true
  return result
end
return M

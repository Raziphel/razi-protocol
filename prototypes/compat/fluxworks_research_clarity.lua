-- Reduce duplicate direct prerequisites in FluxWorks' technology graph.
-- If B already requires A, a technology listing both A and B only draws an
-- extra arrow. Removing that arrow NEVER removes the requirement for A.
-- Razi/Space Age/source technology IDs, research costs and unlocks are untouched.
local M={}

local function implies(technologies,start,target,memo)
  local key=start.."\0"..target
  if memo[key]~=nil then return memo[key] end
  local visited={}
  local pending={start}
  while #pending>0 do
    local current=pending[#pending]
    pending[#pending]=nil
    if current==target then
      memo[key]=true
      return true
    end
    if not visited[current] then
      visited[current]=true
      local tech=technologies[current]
      for _,prior in ipairs(tech and tech.prerequisites or {}) do
        if not visited[prior] then pending[#pending+1]=prior end
      end
    end
  end
  memo[key]=false
  return false
end

function M.data_final_fixes()
  if not (mods and mods["FluxWorks"]) then return 0 end
  local technologies=data.raw.technology or {}
  local memo={}
  local removed=0
  for name,technology in pairs(technologies) do
    -- Only FluxWorks-owned technologies. Avoid changing its masterpiece
    -- research reward chain; projects have intentionally visible links.
    if name:sub(1,3)=="fw-" and name:sub(-8)~="-project" then
      local originals=technology.prerequisites or {}
      if #originals>1 then
        local needed={}
        for i,ancestor in ipairs(originals) do
          local redundant=false
          for j,other in ipairs(originals) do
            if i~=j and other~=ancestor
              and implies(technologies,other,ancestor,memo) then
              redundant=true
              break
            end
          end
          if redundant then
            removed=removed+1
          else
            needed[#needed+1]=ancestor
          end
        end
        if #needed<#originals then
          technology.prerequisites=needed
        end
      end
    end
  end
  log("Razi FluxWorks: simplified "..removed.." implied technology arrows")
  return removed
end

return M

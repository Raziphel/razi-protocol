-- Shared IDs for the Cargo Network presentation.
-- This module contains labels and source identities, never inferred stock.
local M={}
M.chains={
  {
    id="razi-network-precision-matrix",key="matrix",
    worlds={"vulcanus","moshine","fulgora","paracelsin"},
    upgrades={
      "razi-network-matrix-cryo-controllers",
      "razi-network-matrix-rubia-logistics",
      "razi-network-matrix-linox-refining"
    }
  },
  {
    id="razi-network-panglia-optic-bond",key="bond",
    worlds={"panglia","moshine","fulgora"},
    upgrades={
      "razi-network-bond-paracelsin-coils",
      "razi-network-bond-linox-refining"
    }
  },
  {
    id="razi-network-extreme-lattice",key="lattice",
    worlds={"rubia","tenebris","linox-planet_linox","gleba"},
    upgrades={
      "razi-network-lattice-vesta-magnets",
      "razi-network-lattice-vesta-foundations",
      "razi-network-lattice-balack-shielding"
    }
  },
  {
    id="razi-network-umbra-pressure-frame",key="frame",deep=true,
    worlds={"panglia","crucible","linox-planet_linox","vesta"},
    upgrades={
      "razi-network-frame-vesta-foundations",
      "razi-network-frame-aquilo-controllers"
    }
  }
}
function M.state(tech)
  if not tech or (tech.prototype and tech.prototype.hidden) then
    return {status="absent",missing={},count=0}
  end
  if tech.researched then
    return {status="researched",missing={},count=0}
  end
  local missing={}
  for _,prior in pairs(tech.prerequisites or {}) do
    if not prior.researched then missing[#missing+1]=prior end
  end
  table.sort(missing,function(a,b) return a.name<b.name end)
  return {status=#missing==0 and "ready" or "blocked",
    missing=missing,count=#missing}
end
function M.snapshot(force)
  local result={parts={},available=0,researched=0,ready=0,upgrades=0}
  local technologies=force.technologies or {}
  for _,entry in ipairs(M.chains) do
    local technology=technologies[entry.id]
    local state=M.state(technology)
    if state.status~="absent" then
      local row={config=entry,technology=technology,state=state,
        upgrades={},researched_upgrades=0}
      result.available=result.available+1
      if state.status=="researched" then
        result.researched=result.researched+1
      elseif state.status=="ready" then
        result.ready=result.ready+1
      end
      for _,name in ipairs(entry.upgrades) do
        local consumer=technologies[name]
        local consumer_state=M.state(consumer)
        if consumer_state.status~="absent" then
          row.upgrades[#row.upgrades+1]={technology=consumer,
            state=consumer_state,name=name}
          result.upgrades=result.upgrades+1
          if consumer_state.status=="researched" then
            row.researched_upgrades=row.researched_upgrades+1
          end
        end
      end
      result.parts[#result.parts+1]=row
    end
  end
  return result
end
return M

-- Shared IDs for the Cargo Network presentation.
-- This module contains labels and source identities, never inferred stock.
local M={}
-- Resolve quest data at control load, not inside GUI callbacks.
local journal_definitions=require("scripts.razi_journal_data")
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
-- Stable links between real research and the existing Codex entries.
-- No substitute milestones are created for optional factory upgrades that
-- do not yet have their own quest.
local chain_by_technology={}
for _,entry in ipairs(M.chains) do
  chain_by_technology[entry.id]=entry.id
  for _,name in ipairs(entry.upgrades) do
    chain_by_technology[name]=entry.id
  end
end
local quest_by_technology={
  ["razi-network-precision-matrix"]="precision-matrix",
  ["razi-network-extreme-lattice"]="extreme-lattice",
  ["razi-network-panglia-optic-bond"]="alliance-panglia-bond",
  ["razi-network-umbra-pressure-frame"]="alliance-pressure-frame",
  ["razi-network-matrix-cryo-controllers"]="alliance-matrix-aquilo",
  ["razi-network-matrix-rubia-logistics"]="alliance-matrix-rubia",
  ["razi-network-lattice-vesta-magnets"]="alliance-lattice-vesta",
  ["razi-network-bond-paracelsin-coils"]="alliance-bond-paracelsin",
  ["razi-network-bond-linox-refining"]="alliance-bond-linox",
  ["razi-network-frame-vesta-foundations"]="alliance-pressure-vesta",
  ["razi-network-frame-aquilo-controllers"]="alliance-pressure-aquilo"
}
-- One optional source research appears in the Razi Codex. AAI supplies
-- the technology and circuits; only the UI mapping belongs to Razi.
if script and script.active_mods
  and script.active_mods["aai-signal-transmission"] and prototypes
  and prototypes.technology then
  local signal_id=require("prototypes.compat.aai_signal_partnerships")
    .source_technology(prototypes.technology)
  if signal_id then
    quest_by_technology[signal_id]="signal-network"
    chain_by_technology[signal_id]=signal_id
  end
end
function M.chain_for_technology(name)
  return chain_by_technology[name]
end
function M.quest_for_technology(name)
  return quest_by_technology[name]
end
function M.chain_for_quest(id)
  local quest=journal_definitions.by_id[id]
  if not quest then return nil end
  local chain=M.chain_for_technology(quest.tech)
  return chain,quest.tech
end
function M.is_installed(force,chain)
  local definitions=force and force.technologies or {}
  local tech=chain and definitions[chain]
  return tech and (not tech.prototype or not tech.prototype.hidden)
end

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
  -- Prerequisites alone do not make research available. Other installed
  -- mods can gate a technology through its enabled flag.
  if tech.enabled==false then
    return {status="disabled",missing=missing,count=#missing}
  end
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

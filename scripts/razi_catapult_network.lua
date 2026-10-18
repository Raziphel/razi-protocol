-- Read-only Vespera Orbital Catapult route dossier. All routes come from
-- the same data-stage manifest that supplies the upstream transport mod.
-- There are no on-tick checks, inventory readers or fabricated deliveries.
local M={}
local links=require("prototypes.compat.orbital_catapult").links
local discovery={
  muria="planet-discovery-muria",
  rubia="planet-discovery-rubia",
  aquilo="planet-discovery-aquilo"
}
local purpose={
  ["aquilo:muria"]="cold-resupply",
  ["muria:rubia"]="materials-transfer",
  ["aquilo:rubia"]="cryo-materials"
}
local function researched(force,world)
  local technology=force and force.technologies
    and force.technologies[discovery[world]]
  return technology and technology.researched==true or false
end
local function setting(name,group,default)
  local current=settings and settings[group] and settings[group][name]
  if current==nil then return default end
  return current.value==true
end
function M.snapshot(force,options)
  options=options or {}
  local planet_protos=options.planets or (prototypes and
    (prototypes.planet or prototypes.space_location)) or {}
  local loaded=options.loaded
  if loaded==nil then
    loaded=script and script.active_mods and
      script.active_mods["orbital-cannon"]~=nil or false
  end
  local enabled=options.enabled
  if enabled==nil then
    enabled=setting("razi-orbital-catapult-local-links","startup",false)
  end
  local hide=options.hide
  if hide==nil then hide=setting("razi-hide-spoilers","global",false) end
  local result={installed=loaded==true,enabled=enabled==true,
    entries={},concealed=0,total=0,visible=0}
  if not result.installed or not result.enabled then return result end
  local seen={}
  for _,link in ipairs(links) do
    local name,a,b=link[1],link[2],link[3]
    -- Deduplicate the two source-owned directional link definitions.
    local key=a<b and a..":"..b or b..":"..a
    if not seen[key] then
      seen[key]=true
      if planet_protos[a] and planet_protos[b] then
        result.total=result.total+1
        local from=researched(force,a)
        local to=researched(force,b)
        if hide and not (from and to) then
          result.concealed=result.concealed+1
        else
          result.visible=result.visible+1
          result.entries[#result.entries+1]={
            id=name,source=a,target=b,purpose=purpose[key],
            source_researched=from,target_researched=to,
            state=from and to and "researched" or "unresearched"
          }
        end
      end
    end
  end
  return result
end
function M.for_world(snapshot,world)
  local result={}
  for _,entry in ipairs(snapshot and snapshot.entries or {}) do
    if entry.source==world or entry.target==world then
      result[#result+1]=entry
    end
  end
  return result
end
return M

-- Read-only regional Orbital Catapult freight dossier. The one true
-- route manifest is the prototype module; do not duplicate route IDs here.
-- No saved progress, shipments, inventory manipulation or on-tick work.
local M={}
local manifest=require("prototypes.compat.orbital_catapult")
local discovery={
  muria="planet-discovery-muria",
  rubia="planet-discovery-rubia",
  aquilo="planet-discovery-aquilo",
  vulcanus="planet-discovery-vulcanus",
  castra="planet-discovery-castra",
  gleba="planet-discovery-gleba",
  moshine="planet-discovery-moshine",
  maraxsis="planet-discovery-maraxsis"
}
local details={
  ["aquilo:muria"]={"vespera","cold-resupply"},
  ["muria:rubia"]={"vespera","materials-transfer"},
  ["aquilo:rubia"]={"vespera","cryo-materials"},
  ["castra:vulcanus"]={"solaris","smelting-salvage"},
  ["gleba:moshine"]={"nyxaris","bio-compute"},
  ["maraxsis:rubia"]={"vespera","subsea-supply"}
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
  if loaded==nil then loaded=script and script.active_mods
    and script.active_mods["orbital-cannon"]~=nil or false end
  local enabled=options.enabled
  if enabled==nil then enabled=setting(
    "razi-orbital-catapult-local-links","startup",false) end
  local regional=options.regional
  if regional==nil then regional=setting(
    "razi-orbital-catapult-regional-links","startup",false) end
  local hide=options.hide
  if hide==nil then hide=setting("razi-hide-spoilers","global",false) end
  local result={installed=loaded==true,enabled=enabled==true or regional==true,
    local_enabled=enabled==true,regional_enabled=regional==true,
    entries={},concealed=0,total=0,visible=0}
  if not result.installed or not result.enabled then return result end
  local seen={}
  for _,link in ipairs(manifest.active_links(enabled,regional)) do
    local name,a,b=link[1],link[2],link[3]
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
          local detail=details[key]
          result.visible=result.visible+1
          result.entries[#result.entries+1]={
            id=name,source=a,target=b,
            region=detail and detail[1],purpose=detail and detail[2],
            source_researched=from,target_researched=to,
            state=from and to and "researched" or "unresearched"
          }
        end
      end
    end
  end
  local chapter_order={solaris=1,nyxaris=2,vespera=3}
  table.sort(result.entries,function(a,b)
    local left=chapter_order[a.region] or 99
    local right=chapter_order[b.region] or 99
    if left~=right then return left<right end
    return a.id<b.id
  end)
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

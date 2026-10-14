-- Razi Galactic Atlas. Reads the loaded prototypes and force research only
-- when a player requests an inspection. Never unlocks or creates a surface.
local M={}
local trials=require("scripts.razi_nexus_trials")
local weather=require("scripts.razi_weather_guide")
local convergence=require("scripts.razi_convergence")
-- Known, installed native endpoints only. This annotates the Atlas without
-- drawing fake paths, changing source location prototypes or leaking secrets.
M.expedition_briefs={
 ["solar-system-edge"]="edge",
 ["shattered-planet"]="shattered",
 ["nexus"]="nexus",
 ["razi-deep-space-edge"]="frontier",
 ["black-hole-approach"]="approach"
}
local function L(key,...) return {"razi-ops."..key,...} end
local function label(parent,caption)
  return parent.add{type="label",caption=caption}
end
local function line(parent,...)
  return label(parent,{"",...})
end
local function known(force,name)
  return name and prototypes.space_location[name]
    and not prototypes.space_location[name].hidden
    and force.is_space_location_unlocked(name)
end
local function sorted_keys(tbl)
  local result={}
  for key in pairs(tbl or {}) do result[#result+1]=key end
  table.sort(result)
  return result
end
local function named_location(id)
  local loc=prototypes.space_location[id]
  return loc and loc.localised_name or id
end
-- Source techs are discovered from the real final technology effects.
-- No hard-coded optional planet prerequisites or assumed science packs.
local unlock_catalog
local function location_research_catalog()
  if unlock_catalog then return unlock_catalog end
  if not (prototypes and prototypes.technology) then return nil end
  local index={}
  for name,proto in pairs(prototypes.technology) do
    for _,effect in pairs(proto.effects or {}) do
      if effect.type=="unlock-space-location" and effect.space_location then
        local names=index[effect.space_location]
        if not names then
          names={}
          index[effect.space_location]=names
        end
        names[#names+1]=name
      end
    end
  end
  unlock_catalog=index
  return index
end
function M.unlock_research(force,id)
  local choices={}
  local function add_tech(tech)
    if not tech then return end
    local missing={}
    for _,prior in pairs(tech.prerequisites or {}) do
      if not prior.researched then missing[#missing+1]=prior end
    end
    table.sort(missing,function(a,b) return a.name<b.name end)
    choices[#choices+1]={tech=tech,missing=missing}
  end
  local index=location_research_catalog()
  if index then
    for _,name in ipairs(index[id] or {}) do
      add_tech(force.technologies and force.technologies[name])
    end
  else
    for _,tech in pairs(force.technologies or {}) do
      for _,effect in pairs(tech.prototype.effects or {}) do
        if effect.type=="unlock-space-location" and effect.space_location==id then
          add_tech(tech)
          break
        end
      end
    end
  end
  table.sort(choices,function(a,b)
    if #a.missing~=#b.missing then return #a.missing<#b.missing end
    return a.tech.name<b.tech.name
  end)
  return choices
end
-- Dijkstra chooses shortest *listed distance*, not a promised in-game route.
-- All nodes must already be known/unlocked. Source-native travel rules still
-- take precedence, so the resulting corridor is planning guidance only.
function M.shortest_path(force,start,destination,connections)
  if not known(force,start) or not known(force,destination) then return nil end
  if start==destination then return {start},0 end
  local graph={}
  -- Cache the unlock checks for each location within this route query.
  local checked={}
  local function accessible(name)
    if not name then return false end
    if checked[name]==nil then checked[name]=not not known(force,name) end
    return checked[name]
  end
  for _,edge in pairs(connections or prototypes.space_connection or {}) do
    local a=edge.from and edge.from.name
    local b=edge.to and edge.to.name
    if accessible(a) and accessible(b) and edge.length
      and edge.length>0 then
      graph[a]=graph[a] or {}
      graph[b]=graph[b] or {}
      graph[a][#graph[a]+1]={to=b,km=edge.length}
      graph[b][#graph[b]+1]={to=a,km=edge.length}
    end
  end
  local distances={[start]=0}
  local previous,visited={},{}
  while true do
    local current,best=nil,math.huge
    for node,cost in pairs(distances) do
      if not visited[node] and cost<best then current,best=node,cost end
    end
    if not current or current==destination then break end
    visited[current]=true
    for _,route in ipairs(graph[current] or {}) do
      local candidate=best+route.km
      if candidate<(distances[route.to] or math.huge) then
        distances[route.to]=candidate
        previous[route.to]=current
      end
    end
  end
  if not distances[destination] then return nil end
  local reverse,node={},destination
  while node do
    reverse[#reverse+1]=node
    node=previous[node]
    if #reverse>256 then return nil end
  end
  local path={}
  for i=#reverse,1,-1 do path[#path+1]=reverse[i] end
  return path,distances[destination]
end
-- Use actual asteroid prototype IDs rather than inventing route danger levels.
-- The name class is indicative; each mod owns its actual spawn frequencies.
function M.asteroid_profile(definitions)
  local size="unlisted"
  local rank={unlisted=0,small=1,medium=2,big=3,huge=4}
  local types={}
  for _,spawn in ipairs(definitions or {}) do
    local name=spawn.asteroid
    if type(name)=="string" then
      types[name]=true
      local group=name:find("huge",1,true) and "huge"
        or name:find("big",1,true) and "big"
        or name:find("medium",1,true) and "medium"
        or name:find("small",1,true) and "small" or "unlisted"
      if rank[group]>rank[size] then size=group end
    end
  end
  local count=0
  for _ in pairs(types) do count=count+1 end
  return size,count
end
local connections_by_world
local function connection_index()
  if connections_by_world then return connections_by_world end
  local index={}
  for _,edge in pairs(prototypes.space_connection or {}) do
    local a,b=edge.from and edge.from.name,edge.to and edge.to.name
    if a and b then
      index[a]=index[a] or {}
      index[a][#index[a]+1]=edge
      if b~=a then
        index[b]=index[b] or {}
        index[b][#index[b]+1]=edge
      end
    end
  end
  connections_by_world=index
  return index
end
local function connected_routes(force,id,show_locked)
  local results={}
  for _,edge in ipairs(connection_index()[id] or {}) do
    local a,b=edge.from and edge.from.name,edge.to and edge.to.name
    local other=a==id and b or b==id and a or nil
    local location=other and prototypes.space_location[other]
    if location and not location.hidden
      and (show_locked or force.is_space_location_unlocked(other)) then
      local patterns=edge.asteroid_spawn_definitions
      local size,count=M.asteroid_profile(patterns)
      results[#results+1]={name=other,length=edge.length or 0,
        patterns=count,largest=size,
        unlocked=force.is_space_location_unlocked(other)}
    end
  end
  table.sort(results,function(a,b)
    if a.unlocked~=b.unlocked then return a.unlocked end
    if a.length~=b.length then return a.length<b.length end
    return a.name<b.name
  end)
  return results
end
local function bold(parent,caption)
  local element=label(parent,caption)
  element.style.font="default-bold"
  return element
end
function M.render(parent,player,id,p)
  local proto=prototypes.space_location[id]
  if not proto or proto.hidden then return end
  local unlocked=player.force.is_space_location_unlocked(id)
  if not unlocked and not p.locked then return end
  local frame=parent.add{type="frame",direction="vertical",style="inside_shallow_frame"}
  frame.style.horizontally_stretchable=true
  local head=frame.add{type="flow",direction="horizontal"}
  bold(head,L("atlas-title"))
  head.add{type="label",caption=proto.localised_name}
  head.add{type="button",caption="×",
    tags={razi_ops_action="details-close"}}
  label(frame,L(unlocked and "atlas-known" or "atlas-locked"))
  local brief=unlocked and M.expedition_briefs[id]
  if brief and convergence.available(player.force) then
    local dossier=frame.add{type="frame",direction="vertical",
      style="inside_shallow_frame"}
    dossier.style.horizontally_stretchable=true
    bold(dossier,L("atlas-convergence-heading"))
    local description=label(dossier,L("atlas-convergence-"..brief))
    description.style.single_line=false
    description.style.horizontally_stretchable=true
    dossier.add{type="button",caption=L("atlas-convergence-open"),
      tags={razi_ops_action="atlas-convergence"}}
  end
  if unlocked then
    label(frame,proto.localised_description)
    if id=="nexus" then
      local outcome=trials.snapshot(player.force)
      if outcome then
        bold(frame,L("atlas-nexus-heading"))
        label(frame,L("atlas-nexus-victories",
          tostring(outcome.count),tostring(outcome.total)))
        frame.add{type="button",caption=L("atlas-nexus-codex"),
          tags={razi_ops_action="nexus-codex",value="arachnid-queen"}}
      end
    end
    local atmosphere=weather.for_quest({world=id})
    if atmosphere then
      bold(frame,L("atlas-weather-heading"))
      local description=label(frame,{"journal-weather."..atmosphere.world})
      description.style.single_line=false
      description.style.horizontally_stretchable=true
      label(frame,L(atmosphere.enabled
        and "atlas-weather-enabled" or "atlas-weather-disabled"))
    end
    local conditions=proto.type=="planet" and proto.surface_properties or nil
    if conditions then
      bold(frame,L("atlas-environment"))
      local keys=sorted_keys(conditions)
      for i=1,math.min(5,#keys) do
        local key=keys[i]
        label(frame,L("atlas-surface-value",key,tostring(conditions[key])))
      end
    end
  else
    label(frame,L("atlas-spoiler-warning"))
  end
  local research=M.unlock_research(player.force,id)
  if #research>0 then
    bold(frame,L("atlas-unlock"))
    for i=1,math.min(#research,3) do
      local node=research[i]
      line(frame,node.tech.researched and L("atlas-done") or L("atlas-pending"),
        "  ",node.tech.localised_name)
      if not node.tech.researched then
        local blockers=math.min(8,#node.missing)
        for j=1,blockers do
          local prereq=node.missing[j]
          line(frame,"    ",L("atlas-missing")," ",prereq.localised_name)
        end
        if blockers==0 then label(frame,L("atlas-ready-to-research")) end
        local packs=node.tech.research_unit_ingredients or {}
        if #packs>0 then
          local named={}
          for j=1,math.min(5,#packs) do
            local input=packs[j]
            local name=input.name or input[1]
            local item=prototypes.item[name]
            named[#named+1]=item and item.localised_name or name
          end
          local text={"",L("atlas-science")," "}
          for j,name in ipairs(named) do
            if j>1 then text[#text+1]=", " end
            text[#text+1]=name
          end
          label(frame,text)
        end
      end
    end
  else
    label(frame,L("atlas-no-unlock"))
  end
  if unlocked and #research>0 then
    -- Only actual available technology links are displayed. Razi-owned
    -- exchanges can depend on a world without making that world mandatory.
    local discovery={}
    for _,node in ipairs(research) do discovery[node.tech.name]=true end
    local industries={}
    for _,tech in pairs(player.force.technologies or {}) do
      if tech.name:sub(1,5)=="razi-" and not tech.prototype.hidden then
        for name in pairs(tech.prerequisites or {}) do
          if discovery[name] then
            industries[#industries+1]=tech
            break
          end
        end
      end
    end
    table.sort(industries,function(a,b) return a.name<b.name end)
    if #industries>0 then
      bold(frame,L("atlas-industry"))
      for i=1,math.min(6,#industries) do
        local tech=industries[i]
        line(frame,tech.researched and "✓ " or "• ",tech.localised_name)
      end
    end
  end
  if unlocked then
    local button=frame.add{type="button",caption=L("atlas-set-origin"),
      tags={razi_ops_action="atlas-origin",value=id}}
    button.tooltip=L("atlas-origin-tooltip")
  end
  local origin=p.atlas_origin
  if origin and known(player.force,origin) and unlocked then
    bold(frame,L("atlas-itinerary",named_location(origin)))
    local path,distance=M.shortest_path(player.force,origin,id)
    if path then
      label(frame,L("atlas-route-summary",tostring(#path-1),tostring(distance)))
      if #path>1 then
        local text={"",L("atlas-route-notice")," "}
        for i,node in ipairs(path) do
          if i>1 then text[#text+1]="  ›  " end
          text[#text+1]=named_location(node)
        end
        label(frame,text)
      end
    else
      label(frame,L("atlas-no-route"))
    end
  end
  if unlocked then
    bold(frame,L("atlas-connections"))
    local routes=connected_routes(player.force,id,p.locked)
    for i=1,math.min(#routes,9) do
      local r=routes[i]
      line(frame,r.unlocked and "• " or "○ ",named_location(r.name),
        "  •  ",L("atlas-km",tostring(r.length)),
        "  •  ",L("atlas-patterns",tostring(r.patterns)),
        "  •  ",L("atlas-asteroid-size-"..r.largest),
        r.unlocked and "" or "  [LOCKED]")
    end
    if #routes==0 then label(frame,L("atlas-no-routes")) end
  end
end
return M

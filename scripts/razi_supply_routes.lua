-- A.6 read-only, bounded path finder for real source space connections
-- and declared, researched Razi Orbital Catapult corridors.
-- Map adjacency != a working platform, fueled launcher, cargo or transfer.
local M={}
local catapult=require("scripts.razi_catapult_network")
local freight=require("scripts.razi_freight_orders")
local MAX_HOPS=6
local MAX_PATHS=4
local MAX_EXPANSIONS=1600
local MAX_EDGES=400

local function name(value)
  if type(value)=="string" then return value end
  return value and value.name
end
local function unlocked(force,world)
  if not (force and type(world)=="string") then return false end
  -- Native script-unlock state is authoritative when the engine exposes it.
  if force.is_space_location_unlocked then
    return force.is_space_location_unlocked(world)==true
  end
  local tech=force.technologies and
    force.technologies["planet-discovery-"..world]
  return tech and tech.researched==true or false
end
M.unlocked=unlocked

function M.graph(force,options)
  options=options or {}
  local locations=options.locations or
    (prototypes and prototypes.space_location) or {}
  local connections=options.connections or
    (prototypes and prototypes.space_connection) or {}
  local net=options.network or catapult.snapshot(force)
  local graph={nodes={},adj={},edges=0,limited=false}
  local function known(world)
    return type(world)=="string" and locations[world]~=nil
      and unlocked(force,world)
  end
  local function edge(a,b,mode,id,km)
    if graph.edges>=MAX_EDGES then graph.limited=true;return end
    if a==b or not (known(a) and known(b)) then return end
    graph.adj[a]=graph.adj[a] or {}
    graph.adj[a][#graph.adj[a]+1]={
      from=a,to=b,mode=mode,id=id,km=km}
    graph.nodes[a]=true
    graph.nodes[b]=true
    graph.edges=graph.edges+1
  end
  -- Standard platform connections are source map edges, not active
  -- timetables. Their from/to are prototypes in Factorio 2.1.
  local native={}
  for key,conn in pairs(connections) do
    local a,b=name(conn.from),name(conn.to)
    if conn.valid~=false and conn.hidden~=true
      and known(a) and known(b) and a~=b then
      native[#native+1]={id=conn.name or key,from=a,to=b,
        km=type(conn.length)=="number" and conn.length or nil}
    end
  end
  table.sort(native,function(a,b)return tostring(a.id)<tostring(b.id) end)
  for _,connection in ipairs(native) do
    edge(connection.from,connection.to,"platform",
      connection.id,connection.km)
    edge(connection.to,connection.from,"platform",
      connection.id,connection.km)
  end
  -- The only catapult edges are original source-manifest IDs, each
  -- revalidated by A.1's strict directed route authority.
  for _,lane in ipairs(net.entries or {}) do
    if lane.state=="researched" and lane.source_researched
      and lane.target_researched then
      for _,pair in ipairs({
        {lane.source,lane.target},{lane.target,lane.source}}) do
        local id="razi-"..pair[1].."-"..pair[2].."-catapult"
        local route=freight.route(force,id)
        if route and route.source==pair[1] and route.target==pair[2] then
          edge(pair[1],pair[2],"catapult",id,nil)
        end
      end
    end
  end
  for _,adj in pairs(graph.adj) do
    table.sort(adj,function(a,b)
      if a.to~=b.to then return a.to<b.to end
      if a.mode~=b.mode then return a.mode<b.mode end
      return a.id<b.id
    end)
  end
  return graph
end

local function less(a,b)
  if #a.legs~=#b.legs then return #a.legs<#b.legs end
  if a.switches~=b.switches then return a.switches<b.switches end
  if a.platform_legs~=b.platform_legs then
    return a.platform_legs<b.platform_legs
  end
  -- Compare known platform distance ONLY when both paths have the same
  -- number of platform legs; catapult distance has no comparable km.
  if a.platform_km~=b.platform_km then return a.platform_km<b.platform_km end
  return a.key<b.key
end

function M.paths(graph,origin,destination)
  local answer={}
  if not (graph and graph.nodes[origin] and graph.nodes[destination])
    or origin==destination then return answer end
  local visited={[origin]=true}
  local path={}
  local attempts=0
  local function walk(world)
    if attempts>=MAX_EXPANSIONS then return end
    if world==destination then
      local legs={}
      local switches,platform_legs,km=0,0,0
      local keys={}
      for i,leg in ipairs(path) do
        legs[i]={from=leg.from,to=leg.to,mode=leg.mode,
          id=leg.id,km=leg.km}
        keys[i]=leg.mode..":"..leg.id..":"..leg.from..":"..leg.to
        if leg.mode=="platform" then
          platform_legs=platform_legs+1
          km=km+(leg.km or 0)
        end
        if i>1 and path[i-1].mode~=leg.mode then
          switches=switches+1
        end
      end
      answer[#answer+1]={legs=legs,switches=switches,
        platform_legs=platform_legs,platform_km=km,
        key=table.concat(keys,"|")}
      table.sort(answer,less)
      while #answer>MAX_PATHS do table.remove(answer) end
      return
    end
    if #path>=MAX_HOPS then return end
    for _,link in ipairs(graph.adj[world] or {}) do
      attempts=attempts+1
      if attempts>MAX_EXPANSIONS then return end
      if not visited[link.to] then
        visited[link.to]=true
        path[#path+1]=link
        walk(link.to)
        path[#path]=nil
        visited[link.to]=nil
      end
    end
  end
  walk(origin)
  return answer
end

-- A backwards reachability scan is cheaper than pathfinding individually
-- for every candidate origin. Only real discovered planets can be selected.
function M.origins(graph,destination,planets)
  local list={}
  if not (graph and graph.nodes[destination]) then return list end
  local reachable={[destination]=true}
  local frontier={[destination]=true}
  for _=1,MAX_HOPS do
    local next_frontier={}
    for from,edges in pairs(graph.adj) do
      if not reachable[from] then
        for _,edge in ipairs(edges) do
          if frontier[edge.to] then
            next_frontier[from]=true
            break
          end
        end
      end
    end
    if not next(next_frontier) then break end
    for world in pairs(next_frontier) do reachable[world]=true end
    frontier=next_frontier
  end
  for world in pairs(planets or (game and game.planets) or {}) do
    if world~=destination and reachable[world] then
      list[#list+1]=world
    end
  end
  table.sort(list)
  return list
end

-- Recheck saved legs at display / use time; an uninstalled source mod,
-- research rollback or disabled corridor must not leak old waypoints.
function M.valid_path(graph,path)
  if not (graph and path and type(path.legs)=="table"
    and #path.legs>=1 and #path.legs<=MAX_HOPS) then return false end
  local previous=nil
  for _,leg in ipairs(path.legs) do
    if not (type(leg.from)=="string" and type(leg.to)=="string"
      and type(leg.id)=="string" and
      (leg.mode=="platform" or leg.mode=="catapult")
      and (not previous or previous==leg.from)) then return false end
    local found=false
    for _,candidate in ipairs(graph.adj[leg.from] or {}) do
      if candidate.to==leg.to and candidate.mode==leg.mode
        and candidate.id==leg.id then found=true;break end
    end
    if not found then return false end
    previous=leg.to
  end
  return true
end
return M

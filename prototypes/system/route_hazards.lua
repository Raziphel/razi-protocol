-- Route danger levels for the map legend and hover text.
-- Uses the asteroid spawn definitions without changing them.
local M = {}
-- Shared low-saturation hazard palette for the starmap legend, route
-- tooltips and static connected line artwork. Mirrors real asteroid sizes.
local colors = {
  {r=.42,g=.64,b=.77}, -- none / no recorded hostile spawns: slate blue
  {r=.38,g=.70,b=.68}, -- small: sea glass
  {r=.48,g=.76,b=.54}, -- medium: sage
  {r=.94,g=.73,b=.38}, -- big: brass
  {r=.92,g=.43,b=.36}  -- huge or dense big: vermilion
}
local belt_color = colors[4]

local function max_probability(def)
  local maximum = (type(def.probability)=="number" and def.probability) or 0
  for _,point in ipairs(def.spawn_points or {}) do
    if type(point.probability)=="number" then
      maximum=math.max(maximum,point.probability)
    end
  end
  return maximum
end

function M.is_belt_crossing(route)
  local a,b=route.from or "",route.to or ""
  return (a:find("belt%-inner") and b:find("belt%-outer"))
      or (b:find("belt%-inner") and a:find("belt%-outer"))
end

function M.kind(route)
  local a,b=route.from or "",route.to or ""
  if M.is_belt_crossing(route) then return "belt-crossing" end
  if a:find("belt",1,true) or b:find("belt",1,true) then
    return "belt-approach"
  end
  if a:find("solar-system-edge",1,true) or b:find("solar-system-edge",1,true)
    or a:find("deep-space",1,true) or b:find("deep-space",1,true) then
    return "deep-space"
  end
  if route.shape=="line" then return "interstellar" end
  return "local"
end

-- Freight scale is derived from the real connection length; not an ETA.
function M.haul_class(route)
  local length=route and route.length
  if type(length)~="number" or length<=0 then return "unlisted" end
  if length<=20000 then return "shuttle" end
  if length<=75000 then return "regional" end
  if length<=150000 then return "long-haul" end
  return "expedition"
end

function M.inspect(route)
  local peaks={small=0,medium=0,big=0,huge=0}
  local unknown=false
  local chunks={}
  local chunk_count=0
  for _,def in ipairs(route.asteroid_spawn_definitions or {}) do
    if type(def)=="table" and max_probability(def)>0 then
      local name=def.asteroid
      if type(name)=="string" then
        if def.type=="asteroid-chunk" or name:find("asteroid%-chunk$") then
          if not chunks[name] then
            chunks[name]=true
            chunk_count=chunk_count+1
          end
        else
          local size=name:match("^(small)%-") or name:match("^(medium)%-")
            or name:match("^(big)%-") or name:match("^(huge)%-")
          if size then
            peaks[size]=math.max(peaks[size],max_probability(def))
          else
            unknown=true
          end
        end
      end
    end
  end

  local largest="none"
  for _,size in ipairs({"small","medium","big","huge"}) do
    if peaks[size]>0 then largest=size end
  end
  local tier=1
  if peaks.small>0 then tier=2 end
  if peaks.medium>0 then tier=3 end
  if peaks.big>0 then tier=4 end
  if peaks.huge>0 or peaks.big>=0.05 then tier=5 end
  if unknown then tier=math.max(tier,3) end
  local sizes=0
  for _,probability in pairs(peaks) do
    if probability>0 then sizes=sizes+1 end
  end
  local mix=(sizes>1 and "mixed") or (sizes==1 and "single") or "unlisted"
  if unknown then mix="unclassified" end
  return {tier=tier,largest=largest,chunks=chunk_count,unknown=unknown,
    size_count=sizes,mix=mix}
end

function M.color(route)
  local tier=M.inspect(route).tier
  -- A required physical belt crossing cannot visually claim to be a
  -- harmless blue line when source mods omit a standard spawn category.
  if M.is_belt_crossing(route) then tier=math.max(4,tier) end
  return colors[tier]
end

M.colors=colors
M.belt_color=belt_color
return M

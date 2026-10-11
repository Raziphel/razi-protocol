-- One source of truth for graphical risk colours and route hover intelligence.
-- Reads final spawn prototypes; never mutates asteroid populations or progression.
local M = {}
local colors = {
  {r=0.31,g=0.74,b=0.98}, -- no recorded hostile spawns: blue
  {r=0.31,g=0.85,b=0.61}, -- small asteroids: green
  {r=0.98,g=0.79,b=0.28}, -- medium / unidentified: amber
  {r=1.00,g=0.47,b=0.25}, -- big: orange
  {r=1.00,g=0.27,b=0.36}  -- huge or very dense big: red
}
local belt_color = {r=0.72,g=0.48,b=1.00}

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
  return {tier=tier,largest=largest,chunks=chunk_count,unknown=unknown}
end

function M.color(route)
  if M.is_belt_crossing(route) then return belt_color end
  return colors[M.inspect(route).tier]
end

M.colors=colors
M.belt_color=belt_color
return M

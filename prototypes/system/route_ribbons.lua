-- Razi Protocol 2.1: actual color along native Factorio space connections.
-- One shared 128-bearing antialiased sheet; no runtime script or route edits.
-- Keep ribbon shifts exactly on the path (NOT beside it as in the old overlay).
local M={}
local hz=require("prototypes.system.route_hazards")
local SHEET="__razi-protocol__/graphics/route-highlights/route-ribbons.png"
local OLD="__razi-protocol__/graphics/route-highlights/"
local ANGLES,CELL,COLS=128,64,16
local UNIT=50 -- authored line body in source pixels (extra joined end caps)
local TARGET_SPAN=3.6 -- starmap chart units
local ROUTE_LIMIT,LAYER_BUDGET=128,2400
local abs,sqrt,ceil,floor,cos,sin=math.abs,math.sqrt,math.ceil,math.floor,math.cos,math.sin
local function angle(dy,dx)
  return (math.atan2 and math.atan2(dy,dx) or math.atan(dy,dx))%math.pi
end
local function obsolete(sprite)
  local f=sprite and sprite.filename
  return type(f)=="string" and f:sub(1,#OLD)==OLD and
    (f:find("continuous-strokes.png",1,true)
      or f:find("directional-strokes.png",1,true)
      or f:find("quality-risk-marker.png",1,true)
      or f:match("/guide%-%d+%.png$"))~=nil
end
M.sheet=SHEET
M.obsolete=obsolete

local function candidate(owner,route,mode,scope)
  if not route or mode=="off" or not owner.is_navigation_highlight(route,scope)
    then return nil end
  local a,b=owner.position(route.from),owner.position(route.to)
  if not a or not b then return nil end
  local span=sqrt((a.x-b.x)^2+(a.y-b.y)^2)
  if span<2.5 or span>1800 then return nil end
  if scope=="major" and not owner.is_major(route,a,b) then return nil end
  local sample,length=owner.route_path(route,a,b)
  if not sample or length<2.5 then return nil end
  local trim=math.min(1.1,length*.10)
  local covered=length-2*trim
  if covered<=0 then return nil end
  local pieces=math.max(1,math.min(ROUTE_LIMIT,ceil(covered/TARGET_SPAN)))
  return {route=route,sample=sample,length=length,trim=trim,
    covered=covered,pieces=pieces}
end
M.candidate=candidate

local function render(owner,row,mode,n)
  local ladder=require("scripts.razi_asteroid_difficulty")
  local setting=settings and settings.startup
    and settings.startup["razi-asteroid-difficulty-scale"]
  local result={}
  for j=1,n do
    local start=(row.trim+row.covered*(j-1)/n)/row.length
    local finish=(row.trim+row.covered*j/n)/row.length
    local a,b=row.sample(start),row.sample(finish)
    local dx,dy=b.x-a.x,b.y-a.y
    local d=sqrt(dx*dx+dy*dy)
    if d>.01 then
      -- Quantization error stays below ~1px for short route chords.
      local index=floor(angle(dy,dx)/math.pi*ANGLES+.5)%ANGLES
      -- Sample quality danger at this actual point of the journey,
      -- instead of tinting the entire 150,000 km crossing by one
      -- arbitrary endpoint. Long routes transition naturally through
      -- blue, green, yellow, orange and finally the red endgame.
      local midpoint=(start+finish)/2
      local grade=ladder.color_level(ladder.route_level(
        row.route,midpoint,setting and setting.value))
      local color=ladder.route_color(grade)
      local alpha=.78+.014*grade
      result[#result+1]={
        type="sprite",filename=SHEET,
        x=(index%COLS)*CELL,y=floor(index/COLS)*CELL,
        size={CELL,CELL},scale=d*32/UNIT,
        shift={(a.x+b.x)*16,(a.y+b.y)*16},
        priority="extra-high-no-scale",flags={"gui-icon"},
        blend_mode="normal",tint={
          r=color.r,g=color.g,b=color.b,a=alpha
        }
      }
    end
  end
  return result
end
M.render=render
function M.strokes_for_connection(owner,route,mode,scope)
  local row=candidate(owner,route,mode,scope)
  return row and render(owner,row,mode,row.pieces) or {}
end

function M.data_final_fixes(owner)
  local startup=settings and settings.startup or {}
  local mode=startup["razi-route-overlay-mode"]
    and startup["razi-route-overlay-mode"].value or "danger"
  local scope=startup["razi-route-overlay-scope"]
    and startup["razi-route-overlay-scope"].value or "all"
  local ui=(data.raw["utility-sprites"] or {}).default
  local atlas=ui and ui.starmap_star
  if not (atlas and type(atlas.layers)=="table") then return 0 end
  for i=#atlas.layers,1,-1 do
    if obsolete(atlas.layers[i]) then table.remove(atlas.layers,i) end
  end
  if mode=="off" or (mods and mods["space-route-overlay"]) then return 0 end
  -- Respect subsequent final-fixes calls. Never draw duplicate ribbons.
  for _,sprite in ipairs(atlas.layers) do
    if sprite.filename==SHEET then return 0 end
  end
  local routes,total={},0
  for name,route in pairs(data.raw["space-connection"] or {}) do
    local row=candidate(owner,route,mode,scope)
    if row then
      row.name=name
      row.grade=owner.route_color_level(route) or owner.threat_tier(route)
      row.belt=hz.is_belt_crossing(route) and true or false
      routes[#routes+1]=row
      total=total+row.pieces
    end
  end
  -- Deterministic priorities, but distribute atlas capacity across every
  -- resolved native route rather than use the entire budget on the first
  -- dangerous star corridor, which left the screenshot mostly grey.
  table.sort(routes,function(a,b)
    if a.belt~=b.belt then return a.belt end
    if a.grade~=b.grade then return a.grade>b.grade end
    return a.name<b.name
  end)
  local density=math.max(1,total/LAYER_BUDGET)
  local count,covered,skipped=0,0,0
  for _,row in ipairs(routes) do
    if count>=LAYER_BUDGET then skipped=skipped+1
    else
      local n=math.min(LAYER_BUDGET-count,
        math.max(1,floor(row.pieces/density)))
      -- Do not stretch narrow line artwork into thick, ugly map stripes.
      if row.covered/n<=13.5 then
        local segments=render(owner,row,mode,n)
        for _,sprite in ipairs(segments) do
          atlas.layers[#atlas.layers+1]=sprite
          count=count+1
        end
        if #segments>0 then covered=covered+1 end
      else skipped=skipped+1 end
    end
  end
  if type(log)=="function" then
    log(("[Razi Protocol/routes] Colored %d/%d known routes with %d "..
      "contiguous 1-10 hazard ribbon segments (%d skipped; limit %d)"):format(
      covered,#routes,count,skipped,LAYER_BUDGET))
  end
  return count
end
return M

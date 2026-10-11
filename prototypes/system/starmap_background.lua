-- Original static, Razi-authored galaxy artwork.
-- All layers are behind existing Space Age, PlanetsLib and source belt art.
local M={}
local layout=require("prototypes.system.galaxy_layout")
local ASSET="__razi-protocol__/graphics/starmap/razi/"
local systems={
  {name="calidus",tint={r=.98,g=.69,b=.38}},
  {name="solaris",tint={r=1,g=.52,b=.26}},
  {name="nyxaris",tint={r=.32,g=.88,b=.73}},
  {name="vibrant",tint={r=.51,g=.45,b=.99}},
  {name="vespera",tint={r=.47,g=.81,b=.97}},
  {name="beetlejuice",tint={r=.98,g=.31,b=.55}},
  {name="umbra",tint={r=.67,g=.29,b=.43}},
  {name="deep-space",tint={r=.33,g=.49,b=.88}}
}
local belts={
  {name="vibrant",tint={r=.70,g=.57,b=.96}},
  {name="vespera",tint={r=.52,g=.84,b=.98}},
  {name="umbra",tint={r=.95,g=.40,b=.59}}
}

local function option(name,default)
  local s=settings and settings.startup and settings.startup[name]
  if s==nil then return default end
  return s.value
end
local function anchor(name)
  if name=="calidus" then return 0,0 end
  if name=="deep-space" then
    return layout.anchor_position("solar-system-edge")
  end
  return layout.anchor_position(name)
end
local function insert_asset(layers,file,w,h,scale,x,y,rgb,alpha)
  layers[#layers+1]={
    type="sprite",filename=ASSET..file,size={w,h},
    scale=scale,shift={x*32,y*32},
    priority="extra-high-no-scale",flags={"gui-icon"},
    blend_mode="normal",
    tint={r=rgb.r,g=rgb.g,b=rgb.b,a=alpha}
  }
end
function M.make_layers(mode,halos,atmosphere)
  if mode~="subtle" and mode~="cinematic" then return {} end
  local cine=mode=="cinematic"
  local result={}
  -- 4 tiles cover -256..256 map units in each direction.
  for i,p in ipairs({{-128,-128},{128,-128},{-128,128},{128,128}}) do
    insert_asset(result,"sky-"..i..".png",1024,1024,8,p[1],p[2],
      {r=.93,g=.97,b=1},cine and .90 or .60)
  end
  -- Connect the star systems without covering their orbit/route labels.
  insert_asset(result,"galactic-current.png",768,384,9,0,-9,
    {r=.33,g=.56,b=.78},cine and .54 or .24)
  if halos~=false then
    for _,s in ipairs(systems) do
      local x,y=anchor(s.name)
      if x and y then
        insert_asset(result,"glow-"..s.name..".png",512,512,7,x,y,s.tint,
          cine and .74 or .40)
      end
    end
  end
  if atmosphere~=false then
    for _,b in ipairs(belts) do
      local x,y=anchor(b.name)
      if x and y then
        insert_asset(result,"belt-"..b.name..".png",512,512,6,x,y,b.tint,
          cine and .70 or .34)
      end
    end
  end
  return result
end
function M.data_final_fixes()
  local mode=option("razi-starmap-background-style","subtle")
  if mode=="off" then return end
  if mode~="subtle" and mode~="cinematic" then return end
  -- Avoid two simultaneous sky wallpapers; neither source art nor
  -- the external mod is ever mutated when both are installed.
  if mods and mods["Better_Starmap_Background"] then
    if type(log)=="function" then
      log("[Razi Protocol/starmap-art] Skipped for Better_Starmap_Background")
    end
    return
  end
  local utility=(data.raw["utility-sprites"] or {}).default
  local sprite=utility and utility.starmap_star
  if not (sprite and type(sprite.layers)=="table") then
    if type(log)=="function" then
      log("[Razi Protocol/starmap-art] Layered star sprite unavailable")
    end
    return
  end
  for _,layer in ipairs(sprite.layers) do
    if layer.filename==ASSET.."sky-1.png" then return end
  end
  local new=M.make_layers(mode,
    option("razi-starmap-system-halos",true),
    option("razi-starmap-belt-atmosphere",true))
  -- Prepend in natural order. Native belts, authored star graphics and
  -- subsequent risk-coloured route guides remain ABOVE these textures.
  for i=#new,1,-1 do table.insert(sprite.layers,1,new[i]) end
  if type(log)=="function" then
    log("[Razi Protocol/starmap-art] "..#new.." backdrop layers: "..mode)
  end
end
M.systems=systems
M.belts=belts
return M

-- A calm galactic atlas. Soft system light, a few distant stars, and
-- optional single belt rings; no stitched tiles, repeating portals or swirls.
local M={}
local layout=require("prototypes.system.galaxy_layout")
local ASSET="__razi-protocol__/graphics/starmap/razi/"
local systems={
  {name="calidus",tint={r=1,g=.72,b=.47},strength=.62},
  {name="solaris",tint={r=1,g=.51,b=.30},strength=.84},
  {name="nyxaris",tint={r=.37,g=.82,b=.69},strength=.79},
  {name="vibrant",tint={r=.55,g=.56,b=.94},strength=.85},
  {name="vespera",tint={r=.61,g=.78,b=.96},strength=.77},
  {name="beetlejuice",tint={r=.94,g=.43,b=.64},strength=.80},
  {name="umbra",tint={r=.66,g=.35,b=.55},strength=.66},
  {name="deep-space",tint={r=.40,g=.57,b=.82},strength=.48}
}
local belts={
  {name="vibrant",tint={r=.75,g=.66,b=.93},scale=24},
  {name="vespera",tint={r=.59,g=.78,b=.93},scale=17},
  {name="umbra",tint={r=.91,g=.57,b=.68},scale=17}
}
local WHITE={r=1,g=1,b=1}
local function option(name,default)
  local value=settings and settings.startup and settings.startup[name]
  if value==nil then return default end
  return value.value
end
local function anchor(name)
  if name=="calidus" then return 0,0 end
  return layout.anchor_position(name=="deep-space"
    and "solar-system-edge" or name)
end
local function insert_asset(layers,file,scale,x,y,color,alpha)
  layers[#layers+1]={
    type="sprite",filename=ASSET..file,size={128,128},
    scale=scale,shift={x*32,y*32},
    priority="extra-high-no-scale",flags={"gui-icon"},
    blend_mode="normal",
    tint={r=color.r,g=color.g,b=color.b,a=alpha}
  }
end
function M.make_layers(mode,halos,atmosphere,details,cartography)
  if mode~="subtle" and mode~="cinematic" then return {} end
  local cinematic=mode=="cinematic"
  local layers={}
  if halos~=false then
    for _,system in ipairs(systems) do
      local x,y=anchor(system.name)
      if x and y then
        insert_asset(layers,"atlas-halo.png",
          system.name=="calidus" and 9.8 or 13,
          x,y,system.tint,(cinematic and .81 or .58)*system.strength)
      end
    end
  end
  if halos~=false then
    local fx,fy=layout.anchor_position("razi-calidus-drift")
    if fx and fy then
      insert_asset(layers,"atlas-halo.png",2.4,fx,fy,
        {r=1,g=.75,b=.50},cinematic and .20 or .12)
    end
  end
  if atmosphere~=false then
    for _,belt in ipairs(belts) do
      local x,y=anchor(belt.name)
      if x and y then
        insert_asset(layers,"atlas-belt.png",belt.scale,x,y,
          belt.tint,cinematic and .48 or .30)
      end
    end
  end
  if details~=false then
    -- These specks inhabit otherwise empty margins, not travel lanes.
    if option("razi-starmap-galactic-ornaments",true) then
      local pockets={
        {-169,-18,{r=.58,g=.74,b=.91}},
        {162,47,{r=.71,g=.58,b=.87}},
        {9,-254,{r=.55,g=.68,b=.89}},
        {-7,161,{r=.82,g=.68,b=.48}},
        -- Broad, transparent dust pockets fill the otherwise empty gaps
        -- without drawing a fake portal, orbit or route.
        {0,56,{r=.54,g=.71,b=.83},.55},
        {0,-59,{r=.62,g=.59,b=.84},.55},
        {60,-31,{r=.60,g=.58,b=.89},.55},
        {-63,-33,{r=.59,g=.77,b=.85},.55}
      }
      for _,p in ipairs(pockets) do
        insert_asset(layers,"atlas-dust.png",20,p[1],p[2],p[3],
          (cinematic and .72 or .49)*(p[4] or 1))
      end
    end
    if option("razi-starmap-micro-details",true) then
      for _,name in ipairs({"nyxaris","vespera","umbra","vibrant"}) do
        local x,y=anchor(name)
        if x and y then
          insert_asset(layers,"atlas-dust.png",10,x+41,y-33,
            WHITE,cinematic and .38 or .26)
        end
      end
    end
  end
  if cartography==true then
    -- An optional star pocket, never another fake orbit/connection.
    insert_asset(layers,"atlas-dust.png",13,0,-42,WHITE,.42)
  end
  return layers
end
function M.data_final_fixes()
  local mode=option("razi-starmap-background-style","subtle")
  if mode~="subtle" and mode~="cinematic" then return end
  if mods and mods["Better_Starmap_Background"] then return end
  local utility=(data.raw["utility-sprites"] or {}).default
  local sprite=utility and utility.starmap_star
  if not (sprite and type(sprite.layers)=="table") then return end
  -- An integration pass may be repeated: never stack duplicate art.
  for _,layer in ipairs(sprite.layers) do
    if layer.filename==ASSET.."atlas-halo.png"
      or layer.filename==ASSET.."atlas-belt.png"
      or layer.filename==ASSET.."atlas-dust.png" then return end
  end
  local new=M.make_layers(mode,
    option("razi-starmap-system-halos",true),
    option("razi-starmap-belt-atmosphere",true),
    option("razi-starmap-fine-details",true),
    option("razi-starmap-cartography",false))
  for i=#new,1,-1 do table.insert(sprite.layers,1,new[i]) end
  if type(log)=="function" then
    log("[Razi Protocol/starmap-art] Clean atlas "..#new.." layers ("..mode..")")
  end
end
M.systems=systems
M.belts=belts
return M

-- Galaxy backdrop and stellar detail layers.
-- Draw these behind the map's routes and other mods' orbit artwork.
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
-- Quiet, handcrafted background pockets around each system's far side.
-- Relative offsets follow the stellar anchors when the galaxy is relocated.
-- These are NOT waypoints, planets or charted routes.
local micro_scenes={
  {name="calidus",dx=-48,dy=-49,cluster=1},
  {name="solaris",dx=41,dy=43,cluster=2},
  {name="nyxaris",dx=-43,dy=42,cluster=3},
  {name="vibrant",dx=53,dy=-34,cluster=2},
  {name="vespera",dx=-53,dy=-34,cluster=1},
  {name="beetlejuice",dx=43,dy=-41,cluster=3},
  {name="umbra",dx=-43,dy=-41,cluster=2},
  {name="deep-space",dx=52,dy=-16,cluster=1}
}
-- Sparse distant signals brighten the blank corners without tracing lines.
local distant_sparks={
  {185,35,1,{r=.48,g=.77,b=.96}},
  {-190,33,2,{r=.75,g=.53,b=.87}},
  {31,191,3,{r=.91,g=.62,b=.41}},
  {-25,-223,1,{r=.53,g=.61,b=.98}}
}
-- Decorative belt-adjacent fragments. Main hazard rings and the native
-- crossing guides remain authoritative and are rendered on top of these.
local belt_fragments={
  {name="vibrant",dx=30,dy=-17},
  {name="vespera",dx=19,dy=10},
  {name="umbra",dx=21,dy=-6}
}
local function insert_micro_scenery(layers,cine,halos,atmosphere)
  if halos~=false then
    for _,scene in ipairs(micro_scenes) do
      local x,y=anchor(scene.name)
      local tint
      for _,system in ipairs(systems) do
        if system.name==scene.name then tint=system.tint;break end
      end
      if x and y and tint then
        -- Translucent filament pockets and tiny distant star swarms.
        insert_asset(layers,"filament-"..scene.name..".png",512,512,2.6,
          x+scene.dx,y+scene.dy,tint,cine and .17 or .08)
        insert_asset(layers,"cluster-"..scene.cluster..".png",384,384,1.55,
          x+scene.dx+9,y+scene.dy-7,tint,cine and .16 or .075)
      end
    end
  end
  for _,spark in ipairs(distant_sparks) do
    insert_asset(layers,"cluster-"..spark[3]..".png",384,384,1.6,
      spark[1],spark[2],spark[4],cine and .14 or .065)
  end
  if atmosphere~=false then
    for _,fragment in ipairs(belt_fragments) do
      local x,y=anchor(fragment.name)
      if x and y then
        local tint
        for _,belt in ipairs(belts) do
          if belt.name==fragment.name then tint=belt.tint;break end
        end
        if tint then
          insert_asset(layers,"debris-"..fragment.name..".png",512,512,2.2,
            x+fragment.dx,y+fragment.dy,tint,cine and .21 or .115)
          insert_asset(layers,"belt-"..fragment.name..".png",512,512,2.4,
            x+fragment.dx+5,y+fragment.dy+3,tint,cine and .13 or .065)
        end
      end
    end
  end
end
function M.make_layers(mode,halos,atmosphere,details,cartography)
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
  if halos~=false and mods and mods["slp-dyson-sphere-reworked-fork"]
    and option("razi-dyson-calidus-layout",true) then
    -- Restrained stellar-engineering coronas around the home star. Reuse
    -- existing Calidus artwork; never render fake navigation route lines.
    -- Keep it behind the sun, planets and satellite orbit markers.
    insert_asset(result,"filament-calidus.png",512,512,2.7,0,0,
      {r=1,g=.64,b=.29},cine and .32 or .16)
    insert_asset(result,"chart-constellation.png",512,512,2.1,0,0,
      {r=1,g=.72,b=.40},cine and .21 or .10)
  end
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
  -- New fine-grain scenery adds structure at a smaller visual scale.
  -- These textures sit behind every source-owned planet, sun and route.
  if details~=false then
    -- Decorative, noninteractive fine-detail layers. These stay outside
    -- the busy six-system shipping lanes and reuse already-loaded textures.
    -- Never render line-shaped decorations that could resemble routes.
    if option("razi-starmap-galactic-ornaments",true) then
      local wisps={
        {x=-167,y=-85,file="dust-lane-2.png",w=768,h=384,scale=4.0,
         color={r=.36,g=.68,b=.94}},
        {x=169,y=89,file="dust-lane-2.png",w=768,h=384,scale=4.0,
         color={r=.78,g=.43,b=.72}},
        {x=-170,y=72,file="galactic-current.png",w=768,h=384,scale=3.5,
         color={r=.32,g=.64,b=.72}},
        {x=176,y=-74,file="galactic-current.png",w=768,h=384,scale=3.5,
         color={r=.63,g=.39,b=.83}}
      }
      for _,wisp in ipairs(wisps) do
        insert_asset(result,wisp.file,wisp.w,wisp.h,wisp.scale,
          wisp.x,wisp.y,wisp.color,cine and .22 or .11)
      end
      -- Smaller complementary halos add depth without painting over the
      -- source planet icons. Use the six external stars, never Calidus.
      for _,system in ipairs(systems) do
        if system.name~="calidus" and system.name~="deep-space" then
          local x,y=anchor(system.name)
          if x and y then
            insert_asset(result,"glow-"..system.name..".png",
              512,512,cine and 3.2 or 2.8,x,y,system.tint,
              cine and .18 or .09)
          end
        end
      end
      -- Fully static small-scale art, separate from the large nebula layers.
      -- Turn it off without sacrificing the existing eleven-region backdrop.
      if option("razi-starmap-micro-details",true) then
        insert_micro_scenery(result,cine,halos,atmosphere)
      end
    end
    -- A counter-flowing galaxy arm joins the six-star ring visually.
    insert_asset(result,"dust-lane-2.png",768,384,9,8,-43,
      {r=.63,g=.47,b=.78},cine and .51 or .25)
    -- Star nurseries in the outer void, away from main system markers.
    local clusters={
      {169,139,{r=.45,g=.73,b=1}},
      {-162,137,{r=.89,g=.51,b=.84}},
      {-170,-148,{r=.52,g=.86,b=.83}}
    }
    for i,cluster in ipairs(clusters) do
      insert_asset(result,"cluster-"..i..".png",384,384,6.2,
        cluster[1],cluster[2],cluster[3],cine and .60 or .40)
    end
    if halos~=false then
      for _,system in ipairs(systems) do
        local x,y=anchor(system.name)
        if x and y then
          -- Filaments are hollow at the centre to preserve stellar icons.
          insert_asset(result,"filament-"..system.name..".png",512,512,
            5,x,y,system.tint,cine and .64 or .34)
          -- Reuse the filament's texture for a very faint outer corona.
          -- Six stellar hubs gain subtle depth; Calidus and Deep Space keep
          -- their distinct native silhouettes.
          if cine or (system.name~="calidus" and system.name~="deep-space") then
            insert_asset(result,"filament-"..system.name..".png",512,512,
              cine and 6.5 or 6.15,x,y,system.tint,cine and .14 or .085)
          end
        end
      end
    end
    if atmosphere~=false then
      for _,belt in ipairs(belts) do
        local x,y=anchor(belt.name)
        if x and y then
          insert_asset(result,"debris-"..belt.name..".png",512,512,
            6,x,y,belt.tint,cine and .56 or .30)
        end
      end
    end
    local x,y=anchor("deep-space")
    if x and y then
      insert_asset(result,"rift-deep-space.png",512,512,4.7,x,y,
        {r=.48,g=.61,b=.95},cine and .58 or .32)
    end
  end
  if cartography==true then
    -- Decorative, never a navigation connection; disabled by default.
    insert_asset(result,"chart-constellation.png",512,512,16,0,0,
      {r=.51,g=.70,b=.84},cine and .25 or .17)
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
    option("razi-starmap-belt-atmosphere",true),
    option("razi-starmap-fine-details",true),
    option("razi-starmap-cartography",false))
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

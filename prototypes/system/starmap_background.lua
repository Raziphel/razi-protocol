-- Pinpoint Milky Way atlas: tiny colored stars and rare restrained sparkles;
-- no repeating portals, giant fog banks, or false navigation features.
local M={}
local layout=require("prototypes.system.galaxy_layout")
local ASSET="__razi-protocol__/graphics/starmap/razi/"
local ATMOSPHERE_SIZE=512
local systems={
  {name="calidus",tint={r=1,g=.86,b=.42},strength=.38},
  {name="solaris",tint={r=1,g=.55,b=.37},strength=.45},
  {name="nyxaris",tint={r=.37,g=.82,b=.69},strength=.79},
  {name="vibrant",tint={r=.55,g=.56,b=.94},strength=.85},
  {name="vespera",tint={r=.61,g=.78,b=.96},strength=.77},
  {name="beetlejuice",tint={r=.94,g=.43,b=.64},strength=.80},
  {name="umbra",tint={r=.66,g=.35,b=.55},strength=.66},
  {name="deep-space",tint={r=.40,g=.57,b=.82},strength=.48}
}
-- Vibrant has its own Razi-authored ring in asteroid_belt_integration.
-- Don't paint a second generic ring over its sun and orbital markers.
-- The other two belts use their existing hand-painted fragment artwork
-- at restrained opacity over the same soft atlas-belt foundation.
local belts={
  {name="vespera",tint={r=.59,g=.78,b=.93},scale=3.05,
    debris="debris-vespera.png",debris_scale=3.20,debris_alpha=.105},
  {name="umbra",tint={r=.91,g=.57,b=.68},scale=3.12,
    debris="debris-umbra.png",debris_scale=3.25,debris_alpha=.12}
}
local WHITE={r=1,g=1,b=1}
-- Four individually seeded 1024px indexed PNG textures. Mostly single-pixel
-- dots, rare three-pixel diffraction sparkles, no large blurred white blobs.
-- Six tiles per axis give a seamless static atlas without runtime updates.
local sky_tiles={
  {1,3,2,4,1,2},
  {4,2,3,1,4,3},
  {2,1,4,3,2,4},
  {3,4,1,2,3,1},
  {1,2,4,3,1,4},
  {4,3,1,2,4,2}
}
local sky_colors={{.98,.99,1},{1,.98,.95},{.95,.97,1},{1,.97,.99}}
-- The original four tile variants repeat in a 6x6 grid. Small,
-- deterministic per-cell exposure changes break up the checkerboard
-- without allocating any new textures or a runtime effect.
local sky_exposure={
  {1.00,.89,.96,.86,.98,.91},
  {.88,.97,.91,1.00,.85,.96},
  {.95,.87,1.00,.90,.96,.84},
  {.86,.98,.88,.97,.90,1.00},
  {.97,.90,.95,.85,1.00,.87},
  {.89,1.00,.86,.96,.88,.98}
}
local function add_starfield(layers,cinematic)
  for row,variants in ipairs(sky_tiles) do
    for col,variant in ipairs(variants) do
      local rgb=sky_colors[variant]
      layers[#layers+1]={
        type="sprite",filename=ASSET.."atlas-starfield-"..variant..".png",
        size={1024,1024},scale=4,
        shift={(col-3.5)*4096,(row-3.5)*4096},
        priority="extra-high-no-scale",flags={"gui-icon"},
        blend_mode="normal",
        tint={r=rgb[1],g=rgb[2],b=rgb[3],
          a=(cinematic and .88 or .70)*sky_exposure[row][col]}
      }
    end
  end
end
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
    type="sprite",filename=ASSET..file,size={ATMOSPHERE_SIZE,ATMOSPHERE_SIZE},
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
  add_starfield(layers,cinematic)
  if halos~=false then
    for _,system in ipairs(systems) do
      local x,y=anchor(system.name)
      if x and y then
        insert_asset(layers,"atlas-halo.png",
          system.name=="calidus" and 1.55
            or system.name=="solaris" and 1.78 or 2.03,
          x,y,system.tint,(cinematic and .31 or .19)*system.strength)
      end
    end
  end
  if atmosphere~=false then
    for _,belt in ipairs(belts) do
      local x,y=anchor(belt.name)
      if x and y then
        insert_asset(layers,"atlas-belt.png",belt.scale,x,y,
          belt.tint,cinematic and .21 or .115)
        insert_asset(layers,belt.debris,belt.debris_scale,x,y,
          belt.tint,belt.debris_alpha*(cinematic and 1.24 or 1))
      end
    end
  end
  if details~=false then
    -- These specks inhabit otherwise empty margins, not travel lanes.
    if option("razi-starmap-galactic-ornaments",true) then
      local pockets={
        {-169,-18,{r=.58,g=.74,b=.91},1,1},
        {162,47,{r=.71,g=.58,b=.87},1,2},
        {9,-254,{r=.55,g=.68,b=.89},1,3},
        {-7,161,{r=.82,g=.68,b=.48},1,2}
        -- Keep the busy first-frontier corridor empty: the former four
        -- huge central fog pockets covered real solar route connections.
      }
      for _,p in ipairs(pockets) do
        insert_asset(layers,"atlas-dust-"..p[5]..".png",3.50,p[1],p[2],p[3],
          (cinematic and .25 or .155)*(p[4] or 1))
      end
    end
    if option("razi-starmap-micro-details",true) then
      local accents={
        {"nyxaris",-57,18,1},
        {"vespera",-49,-44,2},
        {"umbra",52,-42,3},
        {"vibrant",51,44,2}
      }
      for _,accent in ipairs(accents) do
        local x,y=anchor(accent[1])
        if x and y then
          -- Keep these delicate fragments beyond inhabited orbital rings.
          insert_asset(layers,"atlas-dust-"..accent[4]..".png",
            1.85,x+accent[2],y+accent[3],WHITE,
            cinematic and .13 or .075)
        end
      end
    end
  end
  if cartography==true then
    -- An optional star pocket, never another fake orbit/connection.
    insert_asset(layers,"atlas-dust-2.png",2.75,0,-42,WHITE,.18)
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
    if (type(layer.filename)=="string"
    and layer.filename:find(ASSET.."atlas-starfield-",1,true)==1)
    or layer.filename==ASSET.."atlas-halo.png"
      or layer.filename==ASSET.."atlas-belt.png"
      or layer.filename==ASSET.."debris-vespera.png"
      or layer.filename==ASSET.."debris-umbra.png"
      or (type(layer.filename)=="string"
        and layer.filename:find(ASSET.."atlas-dust-",1,true)==1) then return end
  end
  local new=M.make_layers(mode,
    option("razi-starmap-system-halos",true),
    option("razi-starmap-belt-atmosphere",true),
    option("razi-starmap-fine-details",true),
    option("razi-starmap-cartography",false))
  for i=#new,1,-1 do table.insert(sprite.layers,1,new[i]) end
  if type(log)=="function" then
    log("[Razi Protocol/starmap-art] Pinpoint sky atlas "..#new.." layers ("..mode..")")
  end
end
M.systems=systems
M.belts=belts
return M

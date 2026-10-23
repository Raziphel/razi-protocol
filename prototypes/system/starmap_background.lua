-- Pinpoint Milky Way atlas: tiny colored stars and rare restrained sparkles;
-- no repeating portals, giant fog banks, or false navigation features.
local M={}
local layout=require("prototypes.system.galaxy_layout")
local ASSET="__razi-protocol__/graphics/starmap/razi/"
local ATMOSPHERE_SIZE=512
-- One low-alpha halo per system, each using its existing dedicated
-- texture instead of six identical copies of a generic atlas ring.
-- Nyxaris is sapphire, Vibrant violet, Vespera ivory, Beetlejuice green.
-- Journal accents and route sector labels follow these same identities.
local systems={
  {name="calidus",tint={r=1,g=.87,b=.53},strength=.38,radius=1.50},
  {name="solaris",art="glow-solaris.png",tint={r=1,g=.58,b=.32},strength=.34,radius=1.55},
  {name="nyxaris",art="glow-nyxaris.png",tint={r=.32,g=.63,b=1},strength=.45,radius=1.72},
  {name="vibrant",art="glow-vibrant.png",tint={r=.64,g=.47,b=1},strength=.46,radius=1.85},
  {name="vespera",art="glow-vespera.png",tint={r=.94,g=.91,b=.82},strength=.33,radius=1.55},
  -- Beetlejuice's stellar disc is electric GREEN, not magenta. Tint the
  -- dedicated soft halo to match the actual source star artwork.
  {name="beetlejuice",art="glow-beetlejuice.png",tint={r=.18,g=1,b=.28},strength=.45,radius=1.80},
  {name="umbra",art="glow-umbra.png",tint={r=.74,g=.43,b=.27},strength=.25,radius=1.48},
  {name="deep-space",tint={r=.41,g=.58,b=.81},strength=.39,radius=1.88},
  -- Quiet local ambience behind Bellicos source sprites, never a fake star.
  {name="bellicos",tint={r=.48,g=.69,b=.91},strength=.34,radius=1.45}
}
-- Vibrant renders its real belt separately; only Umbra has belt art here.
local belts={
  -- Real separately shaded asteroid fragments replace the cloudy ring.
  -- The same single 512px indexed texture follows the physical belt in
  -- Subtle and Cinematic. The old smoke layer is never displayed.
  {name="umbra",tint={r=.86,g=.81,b=.79},scale=5.62,
    art="debris-umbra.png",subtle_alpha=.53,cinematic_alpha=.67}
}
local WHITE={r=1,g=1,b=1}
-- Gently correct the actual painted stars to agree with their glows.
-- Match filenames exactly, preserving unrelated PlanetsLib orbit layers.
-- A weak-key cache makes this safe if the renderer is invoked twice.
local star_tints={
  ["__razi-protocol__/graphics/icons/NyxarisStar.png"]={r=.85,g=.77,b=1},
  ["__razi-protocol__/graphics/icons/VibrantStar.png"]={r=.94,g=.87,b=1},
  ["__razi-protocol__/graphics/icons/VesperaStar.png"]={r=1,g=.98,b=.91}
}
local tinted=setmetatable({},{__mode="k"})
function M.tint_star_art(layers)
  for _,layer in ipairs(layers or {}) do
    local desired=star_tints[layer.filename]
    if desired and not tinted[layer] then
      local original=layer.tint or WHITE
      layer.tint={
        r=(original.r or 1)*desired.r,
        g=(original.g or 1)*desired.g,
        b=(original.b or 1)*desired.b,
        a=original.a or 1
      }
      tinted[layer]=true
    end
  end
end
-- Four individually seeded 1024px indexed PNG textures. Mostly single-pixel
-- dots, rare three-pixel diffraction sparkles, no large blurred white blobs.
-- Six tiles per axis plus a northern fringe cover the rebalanced deep-space
-- expeditions; the pulsar now lives SOUTH of the initial star pair.
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
local function selected(name,default)
  local item=settings and settings.startup and settings.startup[name]
  return item and item.value or default
end
local function strength(name,levels)
  return levels[selected(name,"standard")] or 1
end
-- Dim the far-field stars slightly so native destinations and route-risk
-- ribbons keep visual priority, without adding new textures or layers.
local function add_starfield(layers,cinematic)
  local function tile(row,col,variant,exposure)
    local rgb=sky_colors[variant]
    layers[#layers+1]={
      type="sprite",filename=ASSET.."atlas-starfield-"..variant..".png",
      size={1024,1024},scale=4,
      shift={(col-3.5)*4096,(row-3.5)*4096},
      priority="extra-high-no-scale",flags={"gui-icon"},
      blend_mode="normal",
      tint={r=rgb[1],g=rgb[2],b=rgb[3],
        a=math.min(1,(cinematic and .80 or .62)*exposure*
          strength("razi-map-star-intensity",{dim=.6,standard=1,bright=1.3}))}
    }
  end
  for row,variants in ipairs(sky_tiles) do
    for col,variant in ipairs(variants) do
      tile(row,col,variant,sky_exposure[row][col])
    end
  end
  -- One additional row only, on the northern expedition side. Reuse the
  -- existing four tiny-star PNGs, with a varied tile/exposure pattern;
  -- no extra assets or engine-time effects.
  for col,variant in ipairs({3,1,4,2,3,1}) do
    tile(0,col,variant,sky_exposure[6][col]*.94)
  end
end
local function option(name,default)
  local value=settings and settings.startup and settings.startup[name]
  if value==nil then return default end
  return value.value
end
local function anchor(name)
  if name=="calidus" then return 0,0 end
  if name=="bellicos" then
    if not (mods and mods["bellicos-and-aegis"]) then return nil end
    -- One source of truth for native location, baked art and atmosphere.
    return require("prototypes.system.bellicos").pulsar_position()
  end
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
-- Cinematic is its own *static* art direction, not just a brighter Subtle.
-- Reuse the existing small, indexed assets to keep download/VRAM costs
-- flat. Sparse nearby stars, two-depth real stellar coronas and remote
-- mineral-dust pockets are all underneath actual starmap destinations.
-- No fake orbital rings, route strokes, invented stars or simulation ticks.
local cinematic_clusters={
  {"calidus",-30,-46,1,1.32,{r=1,g=.82,b=.59},.78},
  {"solaris",48,-30,2,1.35,{r=1,g=.72,b=.51},.79},
  {"nyxaris",-48,-22,3,1.28,{r=.62,g=.77,b=1},.80},
  {"vibrant",40,-50,4,1.25,{r=.83,g=.66,b=1},.81},
  {"vespera",-40,53,1,1.22,{r=1,g=.95,b=.79},.77},
  {"beetlejuice",53,-32,2,1.18,{r=.62,g=1,b=.71},.78},
  {"umbra",45,57,3,1.18,{r=1,g=.76,b=.56},.76},
  {"deep-space",-65,-20,4,1.26,{r=.70,g=.82,b=1},.75}
}
local cinematic_nebulae={
  {"solaris",-65,39,1,2.45,{r=1,g=.62,b=.42},.28},
  {"nyxaris",66,48,2,2.35,{r=.43,g=.65,b=1},.30},
  {"vibrant",-50,-64,3,2.20,{r=.74,g=.52,b=1},.30},
  {"vespera",58,-51,2,2.40,{r=.97,g=.90,b=.77},.26},
  {"umbra",-70,31,1,2.20,{r=.86,g=.53,b=.36},.28},
  {"deep-space",86,58,3,2.40,{r=.39,g=.63,b=.83},.30}
}
local function add_cluster(layers,spec)
  local x,y=anchor(spec[1])
  if not x then return end
  local tint=spec[6]
  -- 1024px source at a much smaller scale than the 4x deep starfield.
  -- It reads as locally denser distant star clusters, not large blobs.
  layers[#layers+1]={
    type="sprite",filename=ASSET.."atlas-starfield-"..spec[4]..".png",
    size={1024,1024},scale=spec[5],
    shift={(x+spec[2])*32,(y+spec[3])*32},
    priority="extra-high-no-scale",flags={"gui-icon"},
    blend_mode="normal",
    tint={r=tint.r,g=tint.g,b=tint.b,
      a=math.min(.94,spec[7]*
        strength("razi-map-star-intensity",{dim=.6,standard=1,bright=1.3}))}
  }
end
local function cinematic_composition(layers,halos,details)
  if halos~=false then
    for _,system in ipairs(systems) do
      -- Deep Space is a geographic parent, not another literal star.
      if system.name~="deep-space" then
        local x,y=anchor(system.name)
        if x and y then
          local intensity=strength("razi-map-halo-intensity",
            {faint=.5,standard=1,strong=1.45})
          -- Broad, softly colored corona behind the existing source glow.
          insert_asset(layers,system.art or "atlas-halo.png",
            system.radius*1.85,x,y,system.tint,
            math.min(.55,.21*system.strength*intensity))
          -- Compact white-hot core visually anchors the original star art.
          insert_asset(layers,"atlas-halo.png",.77,x,y,system.tint,
            math.min(.60,.44*system.strength*intensity))
        end
      end
    end
  end
  if details~=false then
    if option("razi-starmap-micro-details",true) then
      for _,cluster in ipairs(cinematic_clusters) do
        add_cluster(layers,cluster)
      end
    end
    if option("razi-starmap-galactic-ornaments",true) then
      for _,cloud in ipairs(cinematic_nebulae) do
        local x,y=anchor(cloud[1])
        if x and y then
          insert_asset(layers,"atlas-dust-"..cloud[4]..".png",
            cloud[5],x+cloud[2],y+cloud[3],cloud[6],
            math.min(.48,cloud[7]*
              strength("razi-map-dust-intensity",
                {faint=.5,standard=1,strong=1.4})))
        end
      end
    end
  end
end
M.cinematic_clusters=cinematic_clusters
M.cinematic_nebulae=cinematic_nebulae
function M.make_layers(mode,halos,atmosphere,details,cartography)
  if mode~="subtle" and mode~="cinematic" then return {} end
  local cinematic=mode=="cinematic"
  local layers={}
  add_starfield(layers,cinematic)
  if halos~=false then
    for _,system in ipairs(systems) do
      local x,y=anchor(system.name)
      if x and y then
        insert_asset(layers,system.art or "atlas-halo.png",system.radius,
          x,y,system.tint,(cinematic and .34 or .21)*system.strength*
            strength("razi-map-halo-intensity",{faint=.5,standard=1,strong=1.45}))
      end
    end
  end
  if atmosphere~=false then
    for _,belt in ipairs(belts) do
      local x,y=anchor(belt.name)
      if x and y then
        insert_asset(layers,belt.art,belt.scale,x,y,
          belt.tint,(cinematic and (belt.cinematic_alpha or .145)
            or (belt.subtle_alpha or .105))*
            strength("razi-map-belt-intensity",{faint=.5,standard=1,strong=1.4}))
        if cinematic and belt.debris then
          insert_asset(layers,belt.debris,belt.scale*1.04,x,y,
            belt.tint,belt.debris_alpha*
              strength("razi-map-belt-intensity",{faint=.5,standard=1,strong=1.4}))
        end
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
          (cinematic and .20 or .12)*(p[4] or 1)*
            strength("razi-map-dust-intensity",{faint=.5,standard=1,strong=1.4}))
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
            (cinematic and .11 or .06)*
              strength("razi-map-dust-intensity",{faint=.5,standard=1,strong=1.4}))
        end
      end
    end
  end
  if cinematic and option("razi-starmap-cinematic-extras",true) then
    cinematic_composition(layers,halos,details)
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
  M.tint_star_art(sprite.layers)
  -- An integration pass may be repeated: never stack duplicate art.
  for _,layer in ipairs(sprite.layers) do
    if (type(layer.filename)=="string"
    and layer.filename:find(ASSET.."atlas-starfield-",1,true)==1)
    or layer.filename==ASSET.."atlas-halo.png"
      or (type(layer.filename)=="string"
        and layer.filename:find(ASSET.."glow-",1,true)==1)
      or layer.filename==ASSET.."belt-umbra.png"
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

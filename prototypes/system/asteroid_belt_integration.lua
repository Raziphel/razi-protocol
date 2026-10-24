---@diagnostic disable: inject-field, need-check-nil
-- Map coordinates of Vibrant's belt rims: both stay on the western edge of the system.
local M={}
local HOST="vibrant"
local PIXELS=32
local ASSET="__razi-protocol__/graphics/starmap/razi/"
local coords={
  {"asteroid-belt-inner-edge",31,0.77},
  {"asteroid-belt-outer-edge",39,0.775}
}
M.coords=coords
function M.data_final_fixes()
  local layout=require("prototypes.system.galaxy_layout")
  local cx,cy=layout.anchor_position(HOST)
  if not cx or not cy then return end
  for _,entry in ipairs(coords) do
    local location=(data.raw["space-location"] or {})[entry[1]]
    if location then
      local radians=entry[3]*2*math.pi
      local x=cx+entry[2]*math.sin(radians)
      local y=cy-entry[2]*math.cos(radians)
      if x>=cx or x<0 or math.abs(y-cy)>10 then
        error("Razi: Vibrant belt entries are no longer on the western rim")
      end
      local distance=math.sqrt(x*x+y*y)
      local turn=0.25-math.atan(-y/x)/(2*math.pi)
      location.orbit={parent={type="space-location",name="star"},
        distance=distance,orientation=turn}
      location.origin={x=0,y=0}
      location.distance=distance
      location.orientation=turn
      location.draw_orbit=false
    end
  end
  -- Keep the orbital coordinates available for save migration even when
  -- the user switches off Razi artwork. Cosmetic settings never affect travel.
  local startup=settings and settings.startup or {}
  local mode=startup["razi-starmap-background-style"]
  local atmosphere=startup["razi-starmap-belt-atmosphere"]
  if (mode and mode.value=="off")
    or (atmosphere and atmosphere.value==false)
    or (mods and mods["Better_Starmap_Background"]) then return end
  -- Decorative native textures only. No animation, no source mod assets.
  local utility=(data.raw["utility-sprites"] or {}).default
  local star=utility and utility.starmap_star
  if not (star and type(star.layers)=="table") then return end
  -- One quiet rock band, irregular stray fragments and very faint dust.
  -- The uneven distribution and open gaps are painted into three 512px
  -- textures. Only the native Outer Rim / Inner Rim route crosses them.
  -- These are static starmap layers: no particle loops or new entities.
  local sprites={
    {name="belt-vibrant-core.png",scale=5.65,alpha=.77,
      tint={r=.87,g=.89,b=.94}},
    {name="belt-vibrant-scatter.png",scale=5.72,alpha=.44,
      tint={r=.85,g=.86,b=.91}},
    {name="belt-vibrant-dust.png",scale=5.78,alpha=.33,
      tint={r=.88,g=.90,b=.95}}
  }
  local additions={}
  for _,sprite in ipairs(sprites) do
    local filename=ASSET..sprite.name
    local already=false
    for _,layer in ipairs(star.layers) do
      if layer.filename==filename and layer.scale==sprite.scale
        and layer.shift and math.abs(layer.shift[1]-cx*PIXELS)<.01
        and math.abs(layer.shift[2]-cy*PIXELS)<.01 then
        already=true;break
      end
    end
    if not already then
      additions[#additions+1]={
        type="sprite",filename=filename,size={512,512},
        scale=sprite.scale,shift={cx*PIXELS,cy*PIXELS},
        priority="extra-high-no-scale",flags={"gui-icon"},blend_mode="normal",
        tint={r=sprite.tint.r,g=sprite.tint.g,b=sprite.tint.b,a=sprite.alpha}
      }
    end
  end
  -- Background atmospheres sit behind native stars, moons, route lines and
  -- hover targets. The generic atlas is prepended in a later graphics pass.
  for i=#additions,1,-1 do
    table.insert(star.layers,1,additions[i])
  end
end
return M

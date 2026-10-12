-- GUI-only visuals reuse original Razi starmap textures at a fraction
-- of their native size. The phase is research-based: no fake satellite count.
local root="__razi-protocol__/graphics/starmap/razi/"
local variants={
  {"survey","glow-calidus.png",{r=1,g=.69,b=.41,a=.88}},
  {"plasma","filament-calidus.png",{r=1,g=.54,b=.25,a=.90}},
  {"construction","chart-constellation.png",{r=1,g=.78,b=.52,a=.90}},
  {"distribution","filament-calidus.png",{r=.66,g=.87,b=1,a=.96}},
  {"mastery","glow-calidus.png",{r=1,g=.88,b=.62,a=1}}
}
for _,variant in ipairs(variants) do
  data:extend({{
    type="sprite",name="razi-dyson-works-"..variant[1],
    filename=root..variant[2],size=512,scale=0.25,
    flags={"gui-icon"},tint=variant[3]
  }})
end

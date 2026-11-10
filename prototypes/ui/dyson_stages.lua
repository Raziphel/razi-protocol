-- The native star map is immutable per game session. These seven
-- research-driven frames are displayed in the Stellar Works UI.
local source="__razi-protocol__/graphics/starmap/razi/calidus-dyson-stages.png"
for stage=0,6 do
  data:extend({{
    type="sprite",name="razi-dyson-works-stage-"..stage,
    filename=source,x=stage*256,y=0,size=256,scale=.5,
    flags={"gui-icon"}
  }})
end
-- Retain previous public GUI sprite names as compatibility aliases.
for name,stage in pairs({
  survey=0,plasma=2,construction=3,distribution=4,mastery=6
}) do
  data:extend({{
    type="sprite",name="razi-dyson-works-"..name,
    filename=source,x=stage*256,y=0,size=256,scale=.5,
    flags={"gui-icon"}
  }})
end

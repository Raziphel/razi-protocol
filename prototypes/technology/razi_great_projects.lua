-- RAZI-owned project hardware. One craftable, powered archive relay and
-- one source-issued freight receipt. No copied mod assets or new laboratories.
local M={}
function M.data()
  local source=data.raw.radar and data.raw.radar.radar
  if not source then return end
  local relay=table.deepcopy(source)
  relay.name="razi-archive-relay"
  relay.icon="__base__/graphics/icons/radar.png"
  relay.icon_size=64
  relay.icons=nil
  relay.minable={mining_time=.5,result="razi-archive-relay"}
  relay.energy_usage="1MW"
  relay.max_distance_of_sector_revealed=0
  relay.max_distance_of_nearby_sector_revealed=0
  relay.localised_name={"entity-name.razi-archive-relay"}
  relay.localised_description={"entity-description.razi-archive-relay"}
  local item={
    type="item",name="razi-archive-relay",
    icon="__base__/graphics/icons/radar.png",icon_size=64,
    subgroup="defensive-structure",order="z[razi]-a[archive-relay]",
    place_result="razi-archive-relay",stack_size=10
  }
  local receipt={
    type="item",name="razi-skybridge-consignment",
    icon="__base__/graphics/icons/processing-unit.png",icon_size=64,
    subgroup="intermediate-product",order="z[razi]-b[skybridge]",
    stack_size=20,hidden=true
  }
  local recipe={
    type="recipe",name="razi-archive-relay",enabled=false,
    energy_required=20,
    ingredients={
      {type="item",name="radar",amount=4},
      {type="item",name="processing-unit",amount=25},
      {type="item",name="low-density-structure",amount=20},
      {type="item",name="battery",amount=40}
    },
    results={{type="item",name="razi-archive-relay",amount=1}}
  }
  local tech={
    type="technology",name="razi-archive-array",enabled=true,
    icon="__base__/graphics/technology/radar.png",icon_size=256,
    prerequisites={"radar","space-science-pack"},
    effects={{type="unlock-recipe",recipe="razi-archive-relay"}},
    unit={count=500,time=45,ingredients={
      {"automation-science-pack",1},{"logistic-science-pack",1},
      {"chemical-science-pack",1},{"space-science-pack",1}
    }},
    order="z[razi]-m[archive-array]"
  }
  data:extend{relay,item,receipt,recipe,tech}
end
return M

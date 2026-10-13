-- Run with Lua 5.2+ from the repository root:
-- lua tests/lua/test_fluxworks_factory_preview.lua
local preview=dofile("scripts/razi_journal_recipe_preview.lua")
local recipe={name="razi-fw-vibrant-specialty",ingredients={
  {type="item",name="superconductor",amount=2},
  {type="fluid",name="fw-yellow-flux",amount=55},
},products={{name="fw-resonance-substrate",type="item",amount=3}}}
local native={prototype={effects={
  {type="unlock-recipe",recipe="razi-fw-vibrant-specialty"},
}}}
local quest={tech="razi-fw-vibrant-industry",
  recipe="razi-fw-vibrant-specialty",site="fulgora",
  optional=true,machine="fw-synthesis-plant"}
local list={[recipe.name]=recipe}
assert(preview.recipe(quest,native,list)==recipe,
  "Technology and recipe IDs must resolve independently")
assert(preview.recipe(quest,{prototype={effects={}}},list)==nil,
  "Do not show production recipes unrelated to selected research")
assert(preview.recipe(quest,native,{})==nil)
assert(preview.recipe({tech=recipe.name,site="fulgora"},
  native,list)==recipe,"Legacy source-owned same-ID recipes must work")
assert(preview.recipe({tech=recipe.name},native,list)==nil)
local hidden={name=recipe.name,hidden=true}
assert(preview.recipe(quest,native,{[recipe.name]=hidden})==nil)
assert(preview.quantity({amount=3})==" ×3")
assert(preview.quantity({amount_min=2,amount_max=5})==" ×2–5")
assert(preview.quantity({amount=4,probability=0.5})==" ×4 (50%)")
assert(preview.quantity({})=="")
print("FluxWorks factory preview: exact recipe unlock and quantities OK")

-- Numeric settings of other mods that the owner reads in its own data.lua,
-- before Razi's data.lua can change the value (see
-- foreign_difficulty_settings.lua). The prototypes the owner built from the
-- saved value are scaled by target / saved instead, only the fields that the
-- owner's code derives from that setting, and only on Easy, Hard and
-- Nightmare. Normal and Custom write nothing.
local M={}

-- Values inside the limits of each setting:
--   space-science-pack-energy                       double 0.01..60
--   muluna-balance-exploration-science-data-cost    double 1..100
--   cerys-undo-marathon-multiplier                  double 0.1..100000
M.profiles={
 easy={
  ["space-science-pack-energy"]=5,
  ["muluna-balance-exploration-science-data-cost"]=6,
  ["cerys-undo-marathon-multiplier"]=1.5,
 },
 hard={
  ["space-science-pack-energy"]=9,
  ["muluna-balance-exploration-science-data-cost"]=14,
  ["cerys-undo-marathon-multiplier"]=0.8,
 },
 nightmare={
  ["space-science-pack-energy"]=12,
  ["muluna-balance-exploration-science-data-cost"]=20,
  ["cerys-undo-marathon-multiplier"]=0.6,
 }
}

-- Cerys builds the research counts of these technologies with
-- ceil(count / saved multiplier) (prototypes/technology.lua, correct()).
-- Nothing else of Cerys, no technology of another mod.
M.cerys_technologies={
 "cerys-fulgoran-cryogenics",
 "cerys-electromagnetic-tooling",
 "cerys-mixed-oxide-waste-reprocessing",
 "cerys-lubricant-synthesis",
 "cerys-mixed-oxide-reactors",
 "cerys-radioactive-module",
 "cerys-overclock-module",
 "cerys-plutonium-weaponry",
 "cerys-advanced-structure-repair",
 "cerys-applications-of-radioactivity",
 "cerys-space-science-pack-from-methane-ice",
 "moon-discovery-cerys",
 "cerys-radiative-heaters",
 "cerys-holmium-plate-productivity-1",
 "cerys-holmium-recrystalization",
 "cerys-reactor-fuel"
}

-- The recipes that take the astronomical data of the setting
-- muluna-balance-exploration-science-data-cost: Muluna's interstellar science
-- pack and the cooling variant that Krastorio 2 Spaced Out copies from it
-- (the cubic variant has a price of its own).
M.data_cost_recipes={
 "interstellar-science-pack",
 "interstellar-science-pack-cooling"
}

-- The first value a field had, so a second call never compounds.
local originals=setmetatable({},{__mode="k"})
local function positive(x) return type(x)=="number" and x>0 and x==x and x<math.huge end
local function scale(owner,field,ratio,integer)
 if not owner or not positive(owner[field]) then return false end
 local remembered=originals[owner]
 if not remembered then remembered={};originals[owner]=remembered end
 local baseline=remembered[field]
 if baseline==nil then baseline=owner[field];remembered[field]=baseline end
 local new=baseline*ratio
 if not positive(new) then return false end
 new=integer and math.max(1,math.ceil(new-1e-9)) or math.max(.001,new)
 if new~=owner[field] then owner[field]=new;return true end
 return false
end
local function get_saved(startup,id)
 local record=startup and startup[id]
 return record and record.value
end

function M.apply(raw,startup,enabled)
 raw=raw or (data and data.raw) or {}
 startup=startup or (settings and settings.startup) or {}
 enabled=enabled or mods or {}
 local selected=get_saved(startup,"razi-difficulty-preset")
 local p=M.profiles[selected]
 local updated={recipes=0,technology=0}
 if not p then return updated end
 if enabled["planet-muluna"] then
  local science=get_saved(startup,"space-science-pack-energy")
  local recipe=raw.recipe and raw.recipe["space-science-pack"]
  if positive(science) and recipe and
      scale(recipe,"energy_required",p["space-science-pack-energy"]/science,false) then
   updated.recipes=updated.recipes+1
  end
  local oldCost=get_saved(startup,"muluna-balance-exploration-science-data-cost")
  if positive(oldCost) then
   local ratio=p["muluna-balance-exploration-science-data-cost"]/oldCost
   for _,name in ipairs(M.data_cost_recipes) do
    local lunar=raw.recipe and raw.recipe[name]
    if lunar and type(lunar.ingredients)=="table" then
     for _,ingredient in pairs(lunar.ingredients) do
      if ingredient and ingredient.type=="fluid" and
         ingredient.name=="muluna-astronomical-data" and
         scale(ingredient,"amount",ratio,false)
      then updated.recipes=updated.recipes+1 end
     end
    end
   end
  end
 end
 if enabled["Cerys-Moon-of-Fulgora"] then
  local saved=get_saved(startup,"cerys-undo-marathon-multiplier")
  if positive(saved) then
   local ratio=saved/p["cerys-undo-marathon-multiplier"]
   for _,name in ipairs(M.cerys_technologies) do
    local tech=raw.technology and raw.technology[name]
    if tech then
     if tech.unit and scale(tech.unit,"count",ratio,true) then
      updated.technology=updated.technology+1
     end
     if tech.research_trigger and
        scale(tech.research_trigger,"count",ratio,true) then
      updated.technology=updated.technology+1
     end
    end
   end
  end
 end
 local total=updated.recipes+updated.technology
 if total>0 then
  log("razi-protocol: the "..selected.." level scaled "..updated.recipes
   .." Muluna recipe fields and "..updated.technology
   .." Cerys research counts to the values of its level")
 end
 return updated
end

function M.data_final_fixes()
 return M.apply(data.raw,settings.startup,mods)
end

return M

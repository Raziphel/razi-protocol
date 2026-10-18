-- Factual, read-only production comparison for the seven 3.0 frontier
-- partnerships. Source recipes stay owned by their original mods.
-- All quantities are per alternative recipe craft, not per shipment.
local M={}
local native={
  ["razi-frontier-moshine-biometal-silicon"]={"silicon-cell","silicon-cell"},
  ["razi-frontier-gleba-photofiber"]={"carbon-fiber","carbon-fiber"},
  ["razi-frontier-castra-composite-rounds"]={"piercing-rounds-magazine","piercing-rounds-magazine"},
  ["razi-middle-fulgora-resilient-capacitors"]={"supercapacitor","supercapacitor"},
  ["razi-middle-aquilo-capacitor-controls"]={"kr-energy-control-unit","kr-energy-control-unit"},
  ["razi-middle-paracelsin-shielded-coils"]={"electric-coil","electric-coil"},
  ["razi-middle-rubia-conductive-frames"]={"craptonite-casting","craptonite-frame"}
}

local function quantities(entries)
  local result={}
  for _,entry in ipairs(entries or {}) do
    local name=entry.name or entry[1]
    local amount=entry.amount or entry[2]
    if not (type(name)=="string" and type(amount)=="number" and amount>0)
      or (entry.probability and entry.probability~=1)
      or entry.amount_min or entry.amount_max then return nil end
    local kind=entry.type=="fluid" and "fluid" or "item"
    local key=kind..":"..name
    result[key]=(result[key] or 0)+amount
  end
  return result
end
function M.compare(name,recipes)
  local spec=native[name]
  if not (spec and recipes) then return nil end
  local source,bonus_recipe=recipes[spec[1]],recipes[name]
  if not (source and bonus_recipe) then return nil end
  local old=quantities(source.products)
  local new=quantities(bonus_recipe.products)
  local old_inputs=quantities(source.ingredients)
  local new_inputs=quantities(bonus_recipe.ingredients)
  if not (old and new and old_inputs and new_inputs) then return nil end
  local product="item:"..spec[2]
  local baseline=(old[product] or 0)*4
  local premium=new[product] or 0
  if baseline<=0 or premium<=baseline then return nil end
  local gross=(premium/baseline-1)*100
  if gross>25.0001 then return nil end
  -- Never advertise a gain that is really a missing native cost/byproduct.
  for key,amount in pairs(old_inputs) do
    if (new_inputs[key] or 0)+0.0001<amount*4 then return nil end
  end
  for key,amount in pairs(old) do
    if key~=product and (new[key] or 0)+0.0001<amount*4 then return nil end
  end
  local additional={}
  for key,amount in pairs(new_inputs) do
    local extra=amount-(old_inputs[key] or 0)*4
    if extra>0 then
      local kind,item=key:match("^(%w+):(.+)$")
      additional[#additional+1]={kind=kind,name=item,amount=extra}
    end
  end
  table.sort(additional,function(a,b)
    if a.kind==b.kind then return a.name<b.name end
    return a.kind<b.kind
  end)
  return {bonus_percent=math.floor(gross+0.5),
    output=premium,baseline=baseline,additional=additional,
    native_name=spec[1]}
end
M.native=native
return M

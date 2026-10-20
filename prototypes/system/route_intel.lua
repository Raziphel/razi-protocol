-- Extra route details for the native starmap tooltip.
-- Built during the data stage, not during play.
local M={}
local hazards=require("prototypes.system.route_hazards")
local catalog=require("scripts.galactic_catalog")
local dossiers=require("prototypes.system.route_dossiers")
local quality_levels=require("scripts.razi_asteroid_difficulty")
local prefix="razi-route-intel."
local function selected(name,default)
  local item=settings and settings.startup and settings.startup[name]
  return item and item.value or default
end
local function show(name)
  return selected("razi-route-show-"..name,true)~=false
end

local function localise(key,...)
  return {prefix..key,...}
end
local function field(key,value,order)
  return {
    name=localise(key),value=value,order=order,
    show_in_tooltip=true,show_in_factoriopedia=true
  }
end

local function has_razi_fields(fields)
  for _,field_data in ipairs(fields) do
    local name=field_data.name
    if type(name)=="table" and type(name[1])=="string"
      and name[1]:sub(1,#prefix)==prefix then return true end
  end
  return false
end

function M.annotate(route)
  if not route or not route.from or not route.to then return false end
  local fields=route.custom_tooltip_fields or {}
  if has_razi_fields(fields) then return false end
  local report=hazards.inspect(route)
  local kind=hazards.kind(route)
  -- Only one difficulty exists: the campaign's ten-level quality/route
  -- ladder. Physical asteroid sizes are separate descriptive facts.
  -- Preserve source-provided tooltip fields, names, and descriptions.
  local mode=require("scripts.razi_difficulty_presets")
    .effective("razi-asteroid-difficulty-scale","balanced")
  local lo,hi=quality_levels.route_range(route,mode)
  local level_text=lo==hi and localise("quality-stage",tostring(hi))
    or localise("quality-stages",tostring(lo),tostring(hi))
  local hex=quality_levels.route_color_richtext(hi)
  -- Show the shared ten-level risk first; native route ownership,
  -- connection length, and third-party custom fields remain untouched.
  local additions={}
  if show("danger") then
    additions[#additions+1]=field("danger",
      {"","[color="..hex.."]",level_text,"[/color]"},218)
  end
  additions[#additions+1]=field("route",localise("kind-"..kind),220)
  if show("sizes") and report.largest~="none" then
    additions[#additions+1]=field("largest",
      localise("size-"..report.largest),223)
  end
  if show("salvage") and report.chunks>0 then
    additions[#additions+1]=field("salvage",
      localise("chunks-present",tostring(report.chunks)),224)
  end
  -- Factorio already renders the native Length row. Do not add a
  -- second number which may reflect a different mod's freight override.
  -- One actionable advisory at the top danger grades, not two repeated
  -- "Critical" and "Legendary" warnings from competing tier systems.
  if show("advice") and hi>=7 then
    local advice=hi>=10 and "prepare-legendary"
      or hi>=9 and "prepare-extreme" or "prepare-advanced"
    additions[#additions+1]=field("preparation",localise(advice),226)
  end
  if show("unknown") and report.unknown then
    additions[#additions+1]=field("unknown",localise("unknown-warning"),227)
  end
  if show("belts") and hazards.is_belt_crossing(route) then
    additions[#additions+1]=field("progress",localise("required-belt"),228)
  end
  -- Only describe routes with two explicitly catalogued system endpoints.
  -- Unknown third-party planets must never be assigned a guessed sector.
  local from,to=catalog.system(route.from),catalog.system(route.to)
  if show("sectors") and from~="unassigned" and to~="unassigned" then
    local desc=from==to
      and localise("inside-system",localise("system-"..from))
      or localise("across-systems",
        localise("system-"..from),localise("system-"..to))
    additions[#additions+1]=field("sector",desc,229)
  end
  if show("haul") and type(route.length)=="number" and route.length>75000 then
    additions[#additions+1]=field("haul",
      localise("haul-"..hazards.haul_class(route)),230)
  end
  local solar=quality_levels.stellar_route_tier(route)
  if solar then
    additions[#additions+1]=field("stellar",
      localise("stellar-"..solar),225)
  end
  -- A single concise, route-specific field note. No claim of ownership
  -- over source mod descriptions and no guessed notes on unknown routes.
  local dossier=dossiers.note_for(route)
  if dossier then
    additions[#additions+1]=field("dispatch",localise("dispatch-"..dossier),231)
  end
  for _,extra in ipairs(additions) do fields[#fields+1]=extra end
  route.custom_tooltip_fields=fields
  return true
end

function M.data_final_fixes()
  local option=settings and settings.startup
    and settings.startup["razi-route-intelligence"]
  if option and option.value==false then return end
  local count=0
  for _,route in pairs(data.raw["space-connection"] or {}) do
    if M.annotate(route) then count=count+1 end
  end
  if type(log)=="function" then
    log("[Razi Protocol/route-intel] enriched "..count.." native space route tooltips")
  end
end
return M

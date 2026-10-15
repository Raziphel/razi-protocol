-- Extra route details for the native starmap tooltip.
-- Built during the data stage, not during play.
local M={}
local hazards=require("prototypes.system.route_hazards")
local catalog=require("scripts.galactic_catalog")
local quality_levels=require("scripts.razi_asteroid_difficulty")
local prefix="razi-route-intel."

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
  -- Append only: route authors own their names, description and existing fields.
  -- The old tooltip included up to ten rows, even for a harmless local
  -- shuttle. Show known facts only; important combat warnings are always
  -- near the top while routine contacts stay quiet.
  local additions={
    field("route",localise("kind-"..kind),220),
    field("danger",localise("tier-"..report.tier),221)
  }
  if report.tier>=4 then
    additions[#additions+1]=field("alert",
      localise("alert-"..report.tier),222)
  end
  -- Separate quality escalation from the native five-class size warning.
  -- Show the actual Razi ladder without counting our temporary carrier
  -- asteroid entities as new threats, and preserve source mod tooltips.
  local quality_enabled=settings and settings.startup
    and settings.startup["razi-quality-asteroids"]
  if not quality_enabled or quality_enabled.value~=false then
    local mode=settings and settings.startup
      and settings.startup["razi-asteroid-difficulty-scale"]
    local lo,hi=quality_levels.route_range(route,mode and mode.value)
    if hi>=2 then
      additions[#additions+1]=field("quality-hazard",
        lo==hi and localise("quality-stage",tostring(hi))
          or localise("quality-stages",tostring(lo),tostring(hi)),231)
      if hi>=9 then additions[#additions+1]=field("quality-warning",
        localise("quality-warning"),232) end
    end
  end
  if report.tier>=3 then
    additions[#additions+1]=field("largest",
      localise("size-"..report.largest),223)
  end
  if report.chunks>0 then
    additions[#additions+1]=field("salvage",
      localise("chunks-present",tostring(report.chunks)),224)
  end
  if type(route.length)=="number" and route.length>0 then
    additions[#additions+1]=field("distance",
      localise("kilometers",tostring(route.length)),225)
  end
  if report.tier>=3 then
    additions[#additions+1]=field("preparation",
      localise("prepare-"..report.tier),226)
  end
  if report.unknown then
    additions[#additions+1]=field("unknown",localise("unknown-warning"),227)
  end
  if hazards.is_belt_crossing(route) then
    additions[#additions+1]=field("progress",localise("required-belt"),228)
  end
  -- Only describe routes with two explicitly catalogued system endpoints.
  -- Unknown third-party planets must never be assigned a guessed sector.
  local from,to=catalog.system(route.from),catalog.system(route.to)
  if from~="unassigned" and to~="unassigned" then
    local desc=from==to
      and localise("inside-system",localise("system-"..from))
      or localise("across-systems",
        localise("system-"..from),localise("system-"..to))
    additions[#additions+1]=field("sector",desc,229)
  end
  if type(route.length)=="number" and route.length>75000 then
    additions[#additions+1]=field("haul",
      localise("haul-"..hazards.haul_class(route)),230)
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

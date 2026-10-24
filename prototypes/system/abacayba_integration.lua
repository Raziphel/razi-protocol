-- Rehome the optional Abacayba infestation as Vesta's outer-Umbra moon.
-- Do not copy its planet, terrain, enemies, recipes, events or machines.
-- Source versions may evolve; every step is guarded by actual prototypes.
local M={}
local MOD="Abacayba_Moon_of_Nauvis"
local MOON_RADIUS=9.5
local MOON_TURN=0.85

local function present()
  return mods and mods[MOD]
end
function M.planet_name()
  if not present() then return nil end
  local planets=(data.raw or {}).planet or {}
  if planets.abacayba then return "abacayba" end
  -- Only fall back to an unambiguous source-specific alternate ID.
  local matches={}
  for name in pairs(planets) do
    if name:lower():find("abacayba",1,true) then
      matches[#matches+1]=name
    end
  end
  return #matches==1 and matches[1] or nil
end

local function move()
  local name=M.planet_name()
  local moon=name and (data.raw.planet or {})[name]
  local vesta=(data.raw.planet or {}).vesta
  if not (moon and vesta) then
    if present() and type(log)=="function" then
      log("[Razi Protocol/Abacayba] Planet or Vesta missing; no moon relocation")
    end
    return nil
  end
  moon.orbit=moon.orbit or {}
  -- Preserve source orbit sprites and child surface definitions.
  moon.orbit.parent={type="planet",name="vesta"}
  moon.orbit.distance=MOON_RADIUS
  moon.orbit.orientation=MOON_TURN
  moon.distance=MOON_RADIUS
  moon.orientation=MOON_TURN
  return name
end

local function reaches(techs,start,target,seen)
  if start==target then return true end
  local tech=techs[start]
  if not tech then return false end
  seen=seen or {}
  if seen[start] then return false end
  seen[start]=true
  for _,dependency in ipairs(tech.prerequisites or {}) do
    if reaches(techs,dependency,target,seen) then return true end
  end
  return false
end

-- Add Vesta's existing discovery to the actual native Abacayba unlock,
-- leaving all native effects, science prices and unlocked recipes intact.
-- Retire only the two obsolete *direct* landing gates from earlier versions.
-- Recheck after research-weaving, but never introduce a tech dependency loop.
function M.gate()
  local name=M.planet_name()
  local technologies=(data.raw or {}).technology or {}
  local host=technologies["planet-discovery-vesta"]
  if not (name and host) then return false end
  local count=0
  for technology_name,technology in pairs(technologies) do
    local unlocks=false
    for _,effect in ipairs(technology.effects or {}) do
      if effect.type=="unlock-space-location" and
        effect.space_location==name then unlocks=true break end
    end
    if unlocks then
      local requirements,seen={},{}
      for _,prerequisite in ipairs(technology.prerequisites or {}) do
        if prerequisite~="planet-discovery-aquilo"
          and prerequisite~="planet-discovery-nauvis"
          and not seen[prerequisite] then
          requirements[#requirements+1]=prerequisite
          seen[prerequisite]=true
        end
      end
      if technology_name~="planet-discovery-vesta"
        and not seen["planet-discovery-vesta"] then
        if reaches(technologies,"planet-discovery-vesta",technology_name) then
          if type(log)=="function" then
            log("[Razi Protocol/Abacayba] Cannot anchor "..technology_name..
              " behind Vesta: native research prerequisite cycle")
          end
          return false
        end
        requirements[#requirements+1]="planet-discovery-vesta"
      end
      technology.prerequisites=requirements
      count=count+1
    end
  end
  if count==0 and type(log)=="function" then
    log("[Razi Protocol/Abacayba] No native planet discovery effect found")
  end
  return count>0
end

function M.data_updates()
  return move()
end
function M.data_final_fixes()
  local name=move()
  if name then
    M.gate()
    if type(log)=="function" then
      log("[Razi Protocol/Abacayba] Rehomed "..name..
        " as Vesta moon; destination gate checked")
    end
  end
  return name
end
return M

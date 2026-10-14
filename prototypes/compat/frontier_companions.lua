-- Optional 2.1 industrial companions. Never invent source technology IDs.
-- Use source-owned unlock-recipe effects and opt-out by startup switch.
-- Retain base/source recipes, source progression and all game save IDs.
local M={}
local distributed=require("prototypes.technology.distributed_industry")
M.sources={
  rail="space-age-railway-expansion",
  shield="shield-generators"
}
local function describes(name,tech,word)
  local lower=string.lower(name)
  if lower:find(word,1,true) then return true end
  -- A mod may prefix its technology differently, but its own unlock
  -- recipes still identify the source engineering specialization.
  for _,effect in ipairs(tech.effects or {}) do
    local recipe=effect.type=="unlock-recipe" and effect.recipe
    if recipe and string.lower(recipe):find(word,1,true) then return true end
  end
  return false
end
local function rail_rule(name,tech)
  if not describes(name,tech,"locomotive") then return nil end
  if describes(name,tech,"nuclear") then
    return {tech=name,parents={"nuclear-power"},packs={"solaris-tech-card"}}
  end
  if describes(name,tech,"fusion") then
    -- First fusion train is source-owned Aquilo engineering. A later tier
    -- earns outer-system science only if a real compatible lab exists.
    if name:find("mk[345]") or name:find("tier[345]") then
      return {tech=name,parents={"beetlejuice-discovery"},
        packs={"beetlejuice-tech-card"}}
    end
    return {tech=name,parents={"planet-discovery-aquilo"},
      packs={"vespera-tech-card"}}
  end
end
local function shield_rule(name,tech)
  if describes(name,tech,"shield")
    and (describes(name,tech,"superconduct")
      or describes(name,tech,"advanced-shield")) then
    return {tech=name,parents={"planet-discovery-fulgora"},
      packs={"electromagnetic-science-pack"}}
  end
end
M.rail_rule=rail_rule
M.shield_rule=shield_rule
-- Called after the original planetary/laboratory tech authority, once.
function M.data_final_fixes()
  if not mods or not (mods[M.sources.rail] or mods[M.sources.shield])
    then return end
  local option=settings and settings.startup
    and settings.startup["razi-companion-science-weave"]
  if option and option.value==false then return end
  local raw=data.raw
  local targets={}
  for name,tech in pairs(raw.technology or {}) do
    -- Only source-verified specialist branches. Never modify base cargo
    -- bays, first space platforms, rockets, science producers or gates.
    local rule
    if mods[M.sources.rail] then rule=rail_rule(name,tech) end
    if not rule and mods[M.sources.shield] then
      rule=shield_rule(name,tech)
    end
    if rule then targets[#targets+1]=rule end
  end
  table.sort(targets,function(a,b)return a.tech<b.tech end)
  for _,rule in ipairs(targets) do
    local ok,why=distributed.apply(raw,rule)
    if type(log)=="function" then
      log("[Razi Protocol/companion-industry] "..rule.tech.." "..why)
    end
  end
end
return M

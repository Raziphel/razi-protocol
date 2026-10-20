-- Difficulty-adjusted economy, with player-owned Custom overrides.
-- No mining/entity loops; profile transformations run during data stage.
local M={}
local factors={
 ["razi-resource-frequency"]={abundant=1.35,normal=1,scarce=.75,desolate=.50},
 ["razi-resource-patch-size"]={expansive=1.40,normal=1,small=.78,tiny=.60},
 ["razi-resource-richness"]={generous=1.50,normal=1,poor=.70,meager=.45},
 ["razi-science-demand"]={light=.80,normal=1,intensive=1.50,grueling=2.0},
 ["razi-evolution-speed"]={slow=.65,normal=1,accelerated=1.25,runaway=1.70},
 ["razi-rocket-launch-cost"]={economical=.70,normal=1,costly=1.30,punishing=1.65}
}
M.factors=factors
local function factor(resolver,key,fallback)
 local value=resolver.effective(key,fallback or "normal")
 return (factors[key] or {})[value] or 1
end
function M.profile(mode,spec,resolver)
 -- The four named profiles already define resource/science/evolution
 -- factors in their map-generation balance matrix. Applying again would
 -- double penalize Nightmare. Only Custom adjusts these values separately.
 if resolver.active()~="custom" then return spec end
 spec.resource.frequency=spec.resource.frequency*
   factor(resolver,"razi-resource-frequency")
 spec.resource.size=spec.resource.size*
   factor(resolver,"razi-resource-patch-size")
 local richness=factor(resolver,"razi-resource-richness")
 spec.resource.richness=spec.resource.richness*richness
 spec.oil=spec.oil*richness
 spec.research=math.max(.001,math.min(100000,spec.research*
   factor(resolver,"razi-science-demand")))
 local evolution=factor(resolver,"razi-evolution-speed")
 for _,name in ipairs({"time_factor","destroy_factor","pollution_factor"}) do
   local value=spec.evolution[name]
   if type(value)=="number" then spec.evolution[name]=value*evolution end
 end
 return spec
end
function M.rocket_factor(resolver)
 return factor(resolver,"razi-rocket-launch-cost")
end
return M

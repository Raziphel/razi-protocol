local nexus_hyarion_conditions = {}

-- Hyarion keeps the fusion generator off its crystal air with
-- planetaris-crystalization-resistance <= 49 (data-updates.lua:41-47), but
-- Nexus' fusion-generator-mk2 is a generator of its own with its own item and
-- stands on Hyarion (crystalization 50). It takes the same limit.
local property = "planetaris-crystalization-resistance"

local function condition_on(prototype)
	for _, condition in pairs(prototype.surface_conditions or {}) do
		if condition.property == property then
			return condition
		end
	end

	return nil
end

function nexus_hyarion_conditions.data_final_fixes()
	local generators = data.raw["fusion-generator"] or {}
	local base = generators["fusion-generator"]
	local mk2 = generators["fusion-generator-mk2"]
	if not (base and mk2) then
		return
	end

	local limit = condition_on(base)
	if limit and not condition_on(mk2) then
		mk2.surface_conditions = mk2.surface_conditions or {}
		table.insert(mk2.surface_conditions, {property = property, min = limit.min, max = limit.max})
		log("[Razi Protocol/nexus-hyarion-conditions] fusion-generator-mk2 takes the crystalization limit of fusion-generator")
	end
end

return nexus_hyarion_conditions

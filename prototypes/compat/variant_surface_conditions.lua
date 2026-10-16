local variant_surface_conditions = {}

-- Copies of an entity made before another mod limited the entity miss the
-- limit and stand where the base cannot. The logistic and construction mode
-- copies of the Krastorio 2 roboports and Tellus' roboport variants miss the
-- dust condition that Arig puts on the roboport (data-updates.lua:56-61) and
-- the pressure minimum of Cerys. The copy takes the conditions of its base;
-- conditions on properties the base does not limit stay.
local roboports = {
	["roboport"] = true,
	["kr-big-roboport"] = true,
	["kr-small-roboport"] = true
}

local function by_property(conditions)
	local result = {}
	for _, condition in pairs(conditions or {}) do
		result[condition.property] = condition
	end

	return result
end

local function same(left, right)
	return left and right and left.min == right.min and left.max == right.max
end

local function sync(copy, base)
	if not copy or not base or not base.surface_conditions then
		return
	end

	local wanted = {}
	local own = by_property(copy.surface_conditions)
	local base_conditions = by_property(base.surface_conditions)
	for _, condition in ipairs(base.surface_conditions) do
		wanted[#wanted + 1] = {property = condition.property, min = condition.min, max = condition.max}
	end
	for _, condition in ipairs(copy.surface_conditions or {}) do
		if not base_conditions[condition.property] then
			wanted[#wanted + 1] = condition
		end
	end

	local changed = false
	for property, condition in pairs(by_property(wanted)) do
		changed = changed or not same(own[property], condition)
	end
	if changed then
		copy.surface_conditions = wanted
		log("[Razi Protocol/variant-surface-conditions] " .. copy.name .. " takes the surface conditions of " .. base.name)
	end
end

local function base_name_of(name)
	if name:find("^tellus%-roboport") then
		return "roboport"
	end

	return name:match("^(.+)%-logistic%-mode$") or name:match("^(.+)%-construction%-mode$") or name
end

function variant_surface_conditions.data_final_fixes()
	for name, roboport in pairs(data.raw.roboport or {}) do
		local base_name = base_name_of(name)
		if base_name ~= name and roboports[base_name] then
			sync(roboport, data.raw.roboport[base_name])
		end
	end
end

return variant_surface_conditions

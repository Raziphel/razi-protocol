local variant_surface_conditions = {}

-- Copies of an entity made before another mod limited the entity miss the
-- limit and stand where the base cannot. The logistic and construction mode
-- copies of the Krastorio 2 roboports and Tellus' roboport variants miss the
-- dust condition that Arig puts on the roboport (data-updates.lua:56-61) and
-- the pressure minimum of Cerys. The copy takes the conditions of its base;
-- conditions on properties the base does not limit stay.
--
-- The same holds for two more kinds of copy:
-- - the rigor-module assembler copies of the two recyclers miss the Ribbonia ban (mad-ai <= 0, banlist.lua:47);
-- - the minimal rails of minimalist-rails need gravity 0.1, the vanilla rails 1, so rails stood on Cerys (0.15) with
--   rail-minimal only (data-updates.lua:9-29). No rails on Cerys, as in vanilla.
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
		log("razi-protocol: " .. copy.name .. " takes the surface conditions of " .. base.name)
	end
end

local function base_name_of(name)
	if name:find("^tellus%-roboport") then
		return "roboport"
	end

	return name:match("^(.+)%-logistic%-mode$") or name:match("^(.+)%-construction%-mode$") or name
end

local function sync_roboports()
	for name, roboport in pairs(data.raw.roboport or {}) do
		local base_name = base_name_of(name)
		if base_name ~= name and roboports[base_name] then
			sync(roboport, data.raw.roboport[base_name])
		end
	end
end

local function sync_rigor_recyclers()
	for _, name in pairs({"recycler", "steam-recycler"}) do
		sync(
			data.raw["assembling-machine"] and data.raw["assembling-machine"][name .. "__rigor-module"],
			data.raw.furnace and data.raw.furnace[name]
		)
	end
end

local function sync_minimal_rails()
	for type_name, prototypes in pairs(data.raw) do
		if type_name:find("rail", 1, true) then
			for name, rail in pairs(prototypes) do
				local base_name = name:match("^(.+)%-minimal$")
				if base_name and base_name ~= name and prototypes[base_name] then
					sync(rail, prototypes[base_name])
				end
			end
		end
	end
end

function variant_surface_conditions.data_final_fixes()
	sync_roboports()
	sync_rigor_recyclers()
	sync_minimal_rails()
end

return variant_surface_conditions

-- Igrys bans the accumulator on its planet (changelog 1.5.29, Scripts/Planet/SurfaceConditions.lua:1 sets
-- igrys-magic <= 0), but only the vanilla one: the accumulators of other mods (Krastorio 2 energy storage, Nexus,
-- shchierbin and more) still stand there and undo the planet's challenge. Every buildable accumulator takes the same
-- ban. Entities of the accumulator type that do not store power for the grid keep their conditions: the planetary
-- teleporter and intergalactic transceiver of Krastorio 2 and the charging rod of Cerys.
local igrys_accumulators = {}

local not_storage = {
	["kr-planetary-teleporter"] = true,
	["kr-intergalactic-transceiver"] = true,
	["cerys-charging-rod"] = true
}

local function limits_magic(entity)
	for _, condition in pairs(entity.surface_conditions or {}) do
		if condition.property == "igrys-magic" then
			return true
		end
	end

	return false
end

function igrys_accumulators.data_final_fixes()
	if not mods["Igrys"] or not data.raw["surface-property"] or not data.raw["surface-property"]["igrys-magic"] then
		return
	end
	local vanilla = data.raw.accumulator and data.raw.accumulator["accumulator"]
	if not vanilla or not limits_magic(vanilla) then
		return
	end

	local names = {}
	for name in pairs(data.raw.accumulator) do
		names[#names + 1] = name
	end
	table.sort(names)
	for _, name in ipairs(names) do
		local entity = data.raw.accumulator[name]
		if not entity.hidden and not not_storage[name] and not limits_magic(entity) then
			local conditions = entity.surface_conditions or {}
			conditions[#conditions + 1] = {property = "igrys-magic", max = 0}
			entity.surface_conditions = conditions
			log("razi-protocol: " .. name .. " cannot be built on Igrys, like the accumulator")
		end
	end
end

return igrys_accumulators

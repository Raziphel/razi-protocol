local compat = {}

local k2_electric_drills = {
	"kr-electric-mining-drill-mk2",
	"kr-electric-mining-drill-mk3"
}

local function mining_drill(name)
	return data.raw["mining-drill"] and data.raw["mining-drill"][name]
end

local function copy_maraxsis_mining_rules(source, target)
	if not source or not target then
		return
	end

	target.collision_mask = table.deepcopy(source.collision_mask)
	target.tile_buildability_rules = table.deepcopy(source.tile_buildability_rules)
end

function compat.data_final_fixes()
	if not (mods["maraxsis"] and mods["Krastorio2-spaced-out"]) then
		return
	end

	local electric_drill = mining_drill("electric-mining-drill")
	if not electric_drill then
		return
	end

	for _, drill_name in pairs(k2_electric_drills) do
		copy_maraxsis_mining_rules(electric_drill, mining_drill(drill_name))
	end
end

return compat

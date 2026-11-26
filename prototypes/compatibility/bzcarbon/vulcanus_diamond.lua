local M = {}

-- PlanetAthos defines diamond as its resource; bzcarbon puts that resource on Vulcanus and
-- makes diamond-processing-2 wait for mining it (PlanetAthos/prototypes/diamond.lua:70-85;
-- bzcarbon/carbon-recipe.lua:657; bzcarbon/prototypes/diamond.lua:30-45).
local function mines_only_diamond(entities)
	local count = 0
	for key, entity_name in pairs(entities or {}) do
		if key ~= 1 or entity_name ~= "diamond" then
			return false
		end
		count = count + 1
	end

	return count == 1
end

local function note(message)
	if log then
		log("razi-protocol: bz: " .. message)
	end
end

function M.data_final_fixes()
	if not (mods and mods["bzcarbon"] and mods["PlanetAthos"]) then
		return
	end

	local raw = data and data.raw or {}
	local technology = raw.technology and raw.technology["diamond-processing-2"]
	local trigger = technology and technology.research_trigger
	if trigger and trigger.type == "mine-entity" and mines_only_diamond(trigger.entities)
		and raw["simple-entity"] and raw["simple-entity"]["big-volcanic-rock"] then
		technology.research_trigger = { type = "mine-entity", entities = { "big-volcanic-rock" } }
		note("diamond-processing-2 waits for big-volcanic-rock instead of diamond")
	end

	local vulcanus = (raw.planet or {}).vulcanus
	local map_gen_settings = vulcanus and vulcanus.map_gen_settings
	local autoplace_controls = map_gen_settings and map_gen_settings.autoplace_controls
	if autoplace_controls and autoplace_controls.diamond ~= nil then
		autoplace_controls.diamond = nil
		note("removed diamond from Vulcanus autoplace controls")
	end

	local autoplace_settings = map_gen_settings and map_gen_settings.autoplace_settings
	local entity_settings = autoplace_settings and autoplace_settings.entity and autoplace_settings.entity.settings
	if entity_settings and entity_settings.diamond ~= nil then
		entity_settings.diamond = nil
		note("removed diamond from Vulcanus entity autoplace settings")
	end
end

return M

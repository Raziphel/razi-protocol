-- Imersite asteroid crushing waits for Fulgora. Imersite-Asteroids opens it after production and space science
-- (technology.lua:8), but its asteroids first fly at the orbit of Fulgora and on the routes to Aquilo
-- (data-updates.lua:14, :21-22; far space in far_space_belts.lua), so the research came long before anything to crush.
-- A save that researched it earlier keeps it: Factorio does not take back research when prerequisites change.
local helpers = require("prototypes.fixes.common.progression_helpers")

local crushing_gate = {}

crushing_gate.technology = "imersite-asteroid-crushing"
crushing_gate.prerequisite = "planet-discovery-fulgora"

function crushing_gate.data_final_fixes()
	if not mods["Imersite-Asteroids"] then
		return
	end

	local crushing = helpers.technology(crushing_gate.technology)
	if not crushing or not helpers.technology_exists(crushing_gate.prerequisite) then
		return
	end

	helpers.add_prerequisite(crushing, crushing_gate.prerequisite)
	log("[Razi Protocol/imersite-crushing-gate] " .. crushing_gate.technology .. " waits for " .. crushing_gate.prerequisite)
end

return crushing_gate

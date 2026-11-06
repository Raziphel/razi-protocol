-- The Secretas recycler and Golden Science keep their scrap -> gold -> science order.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local technology = helpers.technology
local technology_has_prerequisite = helpers.technology_has_prerequisite
local add_technology_prerequisite_if_present = helpers.add_technology_prerequisite_if_present

local science_bootstrap = {}

-- Secretas mines spaceship scrap to unlock the steam recycler and its gold
-- plate recipe; crafting 20 gold plates then unlocks Golden Science.
-- Razi 2.1.85 mistakenly added golden -> steam while another overhaul added
-- steam -> golden, making a hard Factorio technology cycle.
-- Keep the source author's natural scrap -> gold -> science sequence.
local function depends_on_technology(name, ancestor, visited)
	if name == ancestor then return true end
	local target = technology(name)
	if not target then return false end
	visited = visited or {}
	if visited[name] then return false end
	visited[name] = true
	for _, prerequisite in ipairs(target.prerequisites or {}) do
		if depends_on_technology(prerequisite, ancestor, visited) then return true end
	end
	return false
end

local function restore_secretas_science_bootstrap()
	local recycler = technology("steam-recycler")
	local golden = technology("golden-science-pack")
	if not (recycler and golden) then return false end

	local gold_plate_unlock = false
	for _, effect in ipairs(recycler.effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe == "gold-plate" then
			gold_plate_unlock = true
			break
		end
	end
	local native_recycler = recycler.research_trigger
		and recycler.research_trigger.type == "mine-entity"
	local native_golden = golden.research_trigger
		and golden.research_trigger.type == "craft-item"
		and golden.research_trigger.item == "gold-plate"
	if not (native_recycler and native_golden and gold_plate_unlock) then
		-- Some compatibility overhauls replace Secretas's native triggers.
		-- An exact two-node prerequisite cycle is still an engine-stopping
		-- error: restore the known steam-first direction even in that case.
		-- Without an exact reciprocal edge, never speculate about modified
		-- third-party technologies.
		local exact_cycle =
			technology_has_prerequisite("steam-recycler", "golden-science-pack")
			and technology_has_prerequisite("golden-science-pack", "steam-recycler")
		if not exact_cycle then
			if type(log) == "function" then
				log("[Razi Protocol/Secretas] Non-native source triggers without the exact reciprocal cycle; no changes made")
			end
			return false
		end
		if type(log) == "function" then
			log("[Razi Protocol/Secretas] Source triggers changed, repairing confirmed reciprocal Golden Science/Steam Recycler prerequisites")
		end
	end

	-- This is the reversed edge introduced by another compatibility pass.
	-- Never remove Secretas discovery or unrelated research requirements.
	local removed = 0
	for index = #(recycler.prerequisites or {}), 1, -1 do
		if recycler.prerequisites[index] == "golden-science-pack" then
			table.remove(recycler.prerequisites, index)
			removed = removed + 1
		end
	end
	if depends_on_technology("steam-recycler", "golden-science-pack") then
		-- A longer reverse path remains. Do not add the Razi gate if it
		-- would still complete a circle; log this for a targeted followup.
		for index = #(golden.prerequisites or {}), 1, -1 do
			if golden.prerequisites[index] == "steam-recycler" then
				table.remove(golden.prerequisites, index)
			end
		end
		if type(log) == "function" then
			log("[Razi Protocol/Secretas] Indirect golden science -> recycler cycle detected; omitted Razi prerequisite")
		end
		return removed > 0
	end

	add_technology_prerequisite_if_present("golden-science-pack", "steam-recycler")
	if type(log) == "function" and removed > 0 then
		log("[Razi Protocol/Secretas] Repaired cyclic steam-recycler -> golden-science-pack edge; native recycler/gold science triggers preserved")
	end
	return removed > 0
end

function science_bootstrap.data_final_fixes()
	-- Do not gate the native recycler behind the science that its own
	-- gold-plate recipe enables. Repair only this known source bootstrap.
	restore_secretas_science_bootstrap()
end
science_bootstrap.restore_secretas_science_bootstrap = restore_secretas_science_bootstrap

return science_bootstrap

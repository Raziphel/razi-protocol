local M = {}
local Science = require("__razi_lib__/lib/science")

-- 248k defines these science tools in its KI and probe prototypes
-- (248k-Redux/prototypes/electronic/el_ki/el_ki_linker.lua:22,32; 248k-Redux/prototypes/fusion/fu_space_probe.lua:120).
local function lab_targets()
	local targets = {
		["biolab"] = { "fi_ki_science" },
		["kr-advanced-lab"] = { "fi_ki_science" },
		["thermodynamics-lab"] = { "fi_ki_science", "fu_ki_science", "fu_space_probe_science" },
		["pressure-lab"] = { "fi_ki_science", "fu_ki_science", "fu_space_probe_science" },
		["kr-singularity-lab"] = { "fi_ki_science", "fu_ki_science", "fu_space_probe_science" },
	}

	if not (data.raw.lab or {})["thermodynamics-lab"] then
		for _, science in ipairs({ "fu_ki_science", "fu_space_probe_science" }) do
			table.insert(targets["kr-advanced-lab"], science)
		end
	end

	return targets
end

local function note(message)
	if log then
		log("razi-protocol: 248k: " .. message)
	end
end

function M.data_final_fixes()
	if not (mods and mods["248k-Redux"]) then
		return
	end

	local labs = data.raw.lab or {}
	for lab_name, science_packs in pairs(lab_targets()) do
		local lab = labs[lab_name]
		local added = {}
		for _, science_pack in ipairs(science_packs) do
			if Science.add_lab_input(lab, science_pack) then
				added[#added + 1] = science_pack
			end
		end
		if #added > 0 then
			note(lab_name .. " accepts " .. table.concat(added, ", "))
		end
	end
end

return M

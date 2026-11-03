local corrundum_k2so_lab_inputs = {}

local obsolete_input = "xy-electrochemical-research-data"
local replacement_input = "electrochemical-science-pack"

local function item_exists(name)
	return (data.raw.item and data.raw.item[name])
		or (data.raw.tool and data.raw.tool[name])
end

function corrundum_k2so_lab_inputs.data_final_fixes()
	if not (mods["corrundum-krastorio-compatibility-plus"]
		and mods["xy-k2so-enhancements-nulls-fork"]) then
		return
	end

	-- Compatibility+ deliberately removes XY's intermediate research item.
	-- XY can leave that deleted item in omega-lab, which makes Factorio reject
	-- the complete prototype set during assignID. Preserve the intended science
	-- support by replacing it with Compatibility+'s surviving science pack.
	if item_exists(obsolete_input) or not item_exists(replacement_input) then
		return
	end

	for _, lab in pairs(data.raw.lab or {}) do
		if lab.inputs then
			local inputs = {}
			local seen = {}

			for _, input in ipairs(lab.inputs) do
				local resolved = input == obsolete_input and replacement_input or input
				if not seen[resolved] then
					inputs[#inputs + 1] = resolved
					seen[resolved] = true
				end
			end

			lab.inputs = inputs
		end
	end
end

return corrundum_k2so_lab_inputs

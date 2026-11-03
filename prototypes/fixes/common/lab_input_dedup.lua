local Collections = require("__razi_lib__/lib/collections")

local lab_input_dedup = {}

-- Planet packs frequently append their science inputs without checking whether
-- another compatibility pass already added the same pack. Duplicate lab inputs
-- are invalid in Factorio 2.1, so normalize them after every Razi compatibility
-- module has finished.
function lab_input_dedup.data_final_fixes()
	for _, lab in pairs(data.raw.lab or {}) do
		if lab.inputs then
			local unique_inputs = {}
			for _, input in ipairs(lab.inputs) do
				Collections.append_unique(unique_inputs, input)
			end
			lab.inputs = unique_inputs
		end
	end
end

return lab_input_dedup

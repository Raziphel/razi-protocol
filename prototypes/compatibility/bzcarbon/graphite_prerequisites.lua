local M = {}

-- bzcarbon adds graphite-processing through util.add_prerequisite (bzcarbon/data-util.lua:724);
-- that helper does not honor recipe-bypass, while these technologies keep their vanilla recipes.
function M.data_final_fixes()
	if not (mods and mods["bzcarbon"]) then
		return
	end

	local raw = data and data.raw or {}
	local technologies = raw.technology or {}
	for _, technology_name in ipairs({ "electronics", "steel-processing" }) do
		local technology = technologies[technology_name]
		local prerequisites = technology and technology.prerequisites
		if prerequisites then
			local removed = false
			local write_index = 1
			local original_length = #prerequisites
			for read_index = 1, original_length do
				local prerequisite = prerequisites[read_index]
				if prerequisite == "graphite-processing" then
					removed = true
				else
					if write_index ~= read_index then
						prerequisites[write_index] = prerequisite
					end
					write_index = write_index + 1
				end
			end
			if removed then
				for index = write_index, original_length do
					prerequisites[index] = nil
				end
				if log then
					log("razi-protocol: bz: " .. technology_name .. " no longer requires graphite-processing")
				end
			end
		end
	end
end

return M

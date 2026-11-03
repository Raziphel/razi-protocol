-- Technologies that use Crucible's science pack require the Crucible technology.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local add_technology_prerequisite_if_present = helpers.add_technology_prerequisite_if_present
local technology_has_ingredient = helpers.technology_has_ingredient

local pressure_science_prerequisite = {}

function pressure_science_prerequisite.data_final_fixes()
	local pressure_science_aliases = {
		"planet-crucible-science-pack",
		"high-pressure-pack",
		"high-pressure-science-pack"
	}

	for technology_name, target_technology in pairs(data.raw.technology or {}) do
		if technology_name ~= "planet-crucible-science-pack"
			and target_technology.unit
			and target_technology.unit.ingredients
			and technology_exists("planet-crucible-science-pack") then
			for _, pressure_science in ipairs(pressure_science_aliases) do
				if technology_has_ingredient(technology_name, pressure_science) then
					add_technology_prerequisite_if_present(technology_name, "planet-crucible-science-pack")
					break
				end
			end
		end
	end
end

return pressure_science_prerequisite

local rail_support_description = {}

-- planetaris-arig 1.1.47 appends its line about deep sand to the description of rail-support-foundations under the
-- misspelt key `localized_description` (data-updates.lua:64), which the game ignores: the technology shows no
-- mention of Arig. The text is moved to localised_description when nothing else has set one.
function rail_support_description.data_final_fixes()
	local technology = data.raw.technology and data.raw.technology["rail-support-foundations"]
	---@diagnostic disable-next-line: undefined-field
	local misspelt = technology and technology.localized_description
	if misspelt and technology.localised_description == nil then
		technology.localised_description = misspelt
		---@diagnostic disable-next-line: inject-field
		technology.localized_description = nil
		log("razi-protocol: rail-support-foundations shows the Arig line in its description")
	end
end

return rail_support_description

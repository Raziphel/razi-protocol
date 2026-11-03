local artillery_range = {}

-- With realistic weapons Krastorio 2 adds artillery-range +0.4 to artillery-shell-range-1
-- (prototypes/updates/base/weapons-realistic.lua:217-219), next to the vanilla +0.3: its update_ammo_effects does not
-- replace an effect that has no ammo_category (issue 721 of the Krastorio 2 repository). Krastorio2-spaced-out makes the
-- technology endless (prototypes/updates/base/technologies.lua:135), so the doubled range grows by +70 % a level. Only
-- the +0.4 of Krastorio 2 stays.
function artillery_range.data_final_fixes()
	local technology = data.raw.technology and data.raw.technology["artillery-shell-range-1"]
	local effects = technology and technology.effects or {}
	local range_effects = {}
	for index, effect in ipairs(effects) do
		if effect.type == "artillery-range" then
			range_effects[#range_effects + 1] = index
		end
	end
	if #range_effects == 2 then
		for _, index in ipairs({range_effects[2], range_effects[1]}) do
			if effects[index].modifier == 0.3 then
				table.remove(effects, index)
				log("razi-protocol: artillery-shell-range-1 keeps only the +0.4 range of Krastorio 2")
				break
			end
		end
	end
end

return artillery_range

local hidden_poles = {}

-- minimalist-rails 2.0.9 powers its electric rails through hidden poles placed under them (hidden-rail-pole and its
-- invisible copy, prototypes/hidden_poles.lua:1-80). They are copies of the small electric pole with 100 health, they
-- take damage and die on their own, leave a small pole corpse, and nothing rebuilds them: the rail line loses power at
-- that spot. The mod exempts them only from lightning (data-updates.lua:63-72). The poles become what hidden parts
-- usually are: indestructible, with no corpse and no death explosion.
local function indestructible(pole)
	if pole.corpse ~= nil or pole.dying_explosion ~= nil then
		return false
	end
	local has_flag = false
	for _, flag in pairs(pole.flags or {}) do
		has_flag = has_flag or flag == "not-repairable"
	end
	if not has_flag then
		return false
	end
	local immune = {}
	for _, resistance in pairs(pole.resistances or {}) do
		if resistance.percent == 100 then
			immune[resistance.type] = true
		end
	end
	for damage_type in pairs(data.raw["damage-type"] or {}) do
		if not immune[damage_type] then
			return false
		end
	end

	return true
end

function hidden_poles.data_final_fixes()
	for _, name in pairs({"hidden-rail-pole", "hidden-rail-pole-invisible"}) do
		local pole = data.raw["electric-pole"] and data.raw["electric-pole"][name]

		if pole and not indestructible(pole) then
			pole.corpse = nil
			pole.dying_explosion = nil
			pole.flags = pole.flags or {}
			local has_flag = false
			for _, flag in pairs(pole.flags) do
				if flag == "not-repairable" then
					has_flag = true
				end
			end
			if not has_flag then
				table.insert(pole.flags, "not-repairable")
			end
			pole.resistances = {}
			for damage_type in pairs(data.raw["damage-type"] or {}) do
				table.insert(pole.resistances, {type = damage_type, percent = 100})
			end
			log("razi-protocol: " .. name .. " is indestructible, without corpse")
		end
	end
end

return hidden_poles

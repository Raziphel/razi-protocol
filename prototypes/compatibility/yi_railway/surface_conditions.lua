local M = {}

-- Space Age keeps the vanilla locomotive and wagons off space platforms with gravity >= 1
-- (space-age/base-data-updates.lua:173-198); nuclear-steps instead lets them onto heavy space platform foundation only
-- (data-updates/rail-network-in-space.lua:21-61). YIR 1.4.0 defines rolling stock without either rule
-- (yi_railway prototypes/_loco_future.lua:5-6, prototypes/_wagon_small.lua:44-46), and Tenebris Prime copies it as
-- bioluminescent-* with only its own pressure. Every YIR train and its copies follow the rule of the vanilla prototype
-- of their type.
local train_types = { "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" }
local yir_name_patterns = {
	"^yir_",
	"^y_",
	"^bioluminescent%-yir_",
	"^bioluminescent%-y_",
}

local function has_condition(conditions, property)
	for _, condition in pairs(conditions or {}) do
		if condition.property == property then
			return true
		end
	end

	return false
end

local function has_nuclear_steps_rule(rules)
	for _, rule in pairs(rules or {}) do
		local layers = rule.colliding_tiles and rule.colliding_tiles.layers
		if layers and layers.forbid_space_train == true then
			return true
		end
	end

	return false
end

local function is_yir_train(name)
	for _, pattern in ipairs(yir_name_patterns) do
		if name:match(pattern) then
			return true
		end
	end

	return false
end

local function note(message)
	if log then
		log("razi-protocol: yi_railway: " .. message)
	end
end

function M.data_final_fixes()
	if not (mods and mods["yi_railway"]) then
		return
	end

	local raw = data.raw
	for _, train_type in ipairs(train_types) do
		local prototypes = raw[train_type] or {}
		local vanilla = prototypes[train_type]
		local nuclear_steps = vanilla and not has_condition(vanilla.surface_conditions, "gravity")
			and has_nuclear_steps_rule(vanilla.tile_buildability_rules)
		local changed = 0

		if nuclear_steps then
			for name, prototype in pairs(prototypes) do
				if is_yir_train(name) then
					if prototype.tile_buildability_rules == nil then
						prototype.tile_buildability_rules = table.deepcopy(vanilla.tile_buildability_rules)
						changed = changed + 1
					else
						note(name .. " already has tile buildability rules, left as is")
					end
				end
			end

			if changed > 0 then
				note(train_type .. ": the nuclear-steps space train rule for " .. changed .. " prototypes")
			end
		else
			local gravity = raw["surface-property"] and raw["surface-property"].gravity
			if gravity then
				for name, prototype in pairs(prototypes) do
					if is_yir_train(name) then
						if has_condition(prototype.surface_conditions, "gravity") then
							note(name .. " already has a gravity condition, left as is")
						else
							prototype.surface_conditions = prototype.surface_conditions or {}
							prototype.surface_conditions[#prototype.surface_conditions + 1] = {
								property = "gravity",
								min = 1,
							}
							changed = changed + 1
						end
					end
				end

				if changed > 0 then
					note(train_type .. ": gravity >= 1 for " .. changed .. " prototypes")
				end
			end
		end
	end
end

return M

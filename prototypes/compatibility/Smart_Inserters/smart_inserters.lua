-- Smart_Inserters 2.1.0 (Smart_Inserters/data-final-fixes.lua:11-29) doubles extension_speed, applies the belt-chasing setting,
-- merges the long-handed fast-replace group, and changes long-handed-inserter.next_upgrade. Renai, Panglia,
-- Tenebris, and harene add inserter copies after that pass, so the speed is divided in data-updates before SI
-- doubles it; doing this later would also halve Renai's RTThrower-inserter, whose speed is set explicitly.

local smart_inserters = {}

local MOD_NAME = "Smart_Inserters"
local GROUP_MARKER = "razi-long-handed-inserter"

local data_updates_ran = false
local inserters_before_smart_inserters = {}
local original_extension_speeds = {}
local no_belt_chasing = {}

local function clear(table_to_clear)
	for key in pairs(table_to_clear) do
		table_to_clear[key] = nil
	end
end

function smart_inserters.data_updates()
	data_updates_ran = false
	clear(inserters_before_smart_inserters)
	clear(original_extension_speeds)
	clear(no_belt_chasing)

	local version = mods and mods[MOD_NAME]
	if not version then
		return
	end
	if not string.match(version, "^2%.1%.") then
		log("razi-protocol: Smart_Inserters " .. version .. " is not 2.1.x, inserters are left as they are")
		return
	end
	data_updates_ran = true

	for name, inserter in pairs(data.raw.inserter or {}) do
		-- Smart_Inserters/scripts/si_util.lua:60-70 skips hps__ml-* prototypes.
		if string.find(name, "hps__ml-", 1, true) ~= 1 then
			inserters_before_smart_inserters[name] = true

			if type(inserter.extension_speed) == "number" then
				local original_speed = inserter.extension_speed
				original_extension_speeds[name] = original_speed
				inserter.extension_speed = original_speed / 2
				log("razi-protocol: Smart_Inserters: " .. name .. " extension_speed " .. original_speed .. " -> "
					.. inserter.extension_speed .. ", Smart_Inserters doubles it back")
			end

			if inserter.fast_replaceable_group == "long-handed-inserter" then
				inserter.fast_replaceable_group = GROUP_MARKER
				log("razi-protocol: Smart_Inserters: " .. name
					.. " fast_replaceable_group long-handed-inserter -> " .. GROUP_MARKER .. " until data-final-fixes")
			end

			if inserter.chases_belt_items == false then
				no_belt_chasing[name] = true
			end
		end
	end
end

function smart_inserters.data_final_fixes()
	if not data_updates_ran then
		return
	end

	local inserters_restored = 0
	local speed_mismatches = 0

	for name, inserter in pairs(data.raw.inserter or {}) do
		local group = inserter.fast_replaceable_group
		if type(group) == "string" and string.sub(group, 1, #GROUP_MARKER) == GROUP_MARKER then
			-- Copies created after SI can append suffixes to the group (Rabbasca api.lua:187).
			local restored_group = "long-handed-inserter" .. string.sub(group, #GROUP_MARKER + 1)
			inserter.fast_replaceable_group = restored_group
			log("razi-protocol: Smart_Inserters: " .. name .. " fast_replaceable_group " .. group .. " -> " .. restored_group)
		end

		local should_not_chase_belt_items = no_belt_chasing[name] == true
		if not should_not_chase_belt_items and not inserters_before_smart_inserters[name] then
			for original_name in pairs(no_belt_chasing) do
				if string.find(name, original_name, 1, true) then
					should_not_chase_belt_items = true
					break
				end
			end
		end
		if should_not_chase_belt_items and inserter.chases_belt_items ~= false then
			inserter.chases_belt_items = false
			log("razi-protocol: Smart_Inserters: " .. name .. " chases_belt_items back to false")
		end
	end

	for name, original_speed in pairs(original_extension_speeds) do
		local inserter = data.raw.inserter and data.raw.inserter[name]
		if inserter then
			local current_speed = inserter.extension_speed
			if type(current_speed) ~= "number" or math.abs(current_speed - original_speed) > 1e-9 then
				speed_mismatches = speed_mismatches + 1
				log("razi-protocol: Smart_Inserters: " .. name .. " extension_speed " .. tostring(current_speed)
					.. ", expected " .. original_speed)
			else
				inserters_restored = inserters_restored + 1
			end
		end
	end

	log("razi-protocol: Smart_Inserters: " .. inserters_restored .. " inserters restored, "
		.. speed_mismatches .. " speed mismatches")
end

return smart_inserters

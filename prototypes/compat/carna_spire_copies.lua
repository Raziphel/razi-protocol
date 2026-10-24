local carna_spire_copies = {}

-- Carna 0.3.24 drives its spire from two things that do not agree about which entities are spires:
--   * the surface is marked by the created_effect script "spire-mark" of ANY prototype that carries it
--     (control.lua:885-891 -> mark_surface, :327-331 -> storage.spire_marked_surfaces);
--   * storage.carnan_spire, the table the tick walks, is created only in spire_built (control.lua:344-350), and only
--     for the entity named "carnan-spire" (:346).
-- Once the carnan-spire technology is researched, on_nth_tick(600) (control.lua:927-935) runs run_spire_tick on every
-- marked surface, and pairs(storage.carnan_spire) at control.lua:372 raises "table expected, got nil" while no real
-- spire was ever built. That is a fatal error of the whole game, repeated every ten seconds, and removing the entity
-- does not help: the surface stays marked.
-- Mods that copy every assembling machine copy the spire with its created_effect: Tenebris Prime
-- (bioluminescent-carnan-spire, craftable by the player) and Rabbasca (harene-infused-carnan-spire). Building a copy
-- therefore ends the game. A copy cannot be a spire (spire_built ignores its name), so its mark is taken off here and
-- the surface is marked only by the real one.
-- Remove this module when Carna creates storage.carnan_spire for every marked surface (or accepts the copies).

local MARK = "spire-mark"
local ORIGINAL = "carnan-spire"

local function is_mark(effect)
	return type(effect) == "table" and effect.type == "script" and effect.effect_id == MARK
end

-- A single effect has a type; a list of effects does not.
local function is_single(value)
	return value.type ~= nil
end

-- Takes the mark out of delivery[field] (one effect or a list); returns the number removed.
local function strip_field(delivery, field)
	local value = delivery[field]
	if type(value) ~= "table" then
		return 0
	end
	if is_single(value) then
		if is_mark(value) then
			delivery[field] = nil
			return 1
		end
		return 0
	end
	local removed = 0
	for index = #value, 1, -1 do
		if is_mark(value[index]) then
			table.remove(value, index)
			removed = removed + 1
		end
	end
	if removed > 0 and #value == 0 then
		delivery[field] = nil
	end
	return removed
end

-- Returns the number of marks removed and whether the delivery is left without effects.
local function strip_delivery(delivery)
	local removed = strip_field(delivery, "source_effects") + strip_field(delivery, "target_effects")
	return removed, removed > 0 and delivery.source_effects == nil and delivery.target_effects == nil
end

-- Returns the number of marks removed and whether the trigger is left without a delivery.
local function strip_trigger(trigger)
	local deliveries = trigger.action_delivery
	if type(deliveries) ~= "table" then
		return 0, false
	end
	local removed = 0
	if is_single(deliveries) then
		local count, empty = strip_delivery(deliveries)
		removed = count
		if empty then
			trigger.action_delivery = nil
		end
	else
		for index = #deliveries, 1, -1 do
			local count, empty = strip_delivery(deliveries[index])
			removed = removed + count
			if empty then
				table.remove(deliveries, index)
			end
		end
		if removed > 0 and #deliveries == 0 then
			trigger.action_delivery = nil
		end
	end
	return removed, removed > 0 and trigger.action_delivery == nil
end

-- Returns the number of marks removed from a created_effect (one trigger or a list) and whether nothing is left of it.
local function strip_created_effect(created_effect)
	if is_single(created_effect) then
		local removed, empty = strip_trigger(created_effect)
		return removed, empty
	end
	local removed = 0
	for index = #created_effect, 1, -1 do
		local count, empty = strip_trigger(created_effect[index])
		removed = removed + count
		if empty then
			table.remove(created_effect, index)
		end
	end
	return removed, removed > 0 and #created_effect == 0
end

function carna_spire_copies.data_final_fixes()
	if not (mods and mods["carna"]) then
		return
	end

	local types = {}
	for prototype_type in pairs(data.raw) do
		types[#types + 1] = prototype_type
	end
	table.sort(types)

	for _, prototype_type in ipairs(types) do
		local names = {}
		for name, prototype in pairs(data.raw[prototype_type]) do
			if name ~= ORIGINAL and type(prototype) == "table" and type(prototype.created_effect) == "table" then
				names[#names + 1] = name
			end
		end
		table.sort(names)

		for _, name in ipairs(names) do
			local prototype = data.raw[prototype_type][name]
			local removed, empty = strip_created_effect(prototype.created_effect)
			if removed > 0 then
				if empty then
					prototype.created_effect = nil
				end
				log("razi-protocol: " .. prototype_type .. " " .. name .. " no longer marks its surface as a Carna spire surface (removed "
					.. removed .. " spire-mark effect" .. (removed > 1 and "s" or "") .. ")")
			end
		end
	end
end

return carna_spire_copies

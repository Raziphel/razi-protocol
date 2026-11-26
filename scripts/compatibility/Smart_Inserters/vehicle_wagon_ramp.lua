-- Vehicle Wagon 2 sets the loading ramp vectors and pickup target (VehicleWagon2/script/loadingRamp.lua:29-35, 119-127).
-- Smart_Inserters opens its panel for every inserter (Smart_Inserters/control.lua:73-80); changing the ramp's vectors clears
-- the dummy chest target, so its void-powered inserter can move real items. Hide the panel after SI opens it;
-- destroying it would leave entries in storage.handlers (yafla/scripts/experimental/gui_builder.lua:208-214).
-- Hotkeys and pasted settings can still change the ramp. Remove this when Smart_Inserters blacklists VehicleWagon2.

local vehicle_wagon_ramp = {}

function vehicle_wagon_ramp.is_needed()
	return script.active_mods["Smart_Inserters"] ~= nil and script.active_mods["VehicleWagon2"] ~= nil
end

function vehicle_wagon_ramp.on_gui_opened(event)
	local entity = event.entity
	if not entity or not entity.valid or entity.name ~= "loading-ramp" then
		return
	end

	local player = game.get_player(event.player_index)
	if not player or not player.gui or not player.gui.relative then
		return
	end

	local panel = player.gui.relative.smart_inserters
	if panel and panel.valid then
		panel.visible = false
	end
end

function vehicle_wagon_ramp.register(events)
	if vehicle_wagon_ramp.is_needed() then
		events:on_event(defines.events.on_gui_opened, vehicle_wagon_ramp.on_gui_opened)
	end
end

return vehicle_wagon_ramp

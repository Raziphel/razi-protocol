-- The lamp that Cerys leaves behind a radiative tower.
--
-- Cerys 4.25.0 lights a radiative tower with a hidden lamp, radiative-tower-lamp-<N>, which it keeps as
-- tower.current_lamp (scripts/radiative-tower.lua:287-301). When the tower is gone it cleans up tower.lamps
-- (:140-146), a list that nothing ever fills. A tower that is mined or destroyed leaves its lamp shining for ever.
-- The lamp goes with its tower.
--
-- Cost: the handler runs only when a tower named below is removed. It looks for lamps within one tile of the tower
-- and touches no save data. A lamp already left behind by an earlier removal stays where it is.
--
-- Remove this module when Cerys destroys current_lamp together with its tower.

local tower_lamp = {}

local MOD_NAME = "Cerys-Moon-of-Fulgora"
local TOWERS = {"cerys-fulgoran-radiative-tower", "cerys-radiative-heater"}
local LAMP_PATTERN = "^radiative%-tower%-lamp%-"

-- Towers that exist in this game, or none without Cerys.
---@return string[]
local function tower_names()
	local names = {}
	if script.active_mods[MOD_NAME] and prototypes then
		for _, name in ipairs(TOWERS) do
			if prototypes.entity[name] then
				names[#names + 1] = name
			end
		end
	end
	return names
end

-- Name filters for the towers, to be joined to the filter of the event they come with. Empty without Cerys.
---@return table[]
function tower_lamp.filters()
	local filters = {}
	for _, name in ipairs(tower_names()) do
		filters[#filters + 1] = {filter = "name", name = name}
	end
	return filters
end

---@param event table an event that carries the removed tower as entity
function tower_lamp.on_tower_removed(event)
	local tower = event.entity
	if not (tower and tower.valid) then
		return
	end
	local is_tower = false
	for _, name in ipairs(TOWERS) do
		if tower.name == name then
			is_tower = true
			break
		end
	end
	if not is_tower then
		return
	end

	for _, lamp in pairs(tower.surface.find_entities_filtered({type = "lamp", position = tower.position, radius = 1})) do
		if lamp.name:find(LAMP_PATTERN) then
			log("razi-protocol: removed " .. lamp.name .. " left by " .. tower.name)
			lamp.destroy()
		end
	end
end

return tower_lamp

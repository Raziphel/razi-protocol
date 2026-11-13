-- Asteroid armor on Hard and Nightmare (startup setting razi-asteroid-resistances, a lever of the difficulty levels).
-- The size of an asteroid stays the check of the ship's weapons: big and huge ones still need rockets and railguns, so
-- the levels make every size tougher against the weapon meant for it instead of spawning bigger asteroids earlier
-- (Valent125, Razi's dev chat, 11.11.2026):
--   * every size: more percent resistance to its own damage: physical for small, medium and huge asteroids (guns,
--     railguns), explosion for big ones (rockets);
--   * medium: a small flat physical resistance, so plain gun ammo without damage research falls behind;
--   * big: a small flat explosion resistance.
-- Vanilla asteroids (space-age/prototypes/entity/asteroid.lua) have 0/10/10/10 % physical and 10 % explosion on big
-- ones, so Hard gives 10/20/20/20 % and Nightmare 20/30/30/30 %. A resistance of 100 % or more (immunity) is left as it
-- is, and percent stops at 95. Every asteroid named <size>-<kind>-asteroid gets it, those of other mods too. Runs before
-- quality_asteroids.lua, so the quality copies keep the armor of their originals.
local difficulty = require("lib.difficulty.presets")

local asteroid_resistances = {}

asteroid_resistances.levels = {
	hardened = {percent = 10, medium_physical = 1, big_explosion = 20},
	armored = {percent = 20, medium_physical = 2, big_explosion = 40},
}

-- The damage each size is meant to be stopped by.
asteroid_resistances.own_damage = {small = "physical", medium = "physical", big = "explosion", huge = "physical"}

local MAX_PERCENT = 95

---@param resistances table[]
---@param damage string
---@return table
local function entry(resistances, damage)
	for _, resistance in ipairs(resistances) do
		if resistance.type == damage then
			return resistance
		end
	end
	local resistance = {type = damage}
	resistances[#resistances + 1] = resistance
	return resistance
end

---@param resistance table
---@param percent number
---@param decrease number
local function harden(resistance, percent, decrease)
	if (resistance.percent or 0) >= 100 then
		return false
	end
	if percent > 0 then
		resistance.percent = math.min(MAX_PERCENT, (resistance.percent or 0) + percent)
	end
	if decrease > 0 then
		resistance.decrease = (resistance.decrease or 0) + decrease
	end
	return true
end

---@return integer changed number of asteroids
function asteroid_resistances.data_final_fixes()
	local level = asteroid_resistances.levels[difficulty.effective("razi-asteroid-resistances", "standard")]
	if not level then
		return 0
	end
	local changed = 0
	for name, asteroid in pairs(data.raw.asteroid or {}) do
		local size = name:match("^(%a+)%-.+%-asteroid$")
		local damage = asteroid_resistances.own_damage[size]
		if damage then
			asteroid.resistances = asteroid.resistances or {}
			local touched = harden(entry(asteroid.resistances, damage), level.percent, 0)
			if size == "medium" then
				touched = harden(entry(asteroid.resistances, "physical"), 0, level.medium_physical) or touched
			elseif size == "big" then
				touched = harden(entry(asteroid.resistances, "explosion"), 0, level.big_explosion) or touched
			end
			if touched then
				changed = changed + 1
			end
		end
	end
	log("razi-protocol: asteroid armor: " .. changed .. " asteroids are tougher against the weapons meant for them")
	return changed
end

return asteroid_resistances

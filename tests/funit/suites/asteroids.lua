---@diagnostic disable: need-check-nil
-- The asteroid prototypes after data-final-fixes, including optional Rubia and Krastorio2 compatibility.

local function resistance(asteroid, damage)
	for _, entry in pairs(asteroid.resistances or {}) do
		if entry.type == damage then
			return entry
		end
	end
	return nil
end

return function(runner)
	runner.test("one railgun shot kills a huge asteroid on every difficulty", function()
		for name, asteroid in pairs(prototypes.entity) do
			if asteroid.type == "asteroid" and name:match("^huge%-.+%-asteroid$") then
				local kinetic = resistance(asteroid, "rubia-kinetic")
				if kinetic then
					-- Rubia's railgun deals 10,000 rubia-kinetic damage (rubia/prototypes/data-script/asteroid-update.lua:98-125).
					local damage = (10000 - (kinetic.decrease or 0)) * (1 - (kinetic.percent or 0) / 100)
					local max_health = asteroid.get_max_health()
					runner.assert(damage >= max_health,
						name .. " survives one railgun shot at " .. tostring(damage) .. " damage and " .. max_health .. " HP")
				end
			end
		end
	end)

	runner.test("K2 rockets meet the same armor as rockets on big asteroids", function()
		for name, asteroid in pairs(prototypes.entity) do
			if asteroid.type == "asteroid" and name:match("^big%-.+%-asteroid$") then
				local k2_explosion = resistance(asteroid, "kr-explosion")
				if k2_explosion then
					local explosion = resistance(asteroid, "explosion")
					runner.assert(explosion, name .. " has kr-explosion but no explosion resistance")
					if explosion then
						runner.assert(k2_explosion.percent == explosion.percent,
							name .. " has " .. tostring(k2_explosion.percent) .. "% kr-explosion resistance and "
								.. tostring(explosion.percent) .. "% explosion resistance")
					end
				end
			end
		end
	end)
end

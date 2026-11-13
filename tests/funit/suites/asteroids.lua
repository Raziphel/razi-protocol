---@diagnostic disable: need-check-nil
-- The asteroid prototypes after data-final-fixes, including optional Rubia and Krastorio2 compatibility.

-- Runtime LuaEntityPrototype.resistances is a damage-type dictionary; percent is a 0-1 fraction.
local function resistance(asteroid, damage)
	return asteroid.resistances and asteroid.resistances[damage]
end

return function(runner)
	runner.test("one railgun shot kills a huge asteroid on every difficulty", function()
		local checked = 0
		for name, asteroid in pairs(prototypes.entity) do
			if asteroid.type == "asteroid" and name:match("^huge%-.+%-asteroid$") then
				local kinetic = resistance(asteroid, "rubia-kinetic")
				if kinetic then
					local max_health = asteroid.get_max_health()
					if max_health <= 5000 then
						checked = checked + 1
						-- Rubia's railgun deals 10,000 rubia-kinetic damage.
						-- huge-metallic_dense and huge-promethium have 10,000 HP and need two shots on Normal.
						local damage = (10000 - (kinetic.decrease or 0)) * (1 - (kinetic.percent or 0))
						runner.assert(damage >= max_health,
							name .. " survives one railgun shot at " .. tostring(damage) .. " damage and " .. max_health .. " HP")
					end
				end
			end
		end
		runner.assert(checked > 0, "no huge asteroid with rubia-kinetic: the test checks nothing")
	end)

	runner.test("K2 rockets meet the same armor as rockets on big asteroids", function()
		local checked = 0
		for name, asteroid in pairs(prototypes.entity) do
			if asteroid.type == "asteroid" and name:match("^big%-.+%-asteroid$") then
				local k2_explosion = resistance(asteroid, "kr-explosion")
				local explosion = resistance(asteroid, "explosion")
				if k2_explosion and explosion then
					checked = checked + 1
					runner.assert(math.abs(k2_explosion.percent - explosion.percent) < 1e-6,
						name .. " has " .. tostring(k2_explosion.percent) .. " kr-explosion and "
							.. tostring(explosion.percent) .. " explosion resistance")
				end
			end
		end
		runner.assert(checked > 0,
			"no big asteroid with both kr-explosion and explosion: the test checks nothing")
	end)
end

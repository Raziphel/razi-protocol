local boss_spidertrons = {}

-- The spidertron bosses of Big-Monsters 2.2.1 (bm-spidertron_1..5) are copies of the player's spidertron
-- (prototypes/entities.lua:626-641) that the mod spawns for the enemy force (control.lua:719-724). Left as the copy
-- is, a player who reaches one can sit in it and take it over with its rockets, or mine it for a spidertron. The flying
-- saucer boss of mferrari_lib 0.7.7 is a copy of the same vehicle and takes no passengers and is not minable
-- (prototypes/flying_saucer.lua:56, 64); the spidertron bosses take the same two values. The mod is not changed; only
-- these two values are set here, from this mod.
function boss_spidertrons.data_final_fixes()
	for name, spider in pairs(data.raw["spider-vehicle"] or {}) do
		if name:find("^bm%-spidertron_%d+$") and (spider.allow_passengers ~= false or spider.minable ~= nil) then
			spider.allow_passengers = false
			spider.minable = nil
			log("razi-protocol: " .. name .. " takes no passengers and cannot be mined")
		end
	end
end

return boss_spidertrons

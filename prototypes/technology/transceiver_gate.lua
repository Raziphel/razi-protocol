local gate_technology = "razi-intergalactic-transceiver-signal"

if data.raw.technology and data.raw.technology[gate_technology] then
	return
end

-- This is our "phone home" gate. K2SO handles the giant power sink and swaps
-- the entity when it fires; control.lua backs it up for old saves/script weirdness.
data:extend({
	{
		type = "technology",
		name = gate_technology,
		localised_name = {"technology-name.razi-intergalactic-transceiver-signal"},
		icon = "__Krastorio2Assets__/technologies/intergalactic-transceiver.png",
		icon_size = 256,
		essential = true,
		prerequisites = {"razi-stable-intergalactic-singularity"},
		research_trigger = {
			type = "build-entity",
			entity = "kr-activated-intergalactic-transceiver"
		}
	}
})

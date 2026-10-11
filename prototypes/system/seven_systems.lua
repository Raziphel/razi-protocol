-- Seven-system galaxy: two new stellar regions and deliberate orbital spacing.
local function location_exists(kind, name)
	return data.raw[kind] and data.raw[kind][name]
end

PlanetsLib:extend({
	{
		type = "space-location",
		name = "vespera",
		localised_name = {"space-location-name.vespera"},
		starmap_icon = "__razi-protocol__/graphics/icons/VesperaStar.png",
		starmap_icon_size = 1024,
		sprite_only = true,
		magnitude = 18,
		orbit = {
			parent = {type = "space-location", name = "star"},
			distance = 155,
			orientation = 0.40
		}
	},
	{
		type = "space-location",
		name = "sye-vespera",
		localised_name = {"space-location-name.sye-vespera"},
		icon = "__space-age__/graphics/icons/solar-system-edge.png",
		solar_power_in_space = 25,
		orbit = {
			parent = {type = "space-location", name = "vespera"},
			distance = 24,
			orientation = 0.86
		}
	},
	{
		type = "space-location",
		name = "umbra",
		localised_name = {"space-location-name.umbra"},
		starmap_icon = "__razi-protocol__/graphics/icons/UmbraStar.png",
		starmap_icon_size = 1024,
		sprite_only = true,
		magnitude = 20,
		orbit = {
			parent = {type = "space-location", name = "star"},
			distance = 220,
			orientation = 0.43
		}
	},
	{
		type = "space-location",
		name = "sye-umbra",
		localised_name = {"space-location-name.sye-umbra"},
		icon = "__space-age__/graphics/icons/solar-system-edge.png",
		solar_power_in_space = 20,
		orbit = {
			parent = {type = "space-location", name = "umbra"},
			distance = 25,
			orientation = 0.82
		}
	}
})

local updates = {
	{"space-location", "solaris", "star", 90, 0.12},
	{"space-location", "nyxaris", "star", 92, 0.36},
	{"space-location", "vibrant", "star", 153, 0.12},
	{"space-location", "beetlejuice", "star", 218, 0.11},
	-- Space Age's three original off-world planets are frontier destinations,
	-- not additional Calidus starting planets.
	{"planet", "vulcanus", "solaris", 32, 0.04},
	{"planet", "gleba", "nyxaris", 28, 0.45},
	{"planet", "fulgora", "vibrant", 27, 0.42},
	{"planet", "muria", "vespera", 17, 0.62},
	{"planet", "aquilo", "vespera", 26, 0.24},
	{"planet", "rubia", "vespera", 14, 0.34},
	{"planet", "maraxsis", "vespera", 25, 0.48},
	{"planet", "tenebris", "umbra", 19, 0.72},
	{"space-location", "crucible-orbit", "umbra", 25, 0.34},
	{"planet", "vesta", "umbra", 20, 0.10}
}

local reparent = {}
for _, entry in ipairs(updates) do
	local kind, name, parent, distance, orientation = entry[1], entry[2], entry[3], entry[4], entry[5]
	if location_exists(kind, name) then
		reparent[#reparent + 1] = {
			type = kind,
			name = name,
			distance = nil,
			orientation = nil,
			orbit = {
				parent = {type = "space-location", name = parent},
				distance = distance,
				orientation = orientation
			}
		}
	end
end

if #reparent > 0 then
	PlanetsLib:update(reparent)
end

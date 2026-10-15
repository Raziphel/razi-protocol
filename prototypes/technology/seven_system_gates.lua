-- Final pass for the seven-system research gates.
-- Earlier compatibility patches can change prerequisites, so set the
-- campaign's route order here.
local gates = {}
local Science = require("__razi_lib__/lib/science")
local Technology = require("__razi_lib__/lib/technology")

local function tech(name)
	return data.raw.technology and data.raw.technology[name]
end

local function exists(name)
	return Technology.exists(name)
end

local function reaches(start, target, visited)
	if start == target then return true end
	local node = tech(start)
	if not node then return false end
	visited = visited or {}
	if visited[start] then return false end
	visited[start] = true
	for _, parent in ipairs(node.prerequisites or {}) do
		if reaches(parent, target, visited) then return true end
	end
	return false
end

-- Keep these gate checks local instead of relying on util.lua globals.
-- Don't introduce a circular dependency if a mod moves its research.
local function add_existing_prerequisites(name, candidates)
	local target = tech(name)
	if not target then return end
	target.prerequisites = target.prerequisites or {}
	local seen = {}
	for _, parent in ipairs(target.prerequisites) do seen[parent] = true end
	for _, parent in ipairs(candidates) do
		if not seen[parent] and exists(parent)
			and parent ~= name and not reaches(parent, name) then
			target.prerequisites[#target.prerequisites + 1] = parent
			seen[parent] = true
		end
	end
end

local function ingredients_of(packs)
	local result = {}
	for _, name in ipairs(packs) do
		Science.add_pack(result, name)
	end
	return result
end

local function replace_requirements(name, prerequisites, science_packs, count)
	local t = tech(name)
	if not t then
		return
	end

	local filtered, seen = {}, {}
	for _, prerequisite in ipairs(prerequisites) do
		if exists(prerequisite) and prerequisite ~= name
			and not seen[prerequisite] and not reaches(prerequisite, name) then
			filtered[#filtered + 1] = prerequisite
			seen[prerequisite] = true
		end
	end
	t.prerequisites = filtered

	local packs = ingredients_of(science_packs)
	if #packs > 0 then
		t.research_trigger = nil
		t.unit = {
			count = count or (t.unit and t.unit.count) or 1000,
			time = 60,
			ingredients = packs
		}
	end
end


-- Singularity technology prototypes are created in data.lua, before Razi's
-- card prototypes exist. Add the cards now, once lab_cards has created them.
local function ensure_transceiver_cards(technology_name, multiplier)
	local t = tech(technology_name)
	if not (t and t.unit and t.unit.ingredients) then
		return
	end

	local existing = {}
	for _, ingredient in ipairs(t.unit.ingredients) do
		local name = ingredient.name or ingredient[1]
		existing[name] = true
	end
	for _, name in ipairs({
		"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card",
		"vibrant-tech-card", "vespera-tech-card",
		"beetlejuice-tech-card", "umbra-tech-card"
	}) do
		if Science.exists(name) and not existing[name] then
			local amount = 1
			if name == "beetlejuice-tech-card" or name == "umbra-tech-card" then
				amount = multiplier
			end
			t.unit.ingredients[#t.unit.ingredients + 1] = {name, amount}
			existing[name] = true
		end
	end
end

local calidus = {"calidus-tech-card"}
local frontier = {"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card"}
local exotic = {"solaris-tech-card", "nyxaris-tech-card"}
local outer = {"vibrant-tech-card", "vespera-tech-card"}
local finale = {"beetlejuice-tech-card", "umbra-tech-card"}

local calidus_discoveries = {"space-science-pack"}
-- Original Space Age worlds now sit at successive independent frontiers.
-- No travel gate may depend on a science pack from the planet it unlocks.
local frontier_mastery = {
	"planet-discovery-vulcanus",
	"planet-discovery-gleba",
	"planet-discovery-corrundum",
	"planet-discovery-apia-carnova",
	"planet-discovery-moshine",
	"panglia_planet_discovery_panglia"
}
local exotic_mastery = {
	"planet-discovery-fulgora",
	"planet-discovery-maraxsis"
}
local outer_mastery = {
	"planet-discovery-frozeta",
	"planet-discovery-vesta",
	"linox-technology_planet-discovery-linox"
}

local function with_gate(gate, other)
	local list = {gate}
	for _, name in ipairs(other or {}) do
		list[#list + 1] = name
	end
	return list
end

-- The Calidus slipstream is shared by both opening expeditions.
-- Opening either Solaris or Nyxaris must be sufficient to leave Nauvis.
local function ensure_unlock(discovery, location)
	local t = tech(discovery)
	if not t then return end
	t.effects = t.effects or {}
	for _, effect in ipairs(t.effects) do
		if effect.type == "unlock-space-location"
			and effect.space_location == location then return end
	end
	t.effects[#t.effects + 1] = {
		type = "unlock-space-location",
		space_location = location,
		use_icon_overlay_constant = true
	}
end

function gates.data_final_fixes()
	ensure_unlock("solaris-discovery", "sye-calidus")
	ensure_unlock("nyxaris-discovery", "sye-calidus")
	-- Every chapter hub remains tied to exactly its own system discovery.
	for _, name in ipairs({
		"solaris", "nyxaris", "vibrant", "vespera",
		"beetlejuice", "umbra"
	}) do
		ensure_unlock(name .. "-discovery", "sye-" .. name)
	end
	-- Gateway costs follow the practical expense of crafting system cards,
	-- not merely the number of packs in the research unit.
	-- Both first stars unlock using Nauvis science only. In particular, do
	-- not require metallurgic, electromagnetic, or agricultural science here.
	replace_requirements("solaris-discovery", calidus_discoveries, calidus, 650)
	replace_requirements("nyxaris-discovery", calidus_discoveries, calidus, 650)

	-- Solaris's longer required branch once charged substantially more
	-- Calidus cards than the independent Nyxaris branch. Ease later
	-- discoveries while preserving the paired entrances, native products,
	-- and Panglia's source-owned data-cell progression.
	-- Vulcanus is the Solaris industrial anchor, reached after departing Nauvis.
	-- Castra opens after Vulcanus, while Arig and Hyarion branch after Castra.
	replace_requirements("planet-discovery-vulcanus", {"solaris-discovery"}, calidus, 550)
	replace_requirements("planet-discovery-castra", {"planet-discovery-vulcanus"}, calidus, 600)
	replace_requirements("planet-discovery-arig", {"planet-discovery-castra"}, calidus, 650)
	replace_requirements("planet-discovery-hyarion", {"planet-discovery-castra"}, calidus, 650)
	replace_requirements("planet-discovery-tellus",
		{"planet-discovery-arig", "planet-discovery-hyarion"}, calidus, 800)
	replace_requirements("planet-discovery-corrundum", {"planet-discovery-tellus"}, calidus, 950)

	-- Gleba anchors Nyxaris's biological progression, alongside the two
	-- existing research destinations. Optional Dea Dia/Pelagos stay optional.
	replace_requirements("planet-discovery-gleba", {"nyxaris-discovery"}, calidus, 600)
	for _, name in ipairs({
		"planet-discovery-apia-carnova",
		"planet-discovery-moshine",
	}) do
		replace_requirements(name, {"nyxaris-discovery"}, calidus, 800)
	end
	-- Preserve Panglia\'s original data-cell science, foundry and Moshine
	-- extraction prerequisites. Replacing its science cost here would bypass
	-- its native intelligence progression and mask an impossible bootstrap.
	add_existing_prerequisites("panglia_planet_discovery_panglia", {
		"nyxaris-discovery", "planet-discovery-moshine",
		"planet-discovery-apia-carnova"
	})
	replace_requirements("system-discovery-dea-dia", {"nyxaris-discovery"}, calidus, 900)
	replace_requirements("planet-discovery-pelagos",
		{"nyxaris-discovery"}, calidus, 900)

	-- Both first-tier systems must be mastered before either next destination
	-- opens. Requiring the previous pair's cards means genuine production.
	replace_requirements("vibrant-discovery",
		with_gate("solaris-discovery", with_gate("nyxaris-discovery", frontier_mastery)),
		exotic, 1200)
	replace_requirements("vespera-discovery",
		with_gate("solaris-discovery", with_gate("nyxaris-discovery", frontier_mastery)),
		exotic, 1200)

	-- Vibrant is Fulgora's home. Electromagnetic science is obtained *inside*
	-- this tier, never from Calidus or the initial Solaris/Nyxaris entrances.
	replace_requirements("planet-discovery-fulgora", {"vibrant-discovery"}, frontier, 800)
	-- Keep Cerys with its parent Fulgora, while preserving native moon techs.
	add_existing_prerequisites("moon-discovery-cerys", {"planet-discovery-fulgora"})
	replace_requirements("planet-discovery-ribbonia", {"vibrant-discovery"}, frontier, 900)
	-- Preserve the legacy Vibrant survey ID. Razi research unlocks both
	-- Razi-owned edge waypoints; the crossing is a physical travel requirement.
	ensure_unlock("space-discovery-asteroid-belt", "asteroid-belt-inner-edge")
	ensure_unlock("space-discovery-asteroid-belt", "asteroid-belt-outer-edge")
	replace_requirements("planet-discovery-paracelsin",
		{"planet-discovery-ribbonia", "space-discovery-asteroid-belt"}, frontier, 1000)

	-- Vespera: Muria opens the survey, then two independent outer branches.
	replace_requirements("planet-discovery-muria", {"vespera-discovery"}, frontier, 900)
	replace_requirements("planet-discovery-aquilo",
		{"planet-discovery-muria", "razi-vespera-belt-survey"}, frontier, 950)
	replace_requirements("planet-discovery-rubia",
		{"planet-discovery-muria", "razi-vespera-belt-survey"}, frontier, 950)
	replace_requirements("planet-discovery-maraxsis",
		{"planet-discovery-rubia"}, frontier, 1100)

	-- The next parallel pair demands both second-tier branches.
	-- The Razi-owned Vibrant asteroid field is the shared middle-to-outer
	-- expedition gateway. Its science is now Razi-owned.
	local outer_prereqs = {
		"vibrant-discovery", "vespera-discovery",
		"space-discovery-asteroid-belt"
	}
	for _, name in ipairs(exotic_mastery) do
		outer_prereqs[#outer_prereqs + 1] = name
	end
	replace_requirements("beetlejuice-discovery", outer_prereqs, outer, 1600)
	replace_requirements("umbra-discovery", outer_prereqs, outer, 1600)

	replace_requirements("planet-discovery-cubium", {"beetlejuice-discovery"}, outer, 1100)
	replace_requirements("planet-discovery-secretas", {"planet-discovery-cubium"}, outer, 1200)
	replace_requirements("planet-discovery-frozeta", {"planet-discovery-secretas"}, outer, 1200)
	-- Preserve Linox's native landing-site tech, but anchor its discovery here.
	add_existing_prerequisites("linox-technology_planet-discovery-linox",
		{"planet-discovery-cubium"})

	replace_requirements("planet-discovery-tenebris", {"umbra-discovery"}, outer, 1100)
	replace_requirements("planet-discovery-crucible",
		{"planet-discovery-tenebris"}, outer, 1200)
	replace_requirements("planet-discovery-vesta",
		{"planet-discovery-crucible", "razi-umbra-belt-survey"}, outer, 1200)

	-- Require BOTH final branches before opening the solar-system edge.
	local final_prereqs = {"beetlejuice-discovery", "umbra-discovery"}
	for _, name in ipairs(outer_mastery) do
		final_prereqs[#final_prereqs + 1] = name
	end
	replace_requirements("razi-outer-frontier-mastery", final_prereqs, finale, 1900)
	add_existing_prerequisites("stellar-discovery-solar-system-edge",
		{"razi-outer-frontier-mastery"})
	add_existing_prerequisites("promethium-science-pack",
		{"razi-outer-frontier-mastery"})

	-- Keep the final transceiver prices proportionate to each experiment.
	ensure_transceiver_cards("razi-singularity-theory", 1)
	ensure_transceiver_cards("razi-singularity-test-fire", 2)
	ensure_transceiver_cards("razi-stable-intergalactic-singularity", 3)

	-- Old saves retain their original tech IDs; Nexus and Void remain optional
	-- endgame branches, not prerequisites for the seven-system campaign.
end

return gates

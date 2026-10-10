-- Authoritative last-stage research gates for the seven-system campaign.
-- This runs after the legacy planet passes so their rules cannot reintroduce
-- shortcuts, optional dependencies or later-chapter science requirements.
local gates = {}

local function tech(name)
	return data.raw.technology and data.raw.technology[name]
end

local function exists(name)
	return tech(name) ~= nil
end

local function ingredients_of(packs)
	local result = {}
	for _, name in ipairs(packs) do
		if science_pack_exists(name) then
			result[#result + 1] = {name, 1}
		end
	end
	return result
end

local function replace_requirements(name, prerequisites, science_packs, count)
	local t = tech(name)
	if not t then
		return
	end

	local filtered = {}
	for _, prerequisite in ipairs(prerequisites) do
		if exists(prerequisite) and prerequisite ~= name then
			filtered[#filtered + 1] = prerequisite
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
		if science_pack_exists(name) and not existing[name] then
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
	"planet-discovery-shchierbin",
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
	-- Both first stars unlock using Nauvis science only. In particular, do
	-- not require metallurgic, electromagnetic, or agricultural science here.
	replace_requirements("solaris-discovery", calidus_discoveries, calidus, 1000)
	replace_requirements("nyxaris-discovery", calidus_discoveries, calidus, 1000)

	-- Vulcanus is the Solaris industrial anchor, reached after departing Nauvis.
	-- Castra opens after Vulcanus, while Arig and Hyarion branch after Castra.
	replace_requirements("planet-discovery-vulcanus", {"solaris-discovery"}, calidus, 550)
	replace_requirements("planet-discovery-castra", {"planet-discovery-vulcanus"}, calidus, 600)
	replace_requirements("planet-discovery-arig", {"planet-discovery-castra"}, calidus, 750)
	replace_requirements("planet-discovery-hyarion", {"planet-discovery-castra"}, calidus, 750)
	replace_requirements("planet-discovery-tellus",
		{"planet-discovery-arig", "planet-discovery-hyarion"}, calidus, 900)
	replace_requirements("planet-discovery-corrundum", {"planet-discovery-tellus"}, calidus, 1100)

	-- Gleba anchors Nyxaris's biological progression, alongside the three
	-- existing research destinations. Optional Dea Dia/Pelagos stay optional.
	replace_requirements("planet-discovery-gleba", {"nyxaris-discovery"}, calidus, 600)
	for _, name in ipairs({
		"planet-discovery-apia-carnova",
		"planet-discovery-moshine",
		"panglia_planet_discovery_panglia"
	}) do
		replace_requirements(name, {"nyxaris-discovery"}, calidus, 850)
	end
	replace_requirements("system-discovery-dea-dia", {"nyxaris-discovery"}, calidus, 900)
	replace_requirements("planet-discovery-pelagos",
		{"panglia_planet_discovery_panglia"}, calidus, 900)

	-- Both first-tier systems must be mastered before either next destination
	-- opens. Requiring the previous pair's cards means genuine production.
	replace_requirements("vibrant-discovery",
		with_gate("solaris-discovery", with_gate("nyxaris-discovery", frontier_mastery)),
		exotic, 1500)
	replace_requirements("vespera-discovery",
		with_gate("solaris-discovery", with_gate("nyxaris-discovery", frontier_mastery)),
		exotic, 1500)

	-- Vibrant is Fulgora's home. Electromagnetic science is obtained *inside*
	-- this tier, never from Calidus or the initial Solaris/Nyxaris entrances.
	replace_requirements("planet-discovery-fulgora", {"vibrant-discovery"}, frontier, 800)
	-- Keep Cerys with its parent Fulgora, while preserving native moon techs.
	add_existing_prerequisites("moon-discovery-cerys", {"planet-discovery-fulgora"})
	replace_requirements("planet-discovery-ribbonia", {"vibrant-discovery"}, frontier, 900)
	replace_requirements("planet-discovery-paracelsin",
		{"planet-discovery-ribbonia"}, frontier, 900)
	replace_requirements("planet-discovery-shchierbin",
		{"planet-discovery-paracelsin"}, frontier, 900)

	-- Vespera: Muria is the beginning of the Aquilo/Rubia/Maraxsis branch.
	replace_requirements("planet-discovery-muria", {"vespera-discovery"}, frontier, 900)
	replace_requirements("planet-discovery-aquilo",
		{"planet-discovery-muria"}, frontier, 950)
	replace_requirements("planet-discovery-rubia",
		{"planet-discovery-aquilo", "razi-vespera-belt-survey"}, frontier, 950)
	replace_requirements("planet-discovery-maraxsis",
		{"planet-discovery-rubia"}, frontier, 1100)

	-- The next parallel pair demands both second-tier branches.
	local outer_prereqs = {"vibrant-discovery", "vespera-discovery"}
	for _, name in ipairs(exotic_mastery) do
		outer_prereqs[#outer_prereqs + 1] = name
	end
	replace_requirements("beetlejuice-discovery", outer_prereqs, outer, 1900)
	replace_requirements("umbra-discovery", outer_prereqs, outer, 1900)

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
	replace_requirements("razi-outer-frontier-mastery", final_prereqs, finale, 2200)
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

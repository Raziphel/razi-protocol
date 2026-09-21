local science_tiers = {
	base = {
		"automation-science-pack",
		"logistic-science-pack",
		"military-science-pack",
		"chemical-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"metallurgic-science-pack",
		"electromagnetic-science-pack",
		"agricultural-science-pack",
		"lithium-science-pack",
		"tungsten-science-pack"
	},
	inner_system = {
		"lunar-science-pack",
		"interstellar-science-pack",
		"advanced-space-science-pack",
		"cerysian-science-pack"
	},
	solaris = {
		"battlefield-science-pack",
		"planetaris-compression-science-pack",
		"planetaris-polishing-science-pack",
		"planetaris-bioengineering-science-pack",
		"planetaris-pathological-science-pack",
		"planetaris-refraction-science-pack",
		"electrochemical-science-pack"
	},
	dea_dia_nyxaris = {
		"aerospace-science-pack",
		"dea-dia-science-pack",
		"insulation-science-pack",
		"thermodynamic-science-pack",
		"nuclear-science-pack",
		"apicultural-science-pack",
		"pelagos-science-pack",
	},
	vibrant = {
		"ribbonia-alien-science-pack",
		"biorecycling-science-pack",
		"rubia-biofusion-science-pack",
		"galvanization-science-pack",
		"paracelsin-galvanization-science-pack",
		"hydraulic-science-pack"
	},
	beetlejuice = {
		"bioluminescent-science-pack",
		"cryogenic-science-pack",
		"gas-manipulation-science-pack",
		"planet-crucible-science-pack",
		"golden-science-pack",
		"promethium-science-pack"
	},
	nexus_early = {
		"deep-space-tech-card",
		"promethium-882-science-pack"
	},
	nexus = {
		"antimatter-science-pack"
	},
	deep_space = {
		"space-logistic-science-pack",
		"pulsar-science-pack",
		"void-science-pack",
		"voidp-void-science-pack"
	}
}

local tier_order = {
	"base",
	"inner_system",
	"solaris",
	"dea_dia_nyxaris",
	"vibrant",
	"beetlejuice",
	"nexus_early",
	"nexus",
	"deep_space"
}

local system_card_by_tier = {
	base = "calidus-tech-card",
	inner_system = "calidus-tech-card",
	solaris = "solaris-tech-card",
	dea_dia_nyxaris = "nyxaris-tech-card",
	vibrant = "vibrant-tech-card",
	beetlejuice = "beetlejuice-tech-card",
	nexus_early = "deep-space-tech-card"
}

local system_tech_cards = {
	"calidus-tech-card",
	"solaris-tech-card",
	"nyxaris-tech-card",
	"vibrant-tech-card",
	"beetlejuice-tech-card"
}

local transceiver_gate_technology = "razi-intergalactic-transceiver-signal"

local function add_tier_science(ingredients, tier_name, prefer_card, skip_tier_packs)
	local system_card = system_card_by_tier[tier_name]
	if prefer_card and system_card and science_pack_exists(system_card) then
		add_unique_science_pack_if_exists(ingredients, system_card)
		return
	end

	if skip_tier_packs then
		return
	end

	add_existing_science_packs(ingredients, science_tiers[tier_name])
end

local function build_science_through(tier_name, options)
	options = options or {}
	local ingredients = {}

	for _, current_tier_name in ipairs(tier_order) do
		local is_target_tier = current_tier_name == tier_name
		local prefer_card = not options.disable_cards and (options.compress_target_tier or not is_target_tier)
		add_tier_science(ingredients, current_tier_name, prefer_card, options.only_system_cards)
		if current_tier_name == tier_name then
			break
		end
	end

	return ingredients
end

local function build_science_after(tier_name)
	return build_science_through(tier_name, {compress_target_tier = true, only_system_cards = true})
end

local function build_solar_system_edge_science()
	return build_science_after("beetlejuice")
end

local function set_science_through(technology_name, tier_name)
	set_technology_unit_ingredients_if_exists(technology_name, build_science_through(tier_name))
end

local function set_science_after(technology_name, tier_name)
	set_technology_unit_ingredients_if_exists(technology_name, build_science_after(tier_name))
end

local function set_many_science_through(technology_names, tier_name)
	for _, technology_name in ipairs(technology_names) do
		set_science_through(technology_name, tier_name)
	end
end

local function set_many_science_after(technology_names, tier_name)
	for _, technology_name in ipairs(technology_names) do
		set_science_after(technology_name, tier_name)
	end
end

local regular_lab_names = {
	"lab",
	"kr-advanced-lab",
	"biolab",
	"kr-singularity-lab",
	"thermodynamics-lab",
	"pressure-lab"
}

local function add_science_to_labs(science_packs)
	for _, lab_name in ipairs(regular_lab_names) do
		local lab = data.raw.lab and data.raw.lab[lab_name]
		if lab and lab.inputs then
			-- Several planet compatibility layers append their packs independently.
			-- Factorio rejects duplicate lab inputs, so keep the first occurrence
			-- before adding Razi Protocol's cross-system packs.
			local unique_inputs = {}
			local seen_inputs = {}
			for _, lab_input in ipairs(lab.inputs) do
				if not seen_inputs[lab_input] then
					unique_inputs[#unique_inputs + 1] = lab_input
					seen_inputs[lab_input] = true
				end
			end
			lab.inputs = unique_inputs

			for _, science_pack in ipairs(science_packs) do
				if science_pack_exists(science_pack) and not science_pack_is_lab_protected(science_pack) then
					if not seen_inputs[science_pack] then
						table.insert(lab.inputs, science_pack)
						seen_inputs[science_pack] = true
					end
				end
			end
		end
	end
end

-- System discoveries always inherit every science pack produced by earlier systems.
set_prerequisites_if_exists("solaris-discovery", {
	"planet-discovery-vulcanus",
	"planet-discovery-fulgora",
	"planet-discovery-gleba"
})
set_technology_unit_ingredients_if_exists(
	"solaris-discovery",
	build_science_through("base", {disable_cards = true})
)

set_prerequisites_if_exists("nyxaris-discovery", {"planet-discovery-corrundum"})
set_science_after("nyxaris-discovery", "solaris")

set_prerequisites_if_exists("vibrant-discovery", {"nyxaris-discovery"})
set_science_after("vibrant-discovery", "dea_dia_nyxaris")

set_prerequisites_if_exists("beetlejuice-discovery", {"vibrant-discovery"})
set_science_after("beetlejuice-discovery", "vibrant")

-- Base/inner-system planet discoveries.
set_science_through("planet-discovery-muluna", "base")
set_science_through("moon-discovery-cerys", "base")
set_many_science_through({
	"moon-discovery-eneas",
	"planet-discovery-eneas"
}, "base")
add_first_existing_prerequisite("moon-discovery-eneas", {
	"planet-discovery-muluna",
	"moon-discovery-cerys"
})
add_first_existing_prerequisite("planet-discovery-eneas", {
	"planet-discovery-muluna",
	"moon-discovery-cerys"
})
add_existing_prerequisites("solaris-discovery", {
	"planet-discovery-muluna"
})

-- Aegis and Bellicos form a self-contained expedition beyond the solar-system
-- edge. Gate the entrance on reaching the edge, then retain the source mod's
-- internal discovery chain and its requirement for Pulsar Science before
-- Promethium research.
set_prerequisites_if_exists("discovery-aegis-outer", {
	"stellar-discovery-solar-system-edge"
})
add_existing_prerequisites("linox-technology_planet-discovery-linox", {"planet-discovery-cubium"})
set_many_science_after({
	"linox-technology_planet-discovery-linox",
	"linox-technology_exploring-linox-landing-site"
}, "vibrant")

-- Solaris branch.
set_prerequisites_if_exists("planet-discovery-castra", {"solaris-discovery"})
set_prerequisites_if_exists("planet-discovery-arig", {"planet-discovery-castra"})
set_prerequisites_if_exists("planet-discovery-hyarion", {"planet-discovery-arig"})
set_prerequisites_if_exists("planet-discovery-tellus", {"planet-discovery-hyarion"})
set_prerequisites_if_exists("planet-discovery-corrundum", {"planet-discovery-tellus"})
-- Castra belongs after Solaris, so it should also use Calidus Tech Card instead of the full base pack set.
set_science_after("planet-discovery-castra", "base")
set_many_science_after({
	"planet-discovery-arig",
	"planet-discovery-hyarion",
	"planet-discovery-tellus",
	"planet-discovery-corrundum"
}, "inner_system")

-- Dea Dia and Nyxaris are treated as one shared tier before Vibrant.
set_prerequisites_if_exists("system-discovery-dea-dia", {"nyxaris-discovery"})
set_science_after("system-discovery-dea-dia", "solaris")

set_prerequisites_if_exists("planet-discovery-dea-dia", {"system-discovery-dea-dia"})
set_prerequisites_if_exists("planet-discovery-lemures", {"planet-discovery-dea-dia"})
set_prerequisites_if_exists("planet-discovery-prosephina", {"planet-discovery-dea-dia"})
set_many_science_after({
	"planet-discovery-dea-dia",
	"planet-discovery-lemures",
	"planet-discovery-prosephina"
}, "solaris")
add_existing_prerequisites("vibrant-discovery", {
	"planet-discovery-dea-dia",
	"planet-discovery-lemures",
	"planet-discovery-prosephina"
})

-- Nyxaris branch.
set_prerequisites_if_exists("planet-discovery-apia-carnova", {"nyxaris-discovery"})
set_prerequisites_if_exists("planet-discovery-moshine", {"nyxaris-discovery"})
set_prerequisites_if_exists("panglia_planet_discovery_panglia", {"nyxaris-discovery"})
-- Prefer the Dea Dia branch when both optional integrations are installed,
-- otherwise let standalone Pelagos enter through Panglia and Nyxaris.
set_first_existing_prerequisite("planet-discovery-pelagos", {
	"system-discovery-dea-dia",
	"panglia_planet_discovery_panglia",
	"nyxaris-discovery"
})
set_many_science_after({
	"planet-discovery-apia-carnova",
	"planet-discovery-moshine",
	"panglia_planet_discovery_panglia",
	"planet-discovery-pelagos"
}, "solaris")
add_existing_prerequisites("vibrant-discovery", {
	"planet-discovery-apia-carnova",
	"planet-discovery-moshine",
	"panglia_planet_discovery_panglia",
	"planet-discovery-pelagos"
})

-- Vibrant branch.
if technology_exists("planet-discovery-muria") then
	set_prerequisites_if_exists("planet-discovery-muria", {"vibrant-discovery"})
end

if technology_exists("planet-discovery-shchierbin") then
	set_prerequisites_if_exists("planet-discovery-shchierbin", {"planet-discovery-paracelsin"})
end

set_prerequisites_if_exists("planet-discovery-ribbonia", {"vibrant-discovery"})
set_prerequisites_if_exists("planet-discovery-paracelsin", {"planet-discovery-ribbonia"})
set_prerequisites_if_exists("planet-discovery-aquilo", {"vibrant-discovery"})
set_prerequisites_if_exists("muriatic-science-pack", {"planet-discovery-muria"})
set_prerequisites_if_exists("vanadium-science-pack", {"planet-discovery-shchierbin"})
set_many_science_after({
	"muriatic-science-pack",
	"vanadium-science-pack"
}, "vibrant")
set_prerequisites_if_exists("planet-discovery-rubia", {"planet-discovery-aquilo"})
set_first_existing_prerequisite("planet-discovery-maraxsis", {
	"planet-discovery-rubia",
	"planet-discovery-aquilo",
	"vibrant-discovery"
})
add_existing_prerequisites("beetlejuice-discovery", {
	"planet-discovery-ribbonia",
	"planet-discovery-paracelsin",
	"planet-discovery-aquilo",
	"planet-discovery-rubia",
	"planet-discovery-maraxsis"
})

-- Beetlejuice and the road out to deep space.
set_prerequisites_if_exists("planet-discovery-cubium", {"beetlejuice-discovery"})
set_prerequisites_if_exists("planet-discovery-tenebris", {"beetlejuice-discovery"})
set_prerequisites_if_exists("planet-discovery-crucible", {"planet-discovery-tenebris"})
set_prerequisites_if_exists("planet-discovery-vesta", {"planet-discovery-crucible"})
set_prerequisites_if_exists("planet-discovery-secretas", {"planet-discovery-cubium"})
set_prerequisites_if_exists("planet-discovery-frozeta", {"planet-discovery-secretas"})
set_prerequisites_if_exists("planet-crucible-rocket-part", {"planet-crucible-science-pack"})
remove_prerequisites_if_exists("moon-discovery-cerys", {"planet-crucible-rocket-part"})
set_many_science_after({
	"planet-discovery-cubium",
	"planet-discovery-tenebris",
	"planet-discovery-crucible",
	"planet-discovery-vesta",
	"planet-discovery-secretas",
	"planet-discovery-frozeta"
}, "vibrant")

local ribbonia_discovery = data.raw.technology and data.raw.technology["planet-discovery-ribbonia"]
if ribbonia_discovery then
	ribbonia_discovery.research_trigger = nil
	ribbonia_discovery.unit = {
		count = 1500,
		ingredients = build_science_after("dea_dia_nyxaris"),
		time = 60
	}
end

local nexus_discovery_technologies = {
	"planet-discovery-nexus",
	"planet-nexus-scanning",
	"advanced-magnetic-shielding",
	"advanced-stable-electronic",
	"advanced-stronger-armor",
	"planet-nexus-scanning-Krastorio2-space-out"
}

add_existing_prerequisites("planet-nexus-scanning", {"planet-discovery-frozeta"})
add_existing_prerequisites("planet-nexus-scanning-Krastorio2-space-out", {"planet-discovery-frozeta"})
add_existing_prerequisites("planet-discovery-nexus", {"planet-discovery-frozeta"})
add_existing_prerequisites("kr-intergalactic-transceiver", {"planet-discovery-frozeta"})
add_existing_prerequisites("planet-nexus-scanning", {"planet-discovery-crucible"})
add_existing_prerequisites("planet-nexus-scanning-Krastorio2-space-out", {"planet-discovery-crucible"})
add_existing_prerequisites("planet-discovery-nexus", {"planet-discovery-crucible"})
add_existing_prerequisites("kr-intergalactic-transceiver", {"planet-discovery-crucible"})
add_existing_prerequisites("planet-nexus-scanning", {transceiver_gate_technology})
add_existing_prerequisites("planet-nexus-scanning-Krastorio2-space-out", {transceiver_gate_technology})
add_existing_prerequisites("planet-discovery-nexus", {transceiver_gate_technology})
set_many_science_after(nexus_discovery_technologies, "beetlejuice")

add_existing_prerequisites("promethium-science-pack", {"planet-discovery-frozeta"})
add_existing_prerequisites("promethium-science-pack", {"planet-discovery-crucible"})
set_technology_unit_ingredients_if_exists("promethium-science-pack", build_solar_system_edge_science())
set_science_after("promethium-882-research", "beetlejuice")
set_science_after("antimatter-science-pack", "nexus_early")
add_existing_prerequisites("starmap-mapping", {transceiver_gate_technology})

set_first_existing_prerequisite("black-hole-discovery", {
	"antimatter-science-pack",
	"promethium-882-research",
	"planet-discovery-nexus",
	"planet-nexus-scanning-Krastorio2-space-out",
	"planet-nexus-scanning"
})
set_science_through("black-hole-discovery", "nexus")
-- Only the compressed system cards need to be added by this mod.
-- Adding every science pack found in technologies makes all labs universal.
add_science_to_labs(system_tech_cards)
add_science_to_labs({"space-logistic-science-pack", "pulsar-science-pack"})

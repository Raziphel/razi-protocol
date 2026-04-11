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
	castra = {
		"battlefield-science-pack"
	},
	solaris = {
		"planetaris-compression-science-pack",
		"planetaris-polishing-science-pack",
		"planetaris-bioengineering-science-pack",
		"planetaris-pathological-science-pack",
		"planetaris-refraction-science-pack",
		"electrochemical-science-pack"
	},
	dea_dia = {
		"aerospace-science-pack",
		"dea-dia-science-pack",
		"insulation-science-pack",
		"thermodynamic-science-pack",
		"nuclear-science-pack"
	},
	nyxaris = {
		"apicultural-science-pack",
		"pelagos-science-pack"
	},
	vibrant = {
		"bioluminescent-science-pack",
		"biorecycling-science-pack",
		"rubia-biofusion-science-pack",
		"galvanization-science-pack",
		"paracelsin-galvanization-science-pack",
		"golden-science-pack",
		"hydraulic-science-pack"
	},
	beetlejuice = {
		"cryogenic-science-pack",
		"gas-manipulation-science-pack",
		"promethium-science-pack"
	},
	nexus_early = {
		"omega-automation-science-pack",
		"omega-logistic-science-pack",
		"omega-military-science-pack",
		"omega-chemical-science-pack",
		"omega-production-science-pack",
		"omega-utility-science-pack",
		"omega-space-science-pack",
		"omega-metallurgic-science-pack",
		"omega-electromagnetic-science-pack",
		"omega-agricultural-science-pack",
		"omega-cryogenic-science-pack",
		"omega-science-pack",
		"promethium-882-science-pack"
	},
	nexus = {
		"antimatter-science-pack"
	},
	deep_space = {
		"void-science-pack",
		"voidp-void-science-pack"
	}
}

local tier_order = {
	"base",
	"inner_system",
	"castra",
	"solaris",
	"dea_dia",
	"nyxaris",
	"vibrant",
	"beetlejuice",
	"nexus_early",
	"nexus",
	"deep_space"
}

local function build_science_through(tier_name)
	local ingredients = {}

	for _, current_tier_name in ipairs(tier_order) do
		add_existing_science_packs(ingredients, science_tiers[current_tier_name])
		if current_tier_name == tier_name then
			break
		end
	end

	return ingredients
end

local function set_science_through(technology_name, tier_name)
	set_technology_unit_ingredients_if_exists(technology_name, build_science_through(tier_name))
end

local function set_many_science_through(technology_names, tier_name)
	for _, technology_name in ipairs(technology_names) do
		set_science_through(technology_name, tier_name)
	end
end

-- System discoveries always inherit every science pack produced by earlier systems.
set_prerequisites_if_exists("solaris-discovery", {
	"planet-discovery-vulcanus",
	"planet-discovery-fulgora",
	"planet-discovery-gleba"
})
set_science_through("solaris-discovery", "inner_system")

set_prerequisites_if_exists("nyxaris-discovery", {"system-discovery-dea-dia"})
set_science_through("nyxaris-discovery", "dea_dia")

set_prerequisites_if_exists("vibrant-discovery", {"nyxaris-discovery"})
set_science_through("vibrant-discovery", "nyxaris")

set_prerequisites_if_exists("beetlejuice-discovery", {"vibrant-discovery"})
set_science_through("beetlejuice-discovery", "vibrant")

-- Base/inner-system planet discoveries.
set_science_through("planet-discovery-muluna", "base")
set_science_through("moon-discovery-cerys", "base")
add_existing_prerequisites("solaris-discovery", {
	"planet-discovery-muluna",
	"moon-discovery-cerys"
})

-- Solaris and Dea Dia branch.
set_prerequisites_if_exists("planet-discovery-castra", {"solaris-discovery"})
set_prerequisites_if_exists("planet-discovery-arig", {"planet-discovery-castra"})
set_prerequisites_if_exists("planet-discovery-hyarion", {"planet-discovery-arig"})
set_prerequisites_if_exists("planet-discovery-tellus", {"planet-discovery-hyarion"})
set_prerequisites_if_exists("planet-discovery-corrundum", {"planet-discovery-tellus"})
set_science_through("planet-discovery-castra", "inner_system")
set_many_science_through({
	"planet-discovery-arig",
	"planet-discovery-hyarion",
	"planet-discovery-tellus",
	"planet-discovery-corrundum"
}, "castra")

set_prerequisites_if_exists("system-discovery-dea-dia", {"planet-discovery-corrundum"})
set_science_through("system-discovery-dea-dia", "solaris")

set_prerequisites_if_exists("planet-discovery-dea-dia", {"system-discovery-dea-dia"})
set_prerequisites_if_exists("planet-discovery-lemures", {"planet-discovery-dea-dia"})
set_prerequisites_if_exists("planet-discovery-prosephina", {"planet-discovery-dea-dia"})
set_many_science_through({
	"planet-discovery-dea-dia",
	"planet-discovery-lemures",
	"planet-discovery-prosephina"
}, "solaris")
add_existing_prerequisites("nyxaris-discovery", {
	"planet-discovery-dea-dia",
	"planet-discovery-lemures",
	"planet-discovery-prosephina"
})

-- Nyxaris branch.
set_prerequisites_if_exists("planet-discovery-apia-carnova", {"nyxaris-discovery"})
set_prerequisites_if_exists("planet-discovery-moshine", {"nyxaris-discovery"})
set_prerequisites_if_exists("panglia_planet_discovery_panglia", {"nyxaris-discovery"})
-- Pelagos can feed Aquilo/lithium depending on its settings, so keep its
-- technology entrypoint on the Dea Dia branch while its route/orbit stays in Nyxaris.
set_prerequisites_if_exists("planet-discovery-pelagos", {"system-discovery-dea-dia"})
set_many_science_through({
	"planet-discovery-apia-carnova",
	"planet-discovery-moshine",
	"panglia_planet_discovery_panglia",
	"planet-discovery-pelagos"
}, "dea_dia")
add_existing_prerequisites("vibrant-discovery", {
	"planet-discovery-apia-carnova",
	"planet-discovery-moshine",
	"panglia_planet_discovery_panglia",
	"planet-discovery-pelagos"
})

-- Vibrant branch.
set_prerequisites_if_exists("planet-discovery-tenebris", {"vibrant-discovery"})
set_prerequisites_if_exists("planet-discovery-paracelsin", {"planet-discovery-tenebris"})
if technology_exists("planet-discovery-frozeta") then
	set_prerequisites_if_exists("planet-discovery-secretas", {"vibrant-discovery"})
	set_prerequisites_if_exists("planet-discovery-frozeta", {"planet-discovery-secretas"})
else
	set_prerequisites_if_exists("planet-discovery-secretas", {"vibrant-discovery"})
end
set_prerequisites_if_exists("planet-discovery-rubia", {"planet-discovery-secretas"})
set_first_existing_prerequisite("planet-discovery-maraxsis", {
	"planet-discovery-rubia",
	"planet-discovery-secretas",
	"vibrant-discovery"
})
set_many_science_through({
	"planet-discovery-tenebris",
	"planet-discovery-paracelsin",
	"planet-discovery-secretas",
	"planet-discovery-frozeta",
	"planet-discovery-rubia",
	"planet-discovery-maraxsis"
}, "nyxaris")
add_existing_prerequisites("beetlejuice-discovery", {
	"planet-discovery-tenebris",
	"planet-discovery-paracelsin",
	"planet-discovery-secretas",
	"planet-discovery-frozeta",
	"planet-discovery-rubia",
	"planet-discovery-maraxsis"
})

-- Beetlejuice and the road out to deep space.
set_prerequisites_if_exists("planet-discovery-cubium", {"beetlejuice-discovery"})
set_prerequisites_if_exists("planet-discovery-vesta", {"planet-discovery-cubium"})
set_prerequisites_if_exists("planet-discovery-aquilo", {"planet-discovery-vesta"})
set_many_science_through({
	"planet-discovery-cubium",
	"planet-discovery-vesta",
	"planet-discovery-aquilo"
}, "vibrant")

local nexus_discovery_technologies = {
	"planet-discovery-nexus",
	"planet-nexus-scanning",
	"advanced-magnetic-shielding",
	"advanced-stable-electronic",
	"advanced-stronger-armor",
	"planet-nexus-scanning-Krastorio2-space-out"
}

add_existing_prerequisites("planet-nexus-scanning", {"planet-discovery-aquilo"})
add_existing_prerequisites("planet-nexus-scanning-Krastorio2-space-out", {"planet-discovery-aquilo"})
add_existing_prerequisites("planet-discovery-nexus", {"planet-discovery-aquilo"})
set_many_science_through(nexus_discovery_technologies, "beetlejuice")

set_science_through("promethium-882-research", "beetlejuice")
set_science_through("antimatter-science-pack", "nexus_early")

set_first_existing_prerequisite("black-hole-discovery", {
	"antimatter-science-pack",
	"promethium-882-research",
	"planet-discovery-nexus",
	"planet-nexus-scanning-Krastorio2-space-out",
	"planet-nexus-scanning"
})
set_science_through("black-hole-discovery", "nexus")

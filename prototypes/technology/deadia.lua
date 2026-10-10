-- Dea Dia progression chain.
set_prerequisites_if_exists("system-discovery-dea-dia", {
	"planet-discovery-arig",
	"planet-discovery-hyarion",
	"planet-discovery-tellus",
	"planet-discovery-corrundum"
})

-- Apia/Carnova lives inside the Nyxaris chain in this pack.
set_prerequisites_if_exists("planet-discovery-apia-carnova", {"nyxaris-discovery"})

-- Ensure Apia science sits after Dea Dia science in the integrated chain.
add_first_existing_prerequisite("apicultural-science-pack", {
	"aerospace-science-pack",
	"thermodynamic-science-pack",
	"insulation-science-pack"
})

-- The network components assembled from several planetary supply chains, the names of the four
-- main ones, and how their research is linked and ordered in the technology menu.
local parts={
  {
    name="razi-network-precision-matrix",
    source_icon="holmium-plate",accent_icon="optical-cable",
    required_mods={"Moshine","Paracelsin"},
    ingredients={
      {type="item",name="optical-cable",amount=3},
      {type="item",name="zinc-plate",amount=2},
      {type="item",name="holmium-plate",amount=1},
      {type="item",name="kr-rare-metals",amount=2}
    },
    suppliers={
      {recipe="optical-cable",product="optical-cable"},
      {recipe="zinc-plate",product="zinc-plate"},
      {recipe="holmium-plate",product="holmium-plate"},
      {recipe="kr-casting-rare-metals",product="kr-rare-metals"}
    },
    planets={
      "planet-discovery-vulcanus","planet-discovery-moshine",
      "planet-discovery-fulgora","planet-discovery-paracelsin"
    },
    science={"solaris-tech-card","nyxaris-tech-card"},
    count=420,energy=8,output=2
  },
  {
    name="razi-network-extreme-lattice",
    source_icon="craptonite-frame",accent_icon="chitosan",
    required_mods={"rubia","tenebris-prime","linox"},
    ingredients={
      {type="item",name="razi-network-precision-matrix",amount=1},
      {type="item",name="craptonite-frame",amount=2},
      {type="item",name="chitosan",amount=2},
      {type="item",name="rare-earth-powder",amount=2},
      {type="item",name="carbon-fiber",amount=2}
    },
    suppliers={
      {recipe="razi-network-precision-matrix",product="razi-network-precision-matrix"},
      {recipe="craptonite-casting",product="craptonite-frame"},
      {recipe="chitosan",product="chitosan"},
      {recipe="linox-recipe_rare-earth-refining",product="rare-earth-powder"},
      {recipe="carbon-fiber",product="carbon-fiber"}
    },
    planets={
      "planet-discovery-rubia","planet-discovery-tenebris",
      "linox-technology_planet-discovery-linox","planet-discovery-gleba"
    },
    science={"vibrant-tech-card","vespera-tech-card"},
    count=680,energy=12,output=2
  },
  {
    name="razi-network-panglia-optic-bond",
    source_icon="panglia_panglite_glass",accent_icon="optical-cable",
    required_mods={"panglia_planet","Moshine"},
    ingredients={
      {type="item",name="panglia_panglite_glass",amount=2},
      {type="item",name="optical-cable",amount=2},
      {type="item",name="holmium-plate",amount=1}
    },
    suppliers={
      {recipe="panglia_panglite_glass",product="panglia_panglite_glass"},
      {recipe="optical-cable",product="optical-cable"},
      {recipe="holmium-plate",product="holmium-plate"}
    },
    planets={"panglia_planet_discovery_panglia",
      "planet-discovery-moshine","planet-discovery-fulgora"},
    science={"solaris-tech-card","nyxaris-tech-card"},
    -- Eight bonds amortise the three imported materials over four
    -- boosted native batches instead of spending one glass per bonus.
    count=360,energy=10,output=8
  },
  {
    -- This is a late framework built from completed planetary industries.
    -- No unstable hydrogen plates or altered Crucible production loops.
    -- Only Deep has a recipe that consumes it, so only Deep creates it.
    name="razi-network-umbra-pressure-frame",
    deep_only=true,
    source_icon="supermagnet",accent_icon="holmium-plate",
    required_mods={"planet-crucible","skewer_planet_vesta",
      "linox","panglia_planet"},
    ingredients={
      {type="item",name="razi-network-panglia-optic-bond",amount=1},
      {type="item",name="holmium-plate",amount=2},
      {type="item",name="supermagnet",amount=2},
      {type="item",name="rare-earth-powder",amount=2}
    },
    suppliers={
      {recipe="razi-network-panglia-optic-bond",
        product="razi-network-panglia-optic-bond"},
      {recipe="holmium-plate",product="holmium-plate"},
      {recipe="supermagnet",product="supermagnet"},
      {recipe="linox-recipe_rare-earth-refining",product="rare-earth-powder"}
    },
    planets={"panglia_planet_discovery_panglia",
      "linox-technology_planet-discovery-linox",
      "planet-discovery-crucible","planet-discovery-vesta",
      "planet-discovery-fulgora"},
    science={"beetlejuice-tech-card","umbra-tech-card"},
    -- Fully material-driven late framework. The source Crucible milestone
    -- remains a gate, but no science pack is consumed as machine feedstock.
    count=980,energy=20,output=8
  }
}

local precision="razi-network-precision-matrix"
local lattice="razi-network-extreme-lattice"
local bond="razi-network-panglia-optic-bond"
local frame="razi-network-umbra-pressure-frame"
-- Research tree: the exchanges that return cargo to a component's planet
-- follow that planet's own research, Deep asks the component networks to
-- cooperate. Components and their exchanges sit together in the menu, and
-- the components are marked essential. Native technologies are not touched.
local balanced_links={
  {"razi-network-bond-paracelsin-coils","panglia_advanced_optics_nanotech"},
  {"razi-network-bond-linox-refining","panglia_advanced_optics_nanotech"}
}
local deep_links={
  {frame,lattice},
  {"razi-network-lattice-vesta-magnets",bond},
  {"razi-network-frame-vesta-foundations","razi-network-lattice-vesta-magnets"}
}
local families={
  {precision,"f[razi-industry]-a[precision]"},
  {"razi-network-matrix-cryo-controllers","f[razi-industry]-a[precision]-a[aquilo]"},
  {bond,"f[razi-industry]-b[panglia]"},
  {"razi-network-bond-paracelsin-coils","f[razi-industry]-b[panglia]-a[paracelsin]"},
  {"razi-network-bond-linox-refining","f[razi-industry]-b[panglia]-b[linox]"},
  {lattice,"f[razi-industry]-c[lattice]"},
  {"razi-network-lattice-vesta-magnets","f[razi-industry]-c[lattice]-a[magnets]"},
  {frame,"f[razi-industry]-d[pressure]"},
  {"razi-network-frame-vesta-foundations","f[razi-industry]-d[pressure]-a[vesta]"}
}
local essential={[precision]=true,[bond]=true,[lattice]=true,[frame]=true}

return {
  parts = parts,
  precision = precision,
  lattice = lattice,
  bond = bond,
  frame = frame,
  balanced_links = balanced_links,
  deep_links = deep_links,
  families = families,
  essential = essential,
}

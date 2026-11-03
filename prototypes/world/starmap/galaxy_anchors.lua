-- The positions the star map layout places: the orbit of each system and planet around its star,
-- the Deep Space bodies whose coordinates other data-stage files share, and the sets of bodies
-- that draw no ring or count as stars.
-- Four first/middle systems sit modestly farther from Nauvis; the two outer
-- systems have a wider ring to clear their large optional planet orbits.
-- Deep Space has its own spacious, directional expedition sectors.
-- Factorio's north points toward negative Y.
-- Hot worlds stay closer to their sun, colder worlds farther out.
-- These are visual orbit distances only; gameplay climates remain source-owned.
local anchors = {
  {"space-location","solaris","star",118,0.416667},
  {"space-location","nyxaris","star",118,0.583333},
  {"space-location","vibrant","star",118,0.25},
  {"space-location","vespera","star",118,0.75},
  {"space-location","beetlejuice","star",143,0.083333},
  {"space-location","umbra","star",143,0.916667},
  -- Deep Space is an independent northern campaign sector. With Aegis now
  -- south of Solaris/Nyxaris its former northern space belongs to the
  -- Nexus/Oort/Sol lane and the Black Hole western expedition.
  {"space-location","solar-system-edge","star",250,0},
  -- Spread the true Deep Space expeditions across the freed northern sky.
  -- These are visual positions only, not route lengths or travel unlocks.
  {"space-location","shattered-planet","solar-system-edge",140,0.33},
  -- This is just a 1,000 km hop. Place the real planet very close to the
  -- Approach with opposite caption directions so the names remain distinct.
  -- Lost Beyond remains a far-flung north-east expedition, with a distinct
  -- lane away from the Nexus / Oort / Sol corridor. Route km are unchanged.
  {"planet","skewer_shattered_planet","shattered-planet",5.0,0.485},
  {"space-location","skewer_lost_beyond","skewer_shattered_planet",145,0.14},
  {"planet","nexus","solar-system-edge",116,0.15},
  {"space-location","black-hole-approach","solar-system-edge",148,0.82},
  {"space-location","black-hole","black-hole-approach",31,0.76},
  {"space-location","oort-cloud","nexus",112,0.17},
  {"space-location","sol","oort-cloud",94,0.13},
  {"space-location","sye-calidus","star",20,0.5},
  -- Clear west-northwest external gateway, just beyond the orbital rim.
  -- Three interstellar departures fan outward, while the northern arc
  -- from Corrundum to Igrys never intersects the gateway/Vulcanus leg.
  {"space-location","sye-solaris","solaris",44,0.84},
  -- Arrivals begin beyond the western asteroid belt, not inside it.
  {"space-location","sye-vibrant","vibrant",60,0.73},
  {"space-location","sye-beetlejuice","beetlejuice",27,0.5},
  -- Northern arrivals flank the corona instead of threading through it.
  {"space-location","sye-nyxaris","nyxaris",41,0.04},
  {"space-location","sye-vespera","vespera",27,0.25},
  {"space-location","sye-umbra","umbra",54,0.42},
  -- Solaris's compact, asymmetric orbital sweep. Warm inner worlds sit
  -- close to the star; Tellus and the denser industrial worlds are
  -- progressively farther out. Distances are visual, not physical AU.
  -- Clockwise spacing is intentionally nonuniform, keeping names and
  -- source planet icons separate without turning travel into a polygon web.
  {"planet","vulcanus","solaris",17,0.69},
  {"planet","hyarion","solaris",21,0.37},
  {"planet","arig","solaris",24,0.52},
  {"planet","castra","solaris",27,0.61},
  {"planet","tellus","solaris",29,0.26},
  {"planet","corrundum","solaris",33,0.13},
  -- Nyxaris forms an open biological crescent, with the Gleba moons well
  -- away from the gateway and Foliax across the quieter western arc.
  -- These are chart positions only; source production and climate are intact.
  {"planet","gleba","nyxaris",32,0.17},
  -- Native Terra Palus joins Gleba as a quiet short-hop moon.
  {"planet","terrapalus","gleba",8,0.43},
  {"planet","moshine","nyxaris",22,0.29},
  {"space-location","apia-carnova-orbit","nyxaris",39,0.35},
  {"planet","panglia","nyxaris",40,0.49},
  -- The rock annulus separates the inner electrical/alchemical worlds
  -- (Fulgora, Ribbonia and Khemia) from Paracelsin and Shchierbin.
  -- Razi's real crossing lies on the south-western part of the asteroid ring.
  {"planet","fulgora","vibrant",24,0.57},
  {"planet","ribbonia","vibrant",26,0.655},
  -- Keep the frozen outer world below the busy west-rim crossing: the
  -- previous .70 bearing shared almost the same label baseline as Outer Rim.
  -- .65 places the marker southeast of the rim while staying outside the
  -- 31-39 unit rock annulus and near the Shchierbin return leg.
  {"planet","paracelsin","vibrant",51,0.65},
  -- Belt-free Vespera: Muria opens Rubia, then branches to greenhouse
  -- ocean Maraxsis and icy outer Aquilo. All planets are true destinations.
  {"planet","muria","vespera",21,0.43},
  -- Athos's arid stone and diamond industry branches from Muria,
  -- before the outer ocean and cryogenic frontier.
  {"planet","athos","vespera",33,0.565},
  {"planet","aquilo","vespera",57,0.73},
  {"planet","rubia","vespera",42,0.70},
  {"planet","maraxsis","vespera",48,0.85},
  {"planet","cubium","beetlejuice",25.283353,0.355716},
  {"planet","linox-planet_linox","beetlejuice",32.133562,0.244042},
  {"space-location","secretas","beetlejuice",40,0.048826},
  -- Umbra enters from OUTSIDE its 31–39-unit shattered belt, like
  -- Vibrant. The only permitted passage to inner Tenebris/Crucible
  -- is the true Outer Rim -> Inner Rim crossing. Distant Vesta remains
  -- a separate outer branch. Crucible's native landing is unchanged.
  {"planet","tenebris","umbra",24,0.54},
  {"space-location","crucible-orbit","umbra",20,0.63},
  {"space-location","razi-umbra-belt-inner","umbra",31,0.47},
  {"space-location","razi-umbra-belt-outer","umbra",39,0.42},
  {"planet","vesta","umbra",56,0.3},
}

-- The optional worlds were previously repositioned in data-final-fixes
-- with PlanetsLib:update, after PlanetsLib removed the sprite-only star
-- prototypes. Register these known orbital plans with both native passes.
-- Only installed planets are touched; moon owners remain unchanged.
local optional_orbits={
  {name="igrys",star="solaris",radius=35,turn=0.905},
  {name="foliax",star="nyxaris",radius=38,turn=0.86},
  {name="obsidiax",star="umbra",radius=68,turn=0.25},
  -- Carna and Arcanyx remain on the INNER side; neither can be reached
  -- directly from the exterior gateway without its rock crossing.
  {name="carna",star="umbra",radius=29,turn=0.7},
  {name="ferrum",star="beetlejuice",radius=43,turn=0.68},
  -- Shchierbin stays outside with Paracelsin; Khemia becomes a distinctive
  -- inner-orbit alchemy world, well inside the 31-39 rock annulus.
  {name="shchierbin",star="vibrant",radius=70,turn=0.64},
  {name="alchemy-planet",star="vibrant",radius=22,turn=0.81},
  {name="arcanyx",star="umbra",radius=27,turn=0.3},
  -- Balack is an optional outer-ice spur beside Aquilo.
  {name="bm-balack",star="vespera",radius=63,turn=0.70}
}
for _,world in ipairs(optional_orbits) do
  anchors[#anchors+1]={"planet",world.name,world.star,world.radius,world.turn}
end

-- Share one authoritative coordinate manifest with data-stage rendering.
local deep_space_names={
  ["shattered-planet"]=true,["skewer_shattered_planet"]=true,
  ["skewer_lost_beyond"]=true,nexus=true,["black-hole-approach"]=true,
  ["black-hole"]=true,["oort-cloud"]=true,sol=true
}
local deep_space_orbits={}
for _,item in ipairs(anchors) do
  if deep_space_names[item[2]] then
    deep_space_orbits[#deep_space_orbits+1]=item
  end
end

-- Source art is preserved, but not giant synthetic destination orbit circles.
local deep_space_no_rings={
  ["solar-system-edge"]=true,["shattered-planet"]=true,nexus=true,
  ["skewer_shattered_planet"]=true,["skewer_lost_beyond"]=true,
  ["black-hole-approach"]=true,["black-hole"]=true,
  ["oort-cloud"]=true,sol=true,pulsar=true,
  ["near-bellicos-orbit"]=true,["bellicos-orbit"]=true,
  ["calidus-bellicos-stargate-calidus"]=true,
  ["aegis-inner-edge"]=true,["aegis-outer-edge"]=true
}

local stars = {
  solaris=true, nyxaris=true, vibrant=true, vespera=true,
  beetlejuice=true, umbra=true
}

return {
  anchors = anchors,
  deep_space_orbits = deep_space_orbits,
  deep_space_no_rings = deep_space_no_rings,
  stars = stars,
}

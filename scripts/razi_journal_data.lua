-- The Codex quest list. Keep these IDs stable for existing saves.
-- Research and world discovery still come from the installed mods.
local M={}
M.chapters={
 {id="calidus",title="journal-chapter.calidus",intro="journal-chapter-story.calidus"},
 {id="solaris",title="journal-chapter.solaris",intro="journal-chapter-story.solaris"},
 {id="nyxaris",title="journal-chapter.nyxaris",intro="journal-chapter-story.nyxaris"},
 {id="vibrant",title="journal-chapter.vibrant",intro="journal-chapter-story.vibrant"},
 {id="vespera",title="journal-chapter.vespera",intro="journal-chapter-story.vespera"},
 {id="beetlejuice",title="journal-chapter.beetlejuice",intro="journal-chapter-story.beetlejuice"},
 {id="umbra",title="journal-chapter.umbra",intro="journal-chapter-story.umbra"},
 {id="stellar",title="journal-chapter.stellar",intro="journal-chapter-story.stellar"},
 {id="network",title="journal-chapter.network",intro="journal-chapter-story.network"},
 {id="finale",title="journal-chapter.finale",intro="journal-chapter-story.finale"},
}
M.quests={
 {id="first-signal",chapter="calidus",tech="automation",requires={}},
 {id="space-science",chapter="calidus",tech="space-science-pack",requires={"first-signal"}},
 {id="muluna",chapter="calidus",tech="planet-discovery-muluna",requires={"space-science"}},
 {id="solaris-gate",chapter="calidus",tech="solaris-discovery",requires={"space-science"}},
 {id="nyxaris-gate",chapter="calidus",tech="nyxaris-discovery",requires={"space-science"}},
 {id="vulcanus",chapter="solaris",tech="planet-discovery-vulcanus",requires={"solaris-gate"}},
 {id="castra",chapter="solaris",tech="planet-discovery-castra",requires={"vulcanus"}},
 {id="arig",chapter="solaris",tech="planet-discovery-arig",requires={"castra"}},
 {id="hyarion",chapter="solaris",tech="planet-discovery-hyarion",requires={"castra"}},
 {id="tellus",chapter="solaris",tech="planet-discovery-tellus",requires={"arig","hyarion"}},
 {id="corrundum",chapter="solaris",tech="planet-discovery-corrundum",requires={"tellus"}},
 {id="gleba",chapter="nyxaris",tech="planet-discovery-gleba",requires={"nyxaris-gate"}},
 {id="moshine",chapter="nyxaris",tech="planet-discovery-moshine",requires={"nyxaris-gate"}},
 {id="apia",chapter="nyxaris",tech="planet-discovery-apia-carnova",requires={"gleba","moshine"}},
 -- Keep the historical Panglia quest ID for existing completion-time records.
 {id="panglia",chapter="nyxaris",tech="panglia_planet_discovery_panglia",requires={"apia","moshine"}},
 {id="panglia-panglite",chapter="nyxaris",tech="panglia_panglite_multiplication",requires={"panglia"}},
 {id="panglia-glass",chapter="nyxaris",tech="panglia_panglite_glass",requires={"panglia-panglite"}},
 {id="panglia-timewarp",chapter="nyxaris",tech="panglia_tech_timewarp_data",requires={"panglia"}},
 {id="panglia-dna-optics",chapter="nyxaris",tech="panglia_advanced_optics_nanotech",requires={"panglia-glass"}},
 {id="panglia-fish-dna",chapter="nyxaris",tech="panglia_collect_dna_fish",requires={"panglia-dna-optics"}},
 {id="panglia-biter-dna",chapter="nyxaris",tech="panglia_collect_dna_biter",requires={"panglia-dna-optics"}},
 {id="panglia-demolisher-dna",chapter="nyxaris",tech="panglia_collect_dna_demolisher",requires={"panglia-dna-optics"}},
 {id="panglia-pentapod-dna",chapter="nyxaris",tech="panglia_collect_dna_pentapod",requires={"panglia-dna-optics"}},
 {id="panglia-dna",chapter="nyxaris",tech="panglia_dna_manipulation",requires={"panglia-fish-dna","panglia-biter-dna","panglia-demolisher-dna","panglia-pentapod-dna"}},
 {id="panglia-simulation",chapter="nyxaris",tech="panglia_simulation_chamber",requires={"panglia-dna","panglia-timewarp"}},
 {id="panglia-matrix",chapter="nyxaris",tech="panglia_simulation_matrix",requires={"panglia-simulation"}},
 {id="panglia-sentient",chapter="nyxaris",tech="panglia_sentient_processor",requires={"panglia-matrix"}},
 {id="panglia-biooptic-trade",chapter="network",tech="razi-panglia-biooptic-glass",requires={"panglia-glass","interplanetary-trade"}},
 {id="panglia-optical-return",chapter="network",tech="razi-moshine-panglia-optical-cables",requires={"panglia-biooptic-trade"}},
 {id="vibrant-gate",chapter="vibrant",tech="vibrant-discovery",requires={"corrundum","apia"}},
 {id="fulgora",chapter="vibrant",tech="planet-discovery-fulgora",requires={"vibrant-gate"}},
 {id="cerys",chapter="vibrant",tech="moon-discovery-cerys",requires={"fulgora"}},
 {id="ribbonia",chapter="vibrant",tech="planet-discovery-ribbonia",requires={"vibrant-gate"}},
 {id="asteroid-belt",chapter="vibrant",tech="space-discovery-asteroid-belt",requires={"ribbonia"}},
 {id="paracelsin",chapter="vibrant",tech="planet-discovery-paracelsin",requires={"asteroid-belt"}},
 {id="vespera-gate",chapter="vespera",tech="vespera-discovery",requires={"corrundum","apia"}},
 {id="muria",chapter="vespera",tech="planet-discovery-muria",requires={"vespera-gate"}},
 {id="aquilo",chapter="vespera",tech="planet-discovery-aquilo",requires={"muria"}},
 {id="vespera-belt",chapter="vespera",tech="razi-vespera-belt-survey",requires={"aquilo"}},
 {id="rubia",chapter="vespera",tech="planet-discovery-rubia",requires={"vespera-belt"}},
 {id="maraxsis",chapter="vespera",tech="planet-discovery-maraxsis",requires={"rubia"}},
 {id="seadragon",chapter="vespera",tech="maraxsis-project-seadragon",requires={"maraxsis"}},
 {id="beetlejuice-gate",chapter="beetlejuice",tech="beetlejuice-discovery",requires={"paracelsin","maraxsis"}},
 {id="cubium",chapter="beetlejuice",tech="planet-discovery-cubium",requires={"beetlejuice-gate"}},
 {id="linox",chapter="beetlejuice",tech="linox-technology_planet-discovery-linox",requires={"cubium"}},
 {id="secretas",chapter="beetlejuice",tech="planet-discovery-secretas",requires={"cubium"}},
 {id="frozeta",chapter="beetlejuice",tech="planet-discovery-frozeta",requires={"secretas"}},
 {id="umbra-gate",chapter="umbra",tech="umbra-discovery",requires={"paracelsin","maraxsis"}},
 {id="tenebris",chapter="umbra",tech="planet-discovery-tenebris",requires={"umbra-gate"}},
 {id="crucible",chapter="umbra",tech="planet-discovery-crucible",requires={"tenebris"}},
 {id="umbra-belt",chapter="umbra",tech="razi-umbra-belt-survey",requires={"crucible"}},
 {id="vesta",chapter="umbra",tech="planet-discovery-vesta",requires={"umbra-belt"}},
 {id="solar-orbit",chapter="stellar",tech="planet-discovery-sunorbit",requires={"fulgora"}},
 {id="inner-orbit",chapter="stellar",tech="slp-solar-system-sun2",requires={"solar-orbit"}},
 {id="dyson-build",chapter="stellar",tech="slp-dyson-sphere",requires={"inner-orbit"}},
 {id="dyson-repeaters",chapter="stellar",tech="slp-dyson-sphere-grounded",requires={"dyson-build"}},
 {id="dyson-mk2",chapter="stellar",tech="ds-energy-loader-mk2",requires={"dyson-repeaters"}},
 {id="dyson-mk3",chapter="stellar",tech="ds-energy-loader-mk3",requires={"dyson-mk2"}},
 {id="interplanetary-trade",chapter="network",tech="interplanetary-trade-logistics",requires={"space-science"}},
 {id="first-frontier-relay",chapter="network",tech="razi-first-frontier-relay-components",site="nauvis",requires={"vulcanus","gleba","moshine"},optional=true},
 {id="precision-matrix",chapter="network",tech="razi-network-precision-matrix",requires={"fulgora","moshine"}},
 {id="extreme-lattice",chapter="network",tech="razi-network-extreme-lattice",requires={"precision-matrix","rubia","tenebris"}},
 {id="outer-mastery",chapter="finale",tech="razi-outer-frontier-mastery",requires={"frozeta","vesta","linox"}},
 {id="edge",chapter="finale",tech="stellar-discovery-solar-system-edge",requires={"outer-mastery"}},
 {id="aegis",chapter="finale",tech="discovery-aegis-outer",requires={"edge"}},
 {id="singularity-theory",chapter="finale",tech="razi-singularity-theory",requires={"outer-mastery"}},
 {id="test-fire",chapter="finale",tech="razi-singularity-test-fire",requires={"singularity-theory"}},
 {id="stable-singularity",chapter="finale",tech="razi-stable-intergalactic-singularity",requires={"test-fire"}},
}
local extended=require("scripts.razi_journal_expansion")
for _,chapter in ipairs(extended.chapters) do M.chapters[#M.chapters+1]=chapter end
for _,quest in ipairs(extended.quests) do M.quests[#M.quests+1]=quest end
local industry=require("scripts.razi_journal_industry")
-- Place the industrial atlas next to the existing supply-network chapter,
-- not after the final intergalactic signal.
for _,chapter in ipairs(industry.chapters) do
  local position
  for i,current in ipairs(M.chapters) do
    if current.id=="network" then position=i+1 break end
  end
  table.insert(M.chapters,position or #M.chapters+1,chapter)
end
for _,quest in ipairs(industry.quests) do M.quests[#M.quests+1]=quest end
-- The FluxWorks industrial atlas exists only when the optional mod is
-- installed. Missing source technologies are filtered by M.available().
if script and script.active_mods and script.active_mods["FluxWorks"] then
  local fluxworks=require("scripts.razi_journal_fluxworks")
  for _,chapter in ipairs(fluxworks.chapters) do
    local position=#M.chapters+1
    for i,current in ipairs(M.chapters) do
      if current.id=="alliances" then position=i+1;break end
    end
    table.insert(M.chapters,position,chapter)
  end
  for _,quest in ipairs(fluxworks.quests) do
    M.quests[#M.quests+1]=quest
  end
end
M.by_id={}
for _,quest in ipairs(M.quests) do M.by_id[quest.id]=quest end
return M

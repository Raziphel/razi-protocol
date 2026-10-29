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
 -- The four Nauvis acts follow existing research, not scripted tasks.
 -- Every ID is stable; absent K2 technologies are safely omitted.
 {id="first-signal",chapter="calidus",tech="automation",phase="machines",requires={}},
 {id="nauvis-power",chapter="calidus",tech="electricity",phase="machines",requires={}},
 {id="nauvis-logistics",chapter="calidus",tech="logistics",phase="machines",requires={"first-signal"}},
 {id="nauvis-electronics",chapter="calidus",tech="electronics",phase="machines",requires={"nauvis-power"}},
 {id="nauvis-radar",chapter="calidus",tech="radar",phase="machines",requires={"nauvis-power"}},
 {id="green-science",chapter="calidus",tech="logistic-science-pack",phase="growth",requires={"first-signal","nauvis-logistics"}},
 {id="steel",chapter="calidus",tech="steel-processing",phase="growth",requires={"green-science"}},
 {id="nauvis-fast-inserters",chapter="calidus",tech="fast-inserter",phase="growth",requires={"nauvis-logistics","green-science"}},
 {id="nauvis-automation-2",chapter="calidus",tech="automation-2",phase="growth",requires={"green-science"}},
 {id="railways",chapter="calidus",tech="railway",phase="growth",requires={"steel","green-science"}},
 {id="nauvis-engines",chapter="calidus",tech="engine",phase="growth",requires={"steel"}},
 {id="oil",chapter="calidus",tech="oil-processing",phase="chemistry",requires={"steel"}},
 {id="nauvis-fluid-handling",chapter="calidus",tech="fluid-handling",phase="chemistry",requires={"oil"}},
 {id="nauvis-plastics",chapter="calidus",tech="plastics",phase="chemistry",requires={"oil"}},
 {id="nauvis-advanced-electronics",chapter="calidus",tech="advanced-electronics",phase="chemistry",requires={"nauvis-plastics","nauvis-electronics"}},
 {id="chemical-science",chapter="calidus",tech="chemical-science-pack",phase="chemistry",requires={"oil","nauvis-advanced-electronics"}},
 {id="space-science",chapter="calidus",tech="space-science-pack",phase="departure",requires={"chemical-science"}},
 {id="muluna",chapter="calidus",tech="planet-discovery-muluna",phase="departure",requires={"space-science"}},
 {id="solaris-gate",chapter="calidus",tech="solaris-discovery",phase="departure",requires={"space-science"}},
 {id="nyxaris-gate",chapter="calidus",tech="nyxaris-discovery",phase="departure",requires={"space-science"}},
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
 {id="athos",chapter="vespera",world="athos",requires={"muria"}},
 -- Vespera's two outer choices now branch directly from Rubia.
 {id="rubia",chapter="vespera",tech="planet-discovery-rubia",requires={"muria"}},
 {id="aquilo",chapter="vespera",tech="planet-discovery-aquilo",requires={"rubia"}},
 {id="nulla",chapter="vespera",world="nulla",requires={"aquilo"}},
 {id="nulla-electromagnetic",chapter="vespera",tech="electromagnetic-robotics",requires={"nulla"}},
 {id="nulla-robotic-science",chapter="vespera",tech="robotic-science-pack",requires={"nulla-electromagnetic"}},
 {id="maraxsis",chapter="vespera",tech="planet-discovery-maraxsis",requires={"rubia"}},
 {id="seadragon",chapter="vespera",tech="maraxsis-project-seadragon",requires={"maraxsis"}},
 {id="beetlejuice-gate",chapter="beetlejuice",tech="beetlejuice-discovery",requires={"paracelsin","maraxsis"}},
 {id="cubium",chapter="beetlejuice",tech="planet-discovery-cubium",requires={"beetlejuice-gate"}},
 {id="linox",chapter="beetlejuice",tech="linox-technology_planet-discovery-linox",requires={"cubium"}},
 {id="secretas",chapter="beetlejuice",tech="planet-discovery-secretas",requires={"cubium"}},
 {id="frozeta",chapter="beetlejuice",tech="planet-discovery-frozeta",requires={"secretas"}},
 {id="umbra-gate",chapter="umbra",tech="umbra-discovery",requires={"paracelsin","maraxsis"}},
 -- Surveying the outer entrance comes before landing on inner worlds.
 {id="umbra-belt",chapter="umbra",tech="razi-umbra-belt-survey",requires={"umbra-gate"}},
 {id="tenebris",chapter="umbra",tech="planet-discovery-tenebris",requires={"umbra-belt"}},
 {id="crucible",chapter="umbra",tech="planet-discovery-crucible",requires={"tenebris"}},
 {id="vesta",chapter="umbra",tech="planet-discovery-vesta",requires={"crucible","umbra-belt"}},
 -- Source-owned optional moon: it appears only with the installed planet
 -- and reuses the author's actual unlock-space-location discovery.
 {id="abacayba",chapter="umbra",world="abacayba",requires={"vesta"}},
 {id="solar-orbit",chapter="stellar",tech="planet-discovery-sunorbit",requires={"fulgora"}},
 {id="inner-orbit",chapter="stellar",tech="slp-solar-system-sun2",requires={"solar-orbit"}},
 {id="dyson-build",chapter="stellar",tech="slp-dyson-sphere",requires={"inner-orbit"}},
 {id="dyson-repeaters",chapter="stellar",tech="slp-dyson-sphere-grounded",requires={"dyson-build"}},
 {id="dyson-mk2",chapter="stellar",tech="ds-energy-loader-mk2",requires={"dyson-repeaters"}},
 {id="dyson-mk3",chapter="stellar",tech="ds-energy-loader-mk3",requires={"dyson-mk2"}},
 {id="interplanetary-trade",chapter="network",tech="interplanetary-trade-logistics",requires={"space-science"}},
 {id="signal-network",chapter="network",tech="aai-signal-transmission",requires={"interplanetary-trade"},optional=true},
 {id="first-frontier-relay",chapter="network",tech="razi-first-frontier-relay-components",site="nauvis",requires={"vulcanus","gleba","moshine"},optional=true},
 {id="precision-matrix",chapter="network",tech="razi-network-precision-matrix",requires={"fulgora","moshine"}},
 {id="extreme-lattice",chapter="network",tech="razi-network-extreme-lattice",requires={"precision-matrix","rubia","tenebris"}},
 {id="outer-mastery",chapter="finale",tech="razi-outer-frontier-mastery",requires={"frozeta","vesta","linox","frontier-recovery-charter"}},
 {id="edge",chapter="finale",tech="stellar-discovery-solar-system-edge",requires={"outer-mastery","stable-singularity"}},
 {id="aegis",chapter="network",tech="discovery-aegis-outer",requires={"solaris-gate","nyxaris-gate"}},
 {id="singularity-theory",chapter="finale",tech="razi-singularity-theory",requires={"outer-mastery"}},
 {id="test-fire",chapter="finale",tech="razi-singularity-test-fire",requires={"singularity-theory"}},
 {id="stable-singularity",chapter="finale",tech="razi-stable-intergalactic-singularity",requires={"test-fire"}},
 {id="convergence-commission",chapter="finale",tech="razi-convergence-commission",requires={"edge","aegis"}},
 {id="convergence-stellar",chapter="finale",tech="razi-convergence-commission",convergence="stellar",requires={"convergence-commission"}},
 {id="convergence-industry",chapter="finale",tech="razi-convergence-commission",convergence="industry",requires={"convergence-stellar"}},
 {id="convergence-synchronization",chapter="finale",tech="razi-convergence-synchronization",requires={"convergence-industry"}},
 {id="convergence-deep-space",chapter="finale",tech="razi-convergence-synchronization",convergence="deep-space",requires={"convergence-synchronization"}},
 {id="convergence-resonance",chapter="finale",tech="razi-convergence-synchronization",convergence="resonance",requires={"convergence-deep-space"}},
 {id="convergence-ignition-research",chapter="finale",tech="razi-convergence-ignition",requires={"convergence-resonance"}},
 {id="convergence-ignition",chapter="finale",tech="razi-convergence-ignition",convergence="ignition",requires={"convergence-ignition-research"}},
 {id="convergence-victory",chapter="finale",tech="razi-convergence-ignition",convergence="victory",requires={"convergence-ignition"}},
}
local frontier=require("scripts.razi_journal_frontier")
for _,quest in ipairs(frontier.quests) do M.quests[#M.quests+1]=quest end
local extended=require("scripts.razi_journal_expansion")
for _,chapter in ipairs(extended.chapters) do M.chapters[#M.chapters+1]=chapter end
for _,quest in ipairs(extended.quests) do M.quests[#M.quests+1]=quest end
-- Recovering launches is part of the expedition, not a replacement for
-- source-owned rocket tech. Optional improved crushing follows real planets.
local salvage=require("scripts.razi_journal_salvage")
for _,chapter in ipairs(salvage.chapters) do
  local position=#M.chapters+1
  for i,current in ipairs(M.chapters) do
    if current.id=="fleet" then position=i+1 break end
  end
  table.insert(M.chapters,position,chapter)
end
for _,quest in ipairs(salvage.quests) do M.quests[#M.quests+1]=quest end
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
-- In 2.1 the native AAI technology has its own research ID. Use the
-- installed research prototype rather than creating a duplicate or
-- misreporting completion when a compatible AAI fork renamed the ID.
if script and script.active_mods
  and script.active_mods["aai-signal-transmission"] and prototypes
  and prototypes.technology then
  local signal_id=require("prototypes.compat.aai_signal_partnerships")
    .source_technology(prototypes.technology)
  if signal_id then
    for _,quest in ipairs(M.quests) do
      if quest.id=="signal-network" then quest.tech=signal_id break end
    end
  end
end
M.by_id={}
for _,quest in ipairs(M.quests) do M.by_id[quest.id]=quest end
-- The story module loads razi_story_dispatch, which reads this module while
-- the story switches on. Publish the finished table first so that read finds
-- it instead of starting a second load.
package.loaded["scripts.razi_journal_data"]=M
local story=require("scripts.razi_story")

-- The name shown for a quest. Without the story it is the game's own name for
-- what the quest is about: the technology, the world's space location, the
-- boss's name from nexus-bosses, or for Convergence stages (which share the
-- technology of another quest) the plain name from journal-plain-title, which
-- is also the fallback for worlds and bosses. With the story the authored
-- title wins and the plain name is the fallback.
function M.quest_title(quest)
  local plain={"journal-plain-title."..quest.id}
  if quest.tech and not quest.boss and not quest.convergence then
    local technology=prototypes and prototypes.technology
      and prototypes.technology[quest.tech]
    plain=technology and technology.localised_name or {"?",plain,quest.tech}
  elseif quest.world and not quest.tech then
    plain={"?",{"space-location-name."..quest.world},plain}
  elseif quest.boss then
    plain={"?",{"nexus-bosses.boss-"..quest.boss},plain}
  end
  if story.enabled() then
    return {"?",{"journal-title."..quest.id},plain}
  end
  return plain
end
return M

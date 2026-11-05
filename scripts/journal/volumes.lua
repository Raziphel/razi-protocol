-- Five-volume Journal catalog; presentation only. Keep each existing milestone ID and source research gate.
-- legacy_chapter and original act keys protect completion records from older 2.x/3.x saves.
local M={volumes={},chapters={},by_chapter={},assignment={}}
do
 local volume={id="foundations",title="journal-volume.foundations",chapters={}}
 do
  local chapter={id="first-signal",volume="foundations",theme="calidus",title="journal-chapter.first-signal",intro="journal-chapter-story.calidus"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"first-signal","nauvis-power","nauvis-logistics","nauvis-electronics","nauvis-radar"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="industrial-foundations",volume="foundations",theme="foundations",title="journal-chapter.industrial-foundations",intro="journal-chapter-story.foundations"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"green-science","steel","nauvis-fast-inserters","nauvis-automation-2","railways","nauvis-engines","production-science","utility-science"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="oil-chemistry",volume="foundations",theme="calidus",title="journal-chapter.oil-chemistry",intro="journal-chapter-story.calidus"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"oil","nauvis-fluid-handling","nauvis-plastics","nauvis-advanced-electronics","chemical-science"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="robots-power",volume="foundations",theme="sciences",title="journal-chapter.robots-power",intro="journal-chapter-story.sciences"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"solar-energy","nuclear-power","kovarex","robots","robot-logistics"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="orbital-construction",volume="foundations",theme="fleet",title="journal-chapter.orbital-construction",intro="journal-chapter-story.fleet"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"space-science","platform","fuel","frames","rocket-silo","thrusters","bulk-cargo","asteroid-processing","asteroid-reprocessing"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="calidus-muluna",volume="foundations",theme="calidus",title="journal-chapter.calidus-muluna",intro="journal-chapter-story.calidus"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"muluna","interstellar-science","advanced-space"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="orbital-salvage",volume="foundations",theme="salvage",title="journal-chapter.orbital-salvage",intro="journal-chapter-story.salvage"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"rocket-salvage-survey","rocket-salvage-beacon","rocket-salvage-precision","rocket-salvage-cryogenic","rocket-salvage-network"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 M.volumes[#M.volumes+1]=volume
end
do
 local volume={id="first-frontiers",title="journal-volume.first-frontiers",chapters={}}
 do
  local chapter={id="solaris-discovery",volume="first-frontiers",theme="solaris",title="journal-chapter.solaris-discovery",intro="journal-chapter-story.solaris"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"solaris-gate"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="vulcanus",volume="first-frontiers",theme="solaris",title="journal-chapter.vulcanus",intro="journal-chapter-story.solaris"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"vulcanus","metallurgic"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="castra-arig",volume="first-frontiers",theme="solaris",title="journal-chapter.castra-arig",intro="journal-chapter-story.solaris"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"castra","arig","battlefield","compression"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="hyarion-tellus",volume="first-frontiers",theme="solaris",title="journal-chapter.hyarion-tellus",intro="journal-chapter-story.solaris"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"hyarion","tellus","polishing","bioengineering","pathological","refraction"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="corrundum",volume="first-frontiers",theme="solaris",title="journal-chapter.corrundum",intro="journal-chapter-story.solaris"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"corrundum","electrochemical"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="nyxaris-discovery",volume="first-frontiers",theme="nyxaris",title="journal-chapter.nyxaris-discovery",intro="journal-chapter-story.nyxaris"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"nyxaris-gate"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="gleba-moshine",volume="first-frontiers",theme="nyxaris",title="journal-chapter.gleba-moshine",intro="journal-chapter-story.nyxaris"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"gleba","moshine","agricultural","insulation","thermodynamic"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="apia",volume="first-frontiers",theme="nyxaris",title="journal-chapter.apia",intro="journal-chapter-story.nyxaris"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"apia","apicultural","aerospace"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="panglia",volume="first-frontiers",theme="nyxaris",title="journal-chapter.panglia",intro="journal-chapter-story.nyxaris"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"panglia","panglia-panglite","panglia-glass","panglia-timewarp","panglia-dna-optics","panglia-fish-dna","panglia-biter-dna","panglia-demolisher-dna","panglia-pentapod-dna","panglia-dna","panglia-simulation","panglia-matrix","panglia-sentient"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="aegis-frontier",volume="first-frontiers",theme="network",title="journal-chapter.aegis-frontier",intro="journal-chapter-story.network"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"aegis"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 M.volumes[#M.volumes+1]=volume
end
do
 local volume={id="outer-systems",title="journal-volume.outer-systems",chapters={}}
 do
  local chapter={id="vibrant-discovery",volume="outer-systems",theme="vibrant",title="journal-chapter.vibrant-discovery",intro="journal-chapter-story.vibrant"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"vibrant-gate"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="fulgora-cerys",volume="outer-systems",theme="vibrant",title="journal-chapter.fulgora-cerys",intro="journal-chapter-story.vibrant"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"fulgora","cerys","electromagnetic","nuclear-science"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="ribbonia",volume="outer-systems",theme="vibrant",title="journal-chapter.ribbonia",intro="journal-chapter-story.vibrant"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"ribbonia","alien"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="belt-paracelsin",volume="outer-systems",theme="vibrant",title="journal-chapter.belt-paracelsin",intro="journal-chapter-story.vibrant"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"asteroid-belt","paracelsin","galvanization"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="vespera-discovery",volume="outer-systems",theme="vespera",title="journal-chapter.vespera-discovery",intro="journal-chapter-story.vespera"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"vespera-gate"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="muria-rubia",volume="outer-systems",theme="vespera",title="journal-chapter.muria-rubia",intro="journal-chapter-story.vespera"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"muria","athos","athos-particulate","rubia","biorecycling","biofusion"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="aquilo-nulla",volume="outer-systems",theme="vespera",title="journal-chapter.aquilo-nulla",intro="journal-chapter-story.vespera"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"aquilo","nulla","nulla-electromagnetic","nulla-robotic-science","cryogenic"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="maraxsis",volume="outer-systems",theme="vespera",title="journal-chapter.maraxsis",intro="journal-chapter-story.vespera"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"maraxsis","seadragon","hydraulic"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="beetlejuice-discovery",volume="outer-systems",theme="beetlejuice",title="journal-chapter.beetlejuice-discovery",intro="journal-chapter-story.beetlejuice"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"beetlejuice-gate"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="cubium-linox",volume="outer-systems",theme="beetlejuice",title="journal-chapter.cubium-linox",intro="journal-chapter-story.beetlejuice"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"cubium","linox","golden"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="secretas-frozeta",volume="outer-systems",theme="beetlejuice",title="journal-chapter.secretas-frozeta",intro="journal-chapter-story.beetlejuice"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"secretas","frozeta"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="umbra-discovery",volume="outer-systems",theme="umbra",title="journal-chapter.umbra-discovery",intro="journal-chapter-story.umbra"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"umbra-gate","umbra-belt"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="tenebris",volume="outer-systems",theme="umbra",title="journal-chapter.tenebris",intro="journal-chapter-story.umbra"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"tenebris","bioluminescent"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="crucible-vesta",volume="outer-systems",theme="umbra",title="journal-chapter.crucible-vesta",intro="journal-chapter-story.umbra"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"crucible","vesta","abacayba","crucible-science","gas-manipulation"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 M.volumes[#M.volumes+1]=volume
end
do
 local volume={id="industrial-network",title="journal-volume.industrial-network",chapters={}}
 do
  local chapter={id="peripheral-expeditions",volume="industrial-network",theme="outposts",title="journal-chapter.peripheral-expeditions",intro="journal-chapter-story.outposts"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"igrys","foliax","rabbasca","terrapalus","velora","khemia","shchierbin","ferrum","obsidiax","balack","carna","arcanyx","pelagos","dea-dia","lemures","prosephina"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="system-tech-cards",volume="industrial-network",theme="sciences",title="journal-chapter.system-tech-cards",intro="journal-chapter-story.sciences"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"precision-matrix","extreme-lattice"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="defense-fleet",volume="industrial-network",theme="defense",title="journal-chapter.defense-fleet",intro="journal-chapter-story.defense"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"military-science","gun-turrets","stone-walls","military-2","military-3","laser-turrets","rocketry","explosives","flamethrowers","spidertron","energy-shield","rocket-turret"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="interplanetary-trade",volume="industrial-network",theme="network",title="journal-chapter.interplanetary-trade",intro="journal-chapter-story.network"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"interplanetary-trade","signal-network","first-frontier-relay","panglia-biooptic-trade","panglia-optical-return"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="industrial-partnerships",volume="industrial-network",theme="alliances",title="journal-chapter.industrial-partnerships",intro="journal-chapter-story.alliances"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"alliance-frontier-castra-ballistics","alliance-bio-metals","alliance-holmium-circuits","alliance-zinc-silicon","alliance-vesta-magnets","alliance-matrix-aquilo","alliance-lattice-vesta","alliance-panglia-bond","alliance-bond-paracelsin","alliance-bond-linox","alliance-pressure-frame","alliance-pressure-vesta"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="dyson-sphere",volume="industrial-network",theme="stellar",title="journal-chapter.dyson-sphere",intro="journal-chapter-story.stellar"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"solar-orbit","inner-orbit","dyson-build","dyson-repeaters","dyson-mk2","dyson-mk3"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 M.volumes[#M.volumes+1]=volume
end
do
 local volume={id="beyond-the-edge",title="journal-volume.beyond-the-edge",chapters={}}
 do
  local chapter={id="outer-mastery",volume="beyond-the-edge",theme="finale",title="journal-chapter.outer-mastery",intro="journal-chapter-story.finale"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"outer-mastery"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="singularity-research",volume="beyond-the-edge",theme="deepworks",title="journal-chapter.singularity-research",intro="journal-chapter-story.deepworks"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"singularity-theory","test-fire","stable-singularity","matter-processing","matter-stabilization","singularity-core","black-hole","promethium","antimatter","matter-card","singularity-card"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="deep-space",volume="beyond-the-edge",theme="deepworks",title="journal-chapter.deep-space",intro="journal-chapter-story.deepworks"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"edge","nexus","warp-drive","zero-point","antimatter-production","transceiver","fragment-1","fragment-2","fragment-3","fragment-4","fragment-5","fragment-6","fragment-7","fragment-8","fragment-9","fragment-10"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="nexus-trials",volume="beyond-the-edge",theme="deepworks",title="journal-chapter.nexus-trials",intro="journal-chapter-story.deepworks"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"nexus-scan","nexus-photon-works","nexus-magnetic-shields","nexus-storm-forecast","nexus-omega-grid","nexus-energy-reserve","nexus-field-beacons","nexus-whisper","nexus-bearings","omega-components","nexus-arachnid-queen","nexus-watcher","nexus-rogue-spidertron","nexus-chorus","nexus-twin-maws","nexus-colossus","nexus-plague-hulk","nexus-convergence","nexus-storm-guardian","nexus-devourer","nexus-last-commander","nexus-silence"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 do
  local chapter={id="convergence",volume="beyond-the-edge",theme="finale",title="journal-chapter.convergence",intro="journal-chapter-story.finale"}
  volume.chapters[#volume.chapters+1]=chapter
  M.chapters[#M.chapters+1]=chapter
  M.by_chapter[chapter.id]=chapter
  for _,id in ipairs({"convergence-commission","convergence-stellar","convergence-industry","convergence-synchronization","convergence-deep-space","convergence-resonance","convergence-ignition-research","convergence-ignition","convergence-victory"}) do
   if M.assignment[id] then error("Duplicate Journal assignment: "..id) end
   M.assignment[id]=chapter.id
  end
 end
 M.volumes[#M.volumes+1]=volume
end
-- These are view-opening aliases, not new names for historic timestamps.
M.legacy_fallback={
 calidus="first-signal",solaris="solaris-discovery",nyxaris="nyxaris-discovery",
 vibrant="vibrant-discovery",vespera="vespera-discovery",
 beetlejuice="beetlejuice-discovery",umbra="umbra-discovery",
 stellar="dyson-sphere",network="interplanetary-trade",finale="convergence",
 foundations="industrial-foundations",fleet="orbital-construction",
 salvage="orbital-salvage",outposts="peripheral-expeditions",
 sciences="system-tech-cards",defense="defense-fleet",
 deepworks="nexus-trials",echoes="deep-space",alliances="industrial-partnerships"
}
function M.apply(quests)
 for _,quest in ipairs(quests) do
  quest.legacy_chapter=quest.legacy_chapter or quest.chapter
  local destination=M.assignment[quest.id] or M.legacy_fallback[quest.legacy_chapter]
  if not M.by_chapter[destination] then
   error("Journal objective has no chapter: "..tostring(quest.id))
  end
  quest.chapter=destination
 end
end
function M.resolve_chapter(id,selected)
 if M.by_chapter[id] then return id end
 local chosen=selected and M.assignment[selected.id]
 if chosen and selected.legacy_chapter==id then return chosen end
 return M.legacy_fallback[id]
end
return M

-- Curated, source-ID-stable acts for every expedition chapter.
-- All current quests are intentionally grouped; unknown new quests fall back
-- to the chapter's Additional Field Records act until explicitly assigned.
local M={}
M.chapters={
  ["calidus"]={
    {id="machines",missions={"first-signal","nauvis-power","nauvis-logistics","nauvis-electronics","nauvis-radar"}},
    {id="growth",missions={"green-science","steel","nauvis-fast-inserters","nauvis-automation-2","railways","nauvis-engines"}},
    {id="chemistry",missions={"oil","nauvis-fluid-handling","nauvis-plastics","nauvis-advanced-electronics","chemical-science"}},
    {id="departure",missions={"space-science","muluna","solaris-gate","nyxaris-gate"}},
  },
  ["solaris"]={
    {id="landfall",missions={"vulcanus","castra"}},
    {id="foundries",missions={"arig","hyarion","tellus"}},
    {id="reclamation",missions={"corrundum"}},
  },
  ["nyxaris"]={
    {id="seed",missions={"gleba","moshine","apia"}},
    {id="panglia",missions={"panglia","panglia-panglite","panglia-glass","panglia-timewarp","panglia-dna-optics"}},
    {id="genetics",missions={"panglia-fish-dna","panglia-biter-dna","panglia-demolisher-dna","panglia-pentapod-dna","panglia-dna"}},
    {id="awakening",missions={"panglia-simulation","panglia-matrix","panglia-sentient"}},
  },
  ["vibrant"]={
    {id="arrival",missions={"vibrant-gate","fulgora","cerys"}},
    {id="belt",missions={"ribbonia","asteroid-belt","paracelsin"}},
  },
  ["vespera"]={
    {id="frontier",missions={"vespera-gate","muria","athos","athos-particulate","rubia"}},
    {id="cold",missions={"aquilo","nulla","nulla-electromagnetic","nulla-robotic-science"}},
    {id="depths",missions={"maraxsis","seadragon"}},
  },
  ["beetlejuice"]={
    {id="arrival",missions={"beetlejuice-gate","cubium","linox"}},
    {id="frozen",missions={"secretas","frozeta"}},
  },
  ["umbra"]={
    {id="shadow",missions={"umbra-gate","umbra-belt","tenebris"}},
    {id="pressure",missions={"crucible","vesta","abacayba"}},
  },
  ["stellar"]={
    {id="orbit",missions={"solar-orbit","inner-orbit"}},
    {id="sphere",missions={"dyson-build","dyson-repeaters","dyson-mk2","dyson-mk3"}},
  },
  ["network"]={
    {id="trade",missions={"interplanetary-trade","signal-network","first-frontier-relay","panglia-biooptic-trade","panglia-optical-return"}},
    {id="precision",missions={"precision-matrix"}},
    {id="lattice",missions={"extreme-lattice","frontier-recovery-charter"}},
  },
  ["finale"]={
    {id="frontier",missions={"outer-mastery","edge","aegis"}},
    {id="singularity",missions={"singularity-theory","test-fire","stable-singularity"}},
    {id="mandates",missions={"convergence-commission","convergence-stellar","convergence-industry","convergence-synchronization","convergence-deep-space","convergence-resonance"}},
    {id="ignition",missions={"convergence-ignition-research","convergence-ignition","convergence-victory"}},
  },
  ["foundations"]={
    {id="power",missions={"solar-energy"}},
    {id="industry",missions={"production-science","utility-science"}},
  },
  ["fleet"]={
    {id="launch",missions={"platform","fuel","frames","rocket-silo"}},
    {id="journey",missions={"interstellar-science","advanced-space","thrusters","bulk-cargo"}},
    {id="asteroids",missions={"asteroid-processing","asteroid-reprocessing"}},
  },
  ["outposts"]={
    {id="settlement",missions={"igrys","foliax","rabbasca","velora","pelagos","dea-dia","lemures","prosephina"}},
    {id="expeditions",missions={"khemia","ferrum","obsidiax","balack"}},
    {id="beyond",missions={"carna","arcanyx","nexus"}},
  },
  ["sciences"]={
    {id="breakthroughs",missions={"metallurgic","electromagnetic","agricultural","cryogenic","lunar","battlefield","compression","polishing","bioengineering","pathological","refraction","electrochemical","insulation","thermodynamic","apicultural","nuclear-science","aerospace","alien"}},
    {id="fusion",missions={"nuclear-power","kovarex","robots","robot-logistics","biorecycling","biofusion","galvanization","hydraulic","bioluminescent","crucible-science","golden","gas-manipulation"}},
    {id="transcendence",missions={"promethium","antimatter","matter-card","singularity-card"}},
  },
  ["defense"]={
    {id="fortification",missions={"military-science","gun-turrets","stone-walls"}},
    {id="arsenal",missions={"military-2","military-3","laser-turrets","rocketry","explosives","flamethrowers","rocket-turret"}},
    {id="machines",missions={"spidertron","energy-shield"}},
  },
  ["deepworks"]={
    {id="matter",missions={"matter-processing","matter-stabilization","singularity-core","black-hole"}},
    {id="nexus",missions={"nexus-scan","nexus-photon-works","nexus-magnetic-shields","nexus-storm-forecast","nexus-omega-grid","nexus-energy-reserve","nexus-field-beacons","nexus-whisper","nexus-bearings","omega-components"}},
    {id="trials",missions={"nexus-arachnid-queen","nexus-watcher","nexus-rogue-spidertron","nexus-chorus","nexus-twin-maws","nexus-colossus","nexus-plague-hulk","nexus-convergence","nexus-storm-guardian","nexus-devourer","nexus-last-commander","nexus-silence"}},
    {id="transmission",missions={"warp-drive","zero-point","antimatter-production","transceiver"}},
  },
  ["echoes"]={
    {id="fragments",missions={"fragment-1","fragment-2","fragment-3","fragment-4","fragment-5"}},
    {id="signal",missions={"fragment-6","fragment-7","fragment-8","fragment-9","fragment-10"}},
  },
  ["alliances"]={
    {id="frontier",missions={"alliance-middle-fulgora","alliance-middle-aquilo","alliance-middle-paracelsin","alliance-middle-rubia","alliance-frontier-moshine-silicon","alliance-frontier-gleba-carbon","alliance-frontier-castra-ballistics","alliance-bio-metals","alliance-holmium-circuits"}},
    {id="specialties",missions={"alliance-optical-coils","alliance-zinc-silicon","alliance-rubia-composites","alliance-tenebris-chitosan","alliance-linox-refining","alliance-vesta-magnets","alliance-cryo-control"}},
    {id="networks",missions={"alliance-photonic-coils","alliance-network-cubium","alliance-balack-shield","alliance-matrix-rubia","alliance-matrix-aquilo","alliance-lattice-vesta","alliance-vesta-foundations","alliance-balack-vesta","alliance-aquilo-outer"}},
    {id="convergence",missions={"alliance-panglia-bond","alliance-bond-paracelsin","alliance-bond-linox","alliance-pressure-frame","alliance-pressure-vesta","alliance-pressure-aquilo"}},
  },
  ["fluxworks"]={
    {id="regional",missions={"flux-calidus","flux-solaris","flux-nyxaris","flux-vibrant","flux-vespera","flux-beetlejuice","flux-umbra"}},
    {id="exchange",missions={"flux-link-calidus-solaris","flux-link-nyxaris-vibrant","flux-link-solaris-vespera","flux-link-vibrant-beetlejuice","flux-link-nyxaris-umbra"}},
  },
}
local by_quest={}
local fallbacks={}
for chapter,sections in pairs(M.chapters) do
  for order,act in ipairs(sections) do
    act.chapter=chapter
    act.order=order
    act.key=chapter=="calidus" and act.id or chapter..":"..act.id
    act.locale_key=chapter.."-"..act.id
    for _,quest_id in ipairs(act.missions) do
      by_quest[quest_id]=act
    end
  end
  fallbacks[chapter]={id="additional",chapter=chapter,
    key=chapter..":additional",locale_key="additional",order=#sections+1}
end
function M.for_quest(quest)
  if not quest then return nil end
  return by_quest[quest.id] or fallbacks[quest.chapter]
end
function M.order(quest)
  local act=M.for_quest(quest)
  return act and act.order or 999
end
function M.caption(act)
  if not act then return nil end
  if act.id=="additional" then return {"journal-ui.act-additional"} end
  return {"journal-act-title."..act.locale_key}
end
return M

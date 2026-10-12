-- The Expedition Chronicle follows the actual research route, not an independent
-- quest unlock tree. Missing optional-mod technologies simply hide their entries.
-- Side expeditions never block chapter completion.
return {
  {
    id = "calidus",
    title = "I. Calidus | First Light",
    subtitle = "From a stranded engineer to an interplanetary civilization",
    intro = "The first signal is only static. Beneath it lies a pattern: worlds, materials and a route nobody has charted. Before pursuing the signal, we must build an industry capable of leaving Nauvis.",
    outro = "The inner worlds are no longer islands. Their combined knowledge resolves into the first stable slipstream, and the wider expedition begins.",
    finish = "solaris-discovery",
    quests = {
      {tech="automation", title="A Factory Awakens", story="Every expedition starts with a dependable machine. Establish automation before trying to solve the stars."},
      {tech="rocket-silo", title="The First Launch", story="A factory can reach across a planet. A rocket gives it somewhere new to go."},
      {tech="space-science-pack", title="The Orbital Perspective", story="Put research above the atmosphere. The first true map begins where the surface ends."},
      {tech="planet-discovery-vulcanus", title="Forge of the Inner Worlds", story="Vulcanus teaches us to build with heat, pressure and metals that Nauvis cannot provide."},
      {tech="planet-discovery-fulgora", title="Ghosts in the Circuitry", story="Fulgora's ruins preserve answers to questions nobody remembers asking. Recover their electrical legacy."},
      {tech="planet-discovery-gleba", title="The Living Equation", story="A living ecosystem becomes an industrial system. Learn to work with its rhythms instead of against them."},
      {tech="planet-discovery-muluna", title="The Lunar Bridge", story="Muluna becomes the stepping stone between familiar orbital science and the farther reaches of Calidus."},
      {tech="moon-discovery-cerys", title="Ashes on Cerys", side=true, story="A forgotten moon offers an alternate scientific foothold and another history worth uncovering."},
      {tech="moon-discovery-eneas", title="Echoes of Eneas", side=true, story="A separate lunar signal draws the expedition toward Eneas and its own specialised discoveries."},
      {tech="solaris-discovery", title="The Solaris Coordinates", story="Combine the inner worlds' science to resolve and open the Solaris slipstream. The first great crossing is possible."}
    }
  },
  {
    id = "solaris",
    title = "II. Solaris | The Industrial Chain",
    subtitle = "Five worlds, one connected industrial frontier",
    entry = "solaris-discovery",
    finish = "nyxaris-discovery",
    intro = "Solaris is not five unrelated destinations. Each world contributes another capability, and every capability brings the next world within reach. We are learning to build an interstellar supply chain.",
    outro = "The connected laboratories of Solaris reveal a stranger set of signals. The route to Nyxaris is no longer a hypothesis.",
    quests = {
      {tech="planet-discovery-castra", title="A Footing on Castra", story="The frontier opens with a difficult foothold. Secure Castra's industrial and military capacity."},
      {tech="planet-discovery-arig", title="The Arig Compression Works", story="Turn the first frontier discoveries into the materials and engineering needed for the next leg."},
      {tech="planetaris-compression-science-pack", title="Under Pressure", story="The compression disciplines of Solaris turn immense infrastructure into portable expertise."},
      {tech="planet-discovery-hyarion", title="Across Hyarion", story="The next world tests whether our new processes can survive beyond their original environment."},
      {tech="planet-discovery-tellus", title="Tellus, Reconsidered", story="Tellus broadens the industrial chain. What worked on one world must now work across several."},
      {tech="planet-discovery-corrundum", title="The Corrundum Link", story="An unfamiliar electrical frontier completes the connected Solaris route."},
      {tech="nyxaris-discovery", title="A Darker Signal", story="Solaris' combined research identifies the Nyxaris slipstream. Beyond it, biology and extreme environments will matter as much as machinery."}
    }
  },
  {
    id = "nyxaris",
    title = "III. Nyxaris | Adaptation",
    subtitle = "An expedition into hostile biology and unstable environments",
    entry = "nyxaris-discovery",
    finish = "vibrant-discovery",
    intro = "Machines alone cannot master these worlds. Nyxaris asks a different question: can our science adapt quickly enough to survive what we find?",
    outro = "The expedition has learned to adapt instead of merely endure. Our instruments begin to register signatures that conventional science cannot explain.",
    quests = {
      {tech="planet-discovery-apia-carnova", title="The Carnova Frontier", story="Follow the strange biological signatures of Apia Carnova and recover its first practical lessons."},
      {tech="planet-discovery-moshine", title="Storm Logic", story="Moshine's changing conditions demand more than brute-force engineering. Find the science inside the storm."},
      {tech="planet-discovery-pelagos", title="The Pelagos Current", side=true, story="An oceanic research corridor adds another way to understand hostile, moving environments."},
      {tech="panglia_planet_discovery_panglia", title="Panglia's Warning", story="The frontier is alive, and not always welcoming. Adapt the expedition to a world that pushes back."},
      {tech="system-discovery-dea-dia", title="The Dea Dia Detour", side=true, story="A newly mapped system offers an additional route through the Nyxaris era when its expedition is installed."},
      {tech="planet-discovery-dea-dia", title="First Contact with Dea Dia", side=true, story="The optional system's principal world brings its own demands and discoveries into the wider campaign."},
      {tech="planet-discovery-lemures", title="The Lemures Survey", side=true, story="Follow the Dea Dia trail farther, gathering evidence from a lesser-charted destination."},
      {tech="planet-discovery-prosephina", title="The Prosephina Survey", side=true, story="A second remote world fills in another piece of the Dea Dia picture."},
      {tech="vibrant-discovery", title="The Unnatural Spectrum", story="Integrate the lessons of Nyxaris to open the Vibrant slipstream. The next chapter will rewrite our assumptions."}
    }
  },
  {
    id = "vibrant",
    title = "IV. Vibrant | Exotic Matter",
    subtitle = "New sciences change the rules of the expedition",
    entry = "vibrant-discovery",
    finish = "beetlejuice-discovery",
    intro = "The signal is changing. Vibrant's planets do not merely offer better versions of familiar materials. They offer new ways for matter, chemistry and life to interact.",
    outro = "Exotic science has become a working discipline. It points past the bright frontier to the outer systems, where endurance will be the next test.",
    quests = {
      {tech="planet-discovery-ribbonia", title="The Ribbonia Anomaly", story="Our first exotic signatures lead to Ribbonia. Theories that worked in Solaris begin to fail."},
      {tech="planet-discovery-paracelsin", title="The Alchemical Route", story="Paracelsin turns unusual chemistry into a repeatable process, connecting strange discoveries to industry."},
      {tech="planet-discovery-shchierbin", title="The Shchierbin Branch", story="A specialised offshoot from Paracelsin extends the frontier's chemical possibilities."},
      {tech="planet-discovery-muria", title="Muria's New Materials", story="A second branch proves that the exotic sciences are not a single isolated trick."},
      {tech="planet-discovery-aquilo", title="The Cold Threshold", story="Aquilo forces the expedition to account for extreme cold before the outer journey."},
      {tech="planet-discovery-rubia", title="A Living Industry", story="Rubia adds powerful biological processes to an already unconventional industrial toolkit."},
      {tech="planet-discovery-maraxsis", title="Below the Surface", story="Maraxsis proves the expedition can build where familiar surface infrastructure is not enough."},
      {tech="beetlejuice-discovery", title="The Outer Passage", story="Exotic science and cryogenic engineering jointly reveal the route to Beetlejuice."}
    }
  },
  {
    id = "beetlejuice",
    title = "V. Beetlejuice | The Last Frontier",
    subtitle = "Cold, darkness, hazards and the edge of known space",
    entry = "beetlejuice-discovery",
    finish = {"stellar-discovery-solar-system-edge", "promethium-science-pack"},
    intro = "The outer planets are not a tour. They are a test of everything learned so far. Their resources and environments form the last practical bridge to deep space.",
    outro = "The outer system has given us the means to leave familiar space. Beyond the edge, the signal becomes both clearer and more dangerous.",
    quests = {
      {tech="planet-discovery-cubium", title="Cubium's Puzzle", story="The first outer-system industries reward careful automation rather than raw scale."},
      {tech="linox-technology_planet-discovery-linox", title="The Linox Spur", side=true, story="A Cubium-linked side route makes use of materials the main expedition now knows how to handle."},
      {tech="planet-discovery-tenebris", title="Into Tenebris", story="Enter the dark frontier and learn how to keep a factory alive without familiar conditions."},
      {tech="planet-discovery-crucible", title="The Crucible Test", story="The industrial journey reaches a world where survival and production become the same problem."},
      {tech="planet-discovery-vesta", title="The Furnace Beyond", story="Vesta pushes the hazard curve farther outward, where the tools of earlier chapters finally earn their keep."},
      {tech="planet-discovery-secretas", title="Secrets of the Outer Route", story="Follow the Cubium branch to Secretas and gather the insight hidden along its unusual path."},
      {tech="planet-discovery-frozeta", title="The Frozen Horizon", story="Frozeta demands the cold-weather expertise that began on Aquilo."},
      {tech="stellar-discovery-solar-system-edge", title="At the Edge", story="Chart the solar-system edge. This is the boundary between mastering worlds and mastering the void."}
    }
  },
  {
    id = "deep-space",
    title = "VI. Deep Space | The Signal",
    subtitle = "From interstellar exploration to the transceiver finale",
    entry = {"stellar-discovery-solar-system-edge", "promethium-science-pack"},
    finish = "razi-intergalactic-transceiver-signal",
    intro = "The signal is real. The final question is whether we can build something precise enough to reach it. The pulsar expedition, promethium and singularity research bring pieces of an answer.",
    outro = "A stable singularity carries the intergalactic signal. The expedition began with static on Nauvis. It ends by answering it.",
    quests = {
      {tech="discovery-aegis-outer", title="The Aegis Expedition", side=true, story="A remote gate beyond the edge opens a parallel path toward the Bellicos pulsar and its demanding science."},
      {tech="promethium-science-pack", title="Promethium Crossing", story="Collect and research the materials that can withstand the conditions of deep space."},
      {tech="promethium-882-research", title="The 882 Anomaly", side=true, story="An unusual promethium signature adds another layer to the late scientific frontier."},
      {tech="planet-discovery-nexus", title="The Nexus Approach", side=true, story="When Nexus is installed, its black-hole route expands the frontier beyond the required finale."},
      {tech="black-hole-discovery", title="Beyond the Horizon", side=true, story="A further optional deep-space investigation approaches the black-hole system."},
      {tech="kr-intergalactic-transceiver", title="A Receiver for the Impossible", story="Research the K2SO transceiver architecture. Theory alone is not yet enough to operate it."},
      {tech="razi-singularity-theory", title="Intergalactic Singularity Theory", story="Formulate a way to sustain the channel without tearing it apart."},
      {tech="razi-singularity-test-fire", title="Test Fire", story="Prove that the theoretical channel survives a real controlled test."},
      {tech="razi-stable-intergalactic-singularity", title="Stable Singularity", story="Complete the stability research that unlocks the final construction."},
      {tech="razi-intergalactic-transceiver-signal", title="Answer the Signal", story="Activate the intergalactic transceiver. The last step is an engineered machine, not merely another research button."}
    }
  }
}
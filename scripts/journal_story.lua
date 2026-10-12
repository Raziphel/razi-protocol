-- The Expedition Chronicle follows the actual research route, not an independent
-- quest unlock tree. Missing optional-mod technologies simply hide their entries.
-- Project and landing missions observe actual progress without changing research gates.
-- Optional branches never impose new prerequisites.
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
      {id="calidus-vulcanus-landing", planet="vulcanus", after="planet-discovery-vulcanus", title="Boots on Basalt", story="Touch down on Vulcanus. The furnace world has to become an actual factory, not merely a point on the map."},
      {id="calidus-fulgora-landing", planet="fulgora", after="planet-discovery-fulgora", title="Through the Lightning", story="Land among Fulgora's ruins. The abandoned circuits are far more interesting up close."},
      {id="calidus-gleba-landing", planet="gleba", after="planet-discovery-gleba", title="Inside the Living World", story="Establish a presence on Gleba and see why its biology changes the rules of logistics."},
      {id="calidus-muluna-landing", planet="muluna", after="planet-discovery-muluna", title="The First Moonfall", story="Make landfall on Muluna and turn orbital aspirations into another working frontier."},
      {id="calidus-triad", project=true, title="Three Worlds, One Launch", route="Vulcanus + Fulgora + Gleba -> Calidus", requires={"metallurgic-science-pack", "electromagnetic-science-pack", "agricultural-science-pack"}, story="Bring metallurgy, electromagnetic engineering and bioindustry into a single research base. Together they make the jump to Solaris possible."},
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
      {id="solaris-castra-landing", planet="castra", after="planet-discovery-castra", title="Castra Beachhead", story="Land on Castra and secure an industrial foothold at the entrance to Solaris."},
      {id="solaris-arig-landing", planet="arig", after="planet-discovery-arig", title="The Arig Landing", story="Bring the expedition to Arig and begin turning frontier resources into compressed industry."},
      {id="solaris-hyarion-landing", planet="hyarion", after="planet-discovery-hyarion", title="Hyarion Survey", story="Set foot on Hyarion. The industrial chain must now survive on unfamiliar terrain."},
      {id="solaris-corrundum-landing", planet="corrundum", after="planet-discovery-corrundum", title="The Electrical Terminus", story="Reach Corrundum in person to complete the first major interplanetary journey."},
      {id="solaris-industrial-exchange", project=true, title="The Solaris Exchange", route="Castra + Arig + Hyarion + Tellus + Corrundum", requires={"battlefield-science-pack", "planetaris-compression-science-pack", "planetaris-polishing-science-pack", "electrochemical-science-pack"}, story="Different industries, shared research. Establish the frontier sciences of warfare, compression, polishing and electrochemistry without making every world solve the same problem."},
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
      {id="nyxaris-moshine-landing", planet="moshine", after="planet-discovery-moshine", title="Moshine Field Study", story="Reach Moshine and observe how the environment transforms an industrial blueprint."},
      {id="nyxaris-panglia-landing", planet="panglia", after="panglia_planet_discovery_panglia", title="First Steps on Panglia", story="Set foot on Panglia and prepare for a world that resists occupation."},
      {id="nyxaris-pelagos-landing", planet="pelagos", after="planet-discovery-pelagos", title="The Ocean Landfall", side=true, story="Visit Pelagos when the optional ocean branch is installed."},
      {id="nyxaris-triple-study", project=true, title="The Adaptation Accord", route="Apia Carnova + Moshine + Panglia", requires={"planet-discovery-apia-carnova", "planet-discovery-moshine", "panglia_planet_discovery_panglia"}, story="Compare three radically different environments. The next breakthrough comes from a shared survival strategy, not from copying the last planet's factory."},
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
      {id="vibrant-ribbonia-landing", planet="ribbonia", after="planet-discovery-ribbonia", title="Land at the Anomaly", story="Touch down on Ribbonia to examine its exotic matter in situ."},
      {id="vibrant-aquilo-landing", planet="aquilo", after="planet-discovery-aquilo", title="Into the Cold", story="Land on Aquilo and prove the expedition can function below the familiar thermal limits."},
      {id="vibrant-rubia-landing", planet="rubia", after="planet-discovery-rubia", title="Rubia's Living Industry", story="Step onto Rubia and study biological production on its home world."},
      {id="vibrant-maraxsis-landing", planet="maraxsis", after="planet-discovery-maraxsis", title="The Deep Descent", story="Land on Maraxsis. The toughest design problem may be where to build at all."},
      {id="vibrant-muria-landing", planet="muria", after="planet-discovery-muria", title="Muria Survey", side=true, story="Reach Muria along the Aquilo-linked branch to investigate its unusual chemistry."},
      {id="vibrant-shchierbin-landing", planet="shchierbin", after="planet-discovery-shchierbin", title="Shchierbin Survey", side=true, story="Follow Paracelsin's chemical trail out to Shchierbin."},
      {id="vibrant-materials-convergence", project=true, title="The Exotic Synthesis", route="Ribbonia + Aquilo + Rubia + Maraxsis", requires={"ribbonia-alien-science-pack", "cryogenic-science-pack", "rubia-biofusion-science-pack", "hydraulic-science-pack"}, story="These worlds solve different physical problems. Unite their sciences before pushing the expedition into the harsh outer systems."},
      {id="vibrant-chemical-branches", project=true, title="The Alchemical Cousins", route="Paracelsin + Muria + Shchierbin", requires={"paracelsin-galvanization-science-pack", "muriatic-science-pack", "vanadium-science-pack"}, side=true, story="Connect unusual processes from three related chemical frontiers. Every completed branch contributes another piece of exotic engineering."},
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
      {id="beetlejuice-cubium-landing", planet="cubium", after="planet-discovery-cubium", title="Cubium Arrival", story="Land on Cubium and begin mastering the outer system's intricate production chains."},
      {id="beetlejuice-tenebris-landing", planet="tenebris", after="planet-discovery-tenebris", title="The Dark Landing", story="Visit Tenebris in person and adapt industry to darkness."},
      {id="beetlejuice-secretas-landing", planet="secretas", after="planet-discovery-secretas", title="The Secretas Expedition", story="Make landfall on Secretas at the edge of the Cubium branch."},
      {id="beetlejuice-frozeta-landing", planet="frozeta", after="planet-discovery-frozeta", title="The Frozen Landing", story="Land on Frozeta. Cold-weather expertise from Aquilo faces its hardest field test."},
      {id="beetlejuice-vesta-landing", planet="vesta", after="planet-discovery-vesta", title="Vesta's Fire", story="Reach Vesta after the Crucible expedition to face the outer system's volcanic hazards."},
      {id="beetlejuice-linox-landing", planet="linox-planet_linox", after="linox-technology_planet-discovery-linox", title="The Linox Detour", side=true, story="Follow the later Cubium spur and establish a landing on Linox."},
      {id="beetlejuice-two-fronts", project=true, title="Two Fronts, One Edge", route="Cubium -> Secretas -> Frozeta | Tenebris -> Crucible -> Vesta", requires={"planet-discovery-cubium", "planet-discovery-secretas", "planet-discovery-frozeta", "planet-discovery-tenebris", "planet-discovery-crucible", "planet-discovery-vesta"}, story="Finish surveying both outer-system arms. Their contrasting technologies prepare the expedition for the journey beyond the edge."},
      {id="beetlejuice-hazard-labs", project=true, title="The Extremes Laboratory", route="Tenebris + Crucible + Aquilo", requires={"bioluminescent-science-pack", "planet-crucible-science-pack", "cryogenic-science-pack"}, story="Turn knowledge of darkness, severe heat and extreme cold into shared scientific capacity."},
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
      {id="deep-space-nexus-landing", planet="nexus", after="planet-discovery-nexus", title="A Footing at Nexus", side=true, story="Land on the optional Nexus world and test the expedition against the deep-space environment."},
      {id="deep-space-singularity-project", project=true, title="The Final Assembly", route="K2SO + Promethium + Singularity", requires={"promethium-science-pack", "kr-intergalactic-transceiver", "razi-singularity-theory", "razi-singularity-test-fire", "razi-stable-intergalactic-singularity", "razi-intergalactic-transceiver-signal"}, story="Complete the engineering chain from deep-space materials to a stable singularity and the final signal. Every earlier chapter contributes to this one operation."},
      {tech="black-hole-discovery", title="Beyond the Horizon", side=true, story="A further optional deep-space investigation approaches the black-hole system."},
      {tech="kr-intergalactic-transceiver", title="A Receiver for the Impossible", story="Research the K2SO transceiver architecture. Theory alone is not yet enough to operate it."},
      {tech="razi-singularity-theory", title="Intergalactic Singularity Theory", story="Formulate a way to sustain the channel without tearing it apart."},
      {tech="razi-singularity-test-fire", title="Test Fire", story="Prove that the theoretical channel survives a real controlled test."},
      {tech="razi-stable-intergalactic-singularity", title="Stable Singularity", story="Complete the stability research that unlocks the final construction."},
      {tech="razi-intergalactic-transceiver-signal", title="Answer the Signal", story="Activate the intergalactic transceiver. The last step is an engineered machine, not merely another research button."}
    }
  }
}
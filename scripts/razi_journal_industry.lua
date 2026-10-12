-- Industrial Constellations: optional real recipe-research milestones.
-- IDs remain stable; the original source mods retain authority over crafting,
-- production conditions, unlock research, and quantities.
-- An absent optional technology does not appear as a phantom quest.
return {
 chapters={{id="alliances",title="journal-chapter.alliances",
   intro="journal-chapter-story.alliances"}},
 quests={
  {id="alliance-bio-metals",chapter="alliances",tech="razi-bio-rare-metal-casting",site="vulcanus",requires={"vulcanus","gleba"}},
  {id="alliance-holmium-circuits",chapter="alliances",tech="razi-electrobiological-components",site="fulgora",requires={"fulgora","gleba"}},
  {id="alliance-optical-coils",chapter="alliances",tech="razi-modded-paracelsin-optical-coils",site="paracelsin",requires={"paracelsin","moshine"}},
  {id="alliance-zinc-silicon",chapter="alliances",tech="razi-modded-moshine-zinc-silicon",site="moshine",requires={"moshine","paracelsin"}},
  {id="alliance-rubia-composites",chapter="alliances",tech="razi-modded-rubia-craptonite-composites",site="rubia",requires={"rubia","paracelsin","moshine"}},
  {id="alliance-tenebris-chitosan",chapter="alliances",tech="razi-modded-tenebris-galvanized-chitosan",site="tenebris",requires={"tenebris","paracelsin"}},
  {id="alliance-linox-refining",chapter="alliances",tech="razi-modded-linox-precision-refining",site="linox-planet_linox",requires={"linox","moshine","paracelsin"}},
  {id="alliance-vesta-magnets",chapter="alliances",tech="razi-modded-vesta-rare-earth-supermagnets",site="vesta",requires={"vesta","linox","moshine"}},
  {id="alliance-cryo-control",chapter="alliances",tech="razi-cryo-energy-control",site="aquilo",requires={"aquilo","fulgora","gleba"}},
  {id="alliance-photonic-coils",chapter="alliances",tech="razi-network-photonic-coils",site="paracelsin",requires={"paracelsin","fulgora","moshine"}},
  {id="alliance-network-cubium",chapter="alliances",tech="razi-network-golden-cubium-alloys",site="cubium",requires={"cubium","secretas","linox"}},
  {id="alliance-balack-shield",chapter="alliances",tech="razi-balack-rubia-chitosan-shielding",site="bm-balack",requires={"balack","rubia","tenebris"}},
  {id="alliance-matrix-rubia",chapter="alliances",tech="razi-network-matrix-rubia-logistics",site="rubia",requires={"precision-matrix","rubia"}},
  {id="alliance-matrix-aquilo",chapter="alliances",tech="razi-network-matrix-cryo-controllers",site="aquilo",requires={"precision-matrix","aquilo"}},
  {id="alliance-lattice-vesta",chapter="alliances",tech="razi-network-lattice-vesta-magnets",site="vesta",requires={"extreme-lattice","vesta"}},
  {id="alliance-vesta-foundations",chapter="alliances",tech="razi-network-vesta-biofoundations",site="vesta",requires={"vesta","rubia","tenebris"}},
  {id="alliance-balack-vesta",chapter="alliances",tech="razi-network-balack-vesta-shielding",site="bm-balack",requires={"balack","vesta","rubia"}},
  {id="alliance-aquilo-outer",chapter="alliances",tech="razi-network-aquilo-outer-controllers",site="aquilo",requires={"aquilo","vesta","rubia"}}
 }
}

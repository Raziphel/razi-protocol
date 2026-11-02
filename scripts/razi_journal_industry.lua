-- Extra Codex missions for cross-planet factory research.
-- Missing optional techs are handled by the journal when it builds the list.
return {
 chapters={{id="alliances",title="journal-chapter.alliances",
   intro="journal-chapter-story.alliances"}},
 quests={
  {id="alliance-frontier-castra-ballistics",chapter="alliances",tech="razi-frontier-castra-composite-rounds",site="castra",requires={"castra","gleba","moshine"},optional=true},
  {id="alliance-bio-metals",chapter="alliances",tech="razi-bio-rare-metal-casting",site="vulcanus",requires={"vulcanus","gleba"}},
  {id="alliance-holmium-circuits",chapter="alliances",tech="razi-electrobiological-components",site="fulgora",requires={"fulgora","gleba"}},
  {id="alliance-zinc-silicon",chapter="alliances",tech="razi-modded-moshine-zinc-silicon",site="moshine",requires={"moshine","paracelsin"}},
  {id="alliance-vesta-magnets",chapter="alliances",tech="razi-modded-vesta-rare-earth-supermagnets",site="vesta",requires={"vesta","linox","moshine"}},
  {id="alliance-matrix-aquilo",chapter="alliances",tech="razi-network-matrix-cryo-controllers",site="aquilo",requires={"precision-matrix","aquilo"}},
  {id="alliance-lattice-vesta",chapter="alliances",tech="razi-network-lattice-vesta-magnets",site="vesta",requires={"extreme-lattice","vesta"}},
  {id="alliance-panglia-bond",chapter="alliances",tech="razi-network-panglia-optic-bond",site="panglia",requires={"panglia-glass","moshine","fulgora"}},
  {id="alliance-bond-paracelsin",chapter="alliances",tech="razi-network-bond-paracelsin-coils",site="paracelsin",requires={"alliance-panglia-bond","paracelsin"}},
  {id="alliance-bond-linox",chapter="alliances",tech="razi-network-bond-linox-refining",site="linox-planet_linox",requires={"alliance-panglia-bond","linox"}},
  {id="alliance-pressure-frame",chapter="alliances",tech="razi-network-umbra-pressure-frame",site="crucible",requires={"alliance-panglia-bond","crucible","vesta","linox"}},
  {id="alliance-pressure-vesta",chapter="alliances",tech="razi-network-frame-vesta-foundations",site="vesta",requires={"alliance-pressure-frame","vesta"}}
 }
}

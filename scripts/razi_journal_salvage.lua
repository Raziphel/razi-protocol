-- Genuine research milestones only: no invented 'launch ten rockets' objective.
-- Completion reads source or Razi research, so old saves catch up automatically.
return {
  chapters={{id="salvage",title="journal-chapter.salvage",
    intro="journal-chapter-story.salvage"}},
  quests={
    {id="rocket-salvage-survey",chapter="salvage",
      tech="rocket-chunk-processing",requires={"platform"}},
    {id="rocket-salvage-beacon",chapter="salvage",
      tech="remnant-beacon",requires={"rocket-salvage-survey"}},
    {id="rocket-salvage-precision",chapter="salvage",
      tech="razi-rocket-salvage-precision",requires={"rocket-salvage-beacon","fulgora"},
      optional=true},
    {id="rocket-salvage-cryogenic",chapter="salvage",
      tech="razi-rocket-salvage-cryogenic",requires={"rocket-salvage-precision","aquilo"},
      optional=true},
    {id="rocket-salvage-network",chapter="salvage",
      tech="razi-rocket-salvage-network",
      requires={"rocket-salvage-cryogenic","interplanetary-trade","precision-matrix"},
      optional=true}
  }
}

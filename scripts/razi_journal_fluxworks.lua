-- Optional research-only Codex objectives for FluxWorks industry.
-- Each objective records a real researched specialist technology.
-- Building its output is encouraged, not faked as an automatic completion.
return {
  chapters={{
    id="fluxworks",
    title="journal-chapter.fluxworks",
    intro="journal-chapter-story.fluxworks",
  }},
  quests={
    {id="flux-calidus",chapter="fluxworks",tech="razi-fw-calidus-industry",recipe="razi-fw-calidus-specialty",machine="fw-synthesis-plant",optional=true,
      site="nauvis",requires={"space-science"}},
    {id="flux-solaris",chapter="fluxworks",tech="razi-fw-solaris-industry",recipe="razi-fw-solaris-specialty",machine="fw-arc-foundry",optional=true,
      site="vulcanus",requires={"vulcanus"}},
    {id="flux-nyxaris",chapter="fluxworks",tech="razi-fw-nyxaris-industry",recipe="razi-fw-nyxaris-specialty",machine="fw-synthesis-plant",optional=true,
      site="gleba",requires={"gleba"}},
    {id="flux-vibrant",chapter="fluxworks",tech="razi-fw-vibrant-industry",recipe="razi-fw-vibrant-specialty",machine="fw-synthesis-plant",optional=true,
      site="fulgora",requires={"fulgora"}},
    {id="flux-vespera",chapter="fluxworks",tech="razi-fw-vespera-industry",recipe="razi-fw-vespera-specialty",machine="fw-synthesis-plant",optional=true,
      site="aquilo",requires={"aquilo"}},
    {id="flux-beetlejuice",chapter="fluxworks",tech="razi-fw-beetlejuice-industry",recipe="razi-fw-beetlejuice-specialty",machine="fw-synthesis-plant",optional=true,
      site="secretas",requires={"secretas"}},
    {id="flux-umbra",chapter="fluxworks",tech="razi-fw-umbra-industry",recipe="razi-fw-umbra-specialty",machine="fw-synthesis-plant",optional=true,
      site="tenebris",requires={"tenebris"}},
    -- Cooperative workshops. These are follow-up discoveries, not required
    -- completions for any world-discovery or story milestone.
    {id="flux-link-calidus-solaris",chapter="fluxworks",
      tech="razi-fw-calidus-solaris-exchange",recipe="razi-fw-calidus-solaris-assembly",machine="fw-arc-foundry",optional=true,site="vulcanus",
      requires={"flux-calidus","flux-solaris"}},
    {id="flux-link-nyxaris-vibrant",chapter="fluxworks",
      tech="razi-fw-nyxaris-vibrant-exchange",recipe="razi-fw-nyxaris-vibrant-assembly",machine="fw-synthesis-plant",optional=true,site="fulgora",
      requires={"flux-nyxaris","flux-vibrant"}},
    {id="flux-link-solaris-vespera",chapter="fluxworks",
      tech="razi-fw-solaris-vespera-exchange",recipe="razi-fw-solaris-vespera-assembly",machine="fw-synthesis-plant",optional=true,site="aquilo",
      requires={"flux-solaris","flux-vespera"}},
    {id="flux-link-vibrant-beetlejuice",chapter="fluxworks",
      tech="razi-fw-vibrant-beetlejuice-exchange",recipe="razi-fw-vibrant-beetlejuice-assembly",machine="fw-synthesis-plant",optional=true,site="secretas",
      requires={"flux-vibrant","flux-beetlejuice"}},
    {id="flux-link-nyxaris-umbra",chapter="fluxworks",
      tech="razi-fw-nyxaris-umbra-exchange",recipe="razi-fw-nyxaris-umbra-assembly",machine="fw-synthesis-plant",optional=true,site="tenebris",
      requires={"flux-nyxaris","flux-umbra"}},
  },
}

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
    {id="flux-calidus",chapter="fluxworks",tech="razi-fw-calidus-industry",
      site="nauvis",requires={"space-science"}},
    {id="flux-solaris",chapter="fluxworks",tech="razi-fw-solaris-industry",
      site="vulcanus",requires={"vulcanus"}},
    {id="flux-nyxaris",chapter="fluxworks",tech="razi-fw-nyxaris-industry",
      site="gleba",requires={"gleba"}},
    {id="flux-vibrant",chapter="fluxworks",tech="razi-fw-vibrant-industry",
      site="fulgora",requires={"fulgora"}},
    {id="flux-vespera",chapter="fluxworks",tech="razi-fw-vespera-industry",
      site="aquilo",requires={"aquilo"}},
    {id="flux-beetlejuice",chapter="fluxworks",tech="razi-fw-beetlejuice-industry",
      site="secretas",requires={"secretas"}},
    {id="flux-umbra",chapter="fluxworks",tech="razi-fw-umbra-industry",
      site="tenebris",requires={"tenebris"}},
    -- Cooperative workshops. These are follow-up discoveries, not required
    -- completions for any world-discovery or story milestone.
    {id="flux-link-calidus-solaris",chapter="fluxworks",
      tech="razi-fw-calidus-solaris-exchange",site="vulcanus",
      requires={"flux-calidus","flux-solaris"}},
    {id="flux-link-nyxaris-vibrant",chapter="fluxworks",
      tech="razi-fw-nyxaris-vibrant-exchange",site="fulgora",
      requires={"flux-nyxaris","flux-vibrant"}},
    {id="flux-link-solaris-vespera",chapter="fluxworks",
      tech="razi-fw-solaris-vespera-exchange",site="aquilo",
      requires={"flux-solaris","flux-vespera"}},
    {id="flux-link-vibrant-beetlejuice",chapter="fluxworks",
      tech="razi-fw-vibrant-beetlejuice-exchange",site="secretas",
      requires={"flux-vibrant","flux-beetlejuice"}},
    {id="flux-link-nyxaris-umbra",chapter="fluxworks",
      tech="razi-fw-nyxaris-umbra-exchange",site="tenebris",
      requires={"flux-nyxaris","flux-umbra"}},
  },
}

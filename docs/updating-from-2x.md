# Updating a 2.x save to 3.0

Your 2.x save keeps working in 3.0. You don't need a new map, and nothing you have already researched is taken away.

## Before you update

1. Update Razi Protocol to the newest 2.x version and load your save.
2. Type `/razi-prepare-3` in the chat and save the game. You must be an admin; in single player you always are. Do this right before updating: the command takes the system tech cards out of your labs, and the update puts them back.
3. Turn off Asteroid Belt, Better Asteroid Belt and Space Route Overlay if you use them: 3.0 doesn't work with them.
4. Get your space platforms ready. Asteroids on dangerous routes can now be epic or legendary and hit much harder. Strengthen the defenses, or turn off Quality asteroids in the mod settings.
5. Take Rigor modules out of machines that make recipes from other mods: they no longer work there.
6. Take quality modules out of machines that only convert or preserve things (preserved goods, matter conversion, datacells, particle manipulation, isotope recipes of Vesta): these recipes no longer accept quality, and the update removes such modules from the machine. Productivity modules in asteroid reprocessing and rocket salvage machines stay but give no bonus any more; in the space electrolysis of Crucible they are removed.

## Installing

3.0 needs many mods that 2.x didn't: new planets and their helper mods. After you update Razi Protocol, the Mods menu shows what is missing. Install all of it.

## What is different after the update

- **Star map.** The star systems now sit in a ring. There are two new systems, Vespera and Umbra, and ten planets moved to other systems. Your platforms stay where they are.
- **Routes.** Razi has its own route network now. Many old routes are gone, and most trips are a bit longer.
- **Labs.** Each lab accepts only some of the system tech cards. Cards a lab no longer accepts are put into a chest next to it.
- **New planets on the main path.** Igrys, Foliax, Obsidiax, Carna, Velora, Khemia, Arcanyx, Nulla, Athos and Balack are now part of the game. Before you can go to the next star system, you research the planets of the current one and one or two partnership technologies (recipes that combine goods from several planets).
- **End game.** The transceiver takes more research than before.
- **Researched technologies** stay researched when 3.0 gives them a prerequisite you have not researched, for example the discovery of a new planet. The technology tree shows the missing prerequisite; you research it only if you want a technology that follows it.
- **Research in progress** keeps its percentage.
- **Recipes.** When the save loads, the game checks every recipe against your research again. A recipe that now belongs to a technology you have not researched is closed, even if it was open before. A machine set to a closed or hidden recipe keeps it and does not work until the recipe opens (its status reads "Recipe not researched"). A recipe that was removed, or that the machine or the planet no longer allows, is taken out of the machine; the items in the machine stay. This applies to:
  - the electrochemical plant, which no longer makes biochamber recipes: use a biochamber;
  - quantum processors, fusion reactors and fusion generators on Arig, which has too much dust for them: machines there lose these recipes;
  - matter to quartz, matter to bones and hot hydrogen from ammonia, which are hidden while Recipe loops is on Closed (the default on Normal);
  - the Krastorio 2 crusher recipes that destroy an item which also has a real crushing recipe: bones, fossil larvae, wasp eggs, Crucible skarn, rocket chunks and four kinds of asteroid chunk;
  - the bioluminescent copies of Tenebris: copies of machines that cannot work on Tenebris can no longer be made, and the copies you have built keep working.
- **System tech cards** now also need Krastorio 2 research data. Start making it.
- **Asteroid collectors** without a filter also pick up the new kinds of asteroid chunks. Set filters.
- **Enemies and Fulgora Replicators.** Fulgora Replicators is optional. If you add it to a save, its islands appear only in the new chunks of Fulgora. With it the Electric flying enemies leave Fulgora: the nests that already stand there stay, the new chunks get none, and Corrundum gets Electric nests on Hard and Nightmare only if its surface does not exist yet.
- **Difficulty.** Your save plays on Normal, which adds no scaling to prices, enemies or machines. Unlike 2.x, Recipe loops is on Closed: some recipes get no productivity and a few are hidden (see Recipes above). The setting can be changed. On Hard and Nightmare, research uses cards made from science packs, so labs wait until you make the cards.
- **New: the Expedition Journal.** Open it with the button at the top left or with Ctrl+Shift+J. It has quests and Projects and counts what you have already done.

## What the update does for you

- If you have already finished the transceiver chain, the new steps in front of it are marked as researched.
- If you have already been past an asteroid belt, the belt survey is marked as researched, so your platforms behind the belt can fly.
- A platform that was flying a route that no longer exists is placed at the end of that route.

## If you forgot `/razi-prepare-3`

The save still loads. System tech cards in labs that no longer accept them are lost, and platforms that were flying a removed route return to Nauvis.

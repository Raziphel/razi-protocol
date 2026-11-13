![Razi Protocol](https://assets-mod.factorio.com/assets/163ee6c5629ef7393b519aa30620d932f3a24df3.png)

**Requires:** Factorio 2.1, Space Age, Krastorio 2 Spaced Out and the mods in the Dependencies tab  
**GitHub:** [Source Code](https://github.com/Raziphel/razi-protocol)  
**Discord:** [Razi's Realm](https://razisrealm.com/discord)  
**Wiki:** [Razi Protocol Wiki](https://wiki.razisrealm.com/factorio)

# Razi Protocol 3.0

You start on Nauvis with Krastorio 2 Spaced Out. From there the game goes through seven star systems and more than 35 worlds from other planet mods, and it ends in Deep Space with five shipments and a final transmission. Each system has its own tech card, and late research spends the cards of every system, so the factories on your first planets keep running until the end. Space routes have danger levels from 1 to 10, and two asteroid belts stand between you and the outer systems.

I started this because I wanted to play with a lot of planet mods at once, and in a normal game they felt like separate additions. Once a planet's research was done there was no reason to go back, and some planets barely touched the rest of the tech tree. Razi Protocol puts them on one route. The planets, machines and recipes still come from their own mods.

## Please read before you start

* **It is long.** More than 35 worlds on top of Space Age. Nobody has finished a 3.0 game yet, so there is no real playtime figure; plan for hundreds of hours.
* **It is big.** With the required and recommended mods you load 187 mods, about 6.5 GB of downloads. On a graphics card with 6–8 GB of memory, lower the texture atlas size and turn off high-quality animations in Settings → Graphics, or the game can crash.
* **It changes the game early.** Technologies unlock in a different order from regular Space Age, and later research costs system cards.
* **Some mods do not work with it:** other route and asteroid belt overhauls (Asteroid Belt, Redrawn Space Connections), the Krastorio 2 extended endgame mods, Lignumis, Factorio+ and the others marked incompatible in the Dependencies tab.
* **2.x saves can be updated.** Make a backup. Before updating, load the save in the latest 2.x, type `/razi-prepare-3` in the chat and save. Then read [the update guide](https://github.com/Raziphel/razi-protocol/blob/main/docs/updating-from-2x.md): some recipes stop accepting modules, and some researched technologies get new prerequisites.

## Razi Protocol is for you if

* You want many planet mods in one game, and you want them to depend on each other.
* You like long supply lines between planets, with old bases that stay useful.
* You want your platforms to be at risk on the way.

If you want a short mod list or a game you can finish in a few weekends, this is not that.

# How a game goes

![The star map: Nyxaris and Solaris, Vespera, Calidus and Vibrant, Aegis and Bellicos, Umbra, Beetlejuice](https://assets-mod.factorio.com/assets/984fd9f0d2d0a3316c6d8aded1adf2fedea387df.png)

**Calidus.** Nauvis and Muluna. You reach space, settle Muluna and make the first system card.

**Solaris and Nyxaris.** You can open them in either order. Vulcanus, Gleba and their neighbours bring the first big industries, and you research every world of the pair before the next systems open.

**Vibrant and Vespera.** Fulgora, Aquilo and their neighbours. The gateway needs partnership technologies that use goods from several planets. To reach Paracelsin and Beetlejuice you survey the Vibrant asteroid belt and fly through it.

**Beetlejuice and Umbra.** The outer systems. Umbra's Shattered Divide is the second belt, in front of Tenebris.

**Aegis and Bellicos.** The Aegis survey opens after Solaris and Nyxaris. Bellicos is a long flight, and you need it for Outer Frontier Mastery.

**Deep Space.** Singularity research and the Krastorio 2 intergalactic transceiver open it. The game ends with the Convergence.

# Star systems

Worlds marked * need an optional or recommended mod.

* **Calidus:** Nauvis, Muluna, Eneas*, Solar Halo*
* **Solaris:** Vulcanus, Castra Prime, Arig, Hyarion, Tellus, Corrundum, Igrys
* **Nyxaris:** Gleba, Moshine, Apia and Carnova, Panglia, Foliax, Velora, Rabbasca*, Terra Palus*, Pelagos*, Dea Dia*, Nuclear Steps*
* **Vibrant:** Fulgora, Cerys*, Ribbonia, Paracelsin, Khemia, Shchierbin*
* **Vespera:** Muria, Athos, Aquilo, Nulla, Rubia, Maraxsis, Balack
* **Beetlejuice:** Cubium, Linox, Secretas, Frozeta, Ferrum*
* **Umbra:** Tenebris, Crucible, Vesta, Carna, Arcanyx, Obsidiax
* **Aegis and Bellicos:** the Aegis edges, the Warden, Bellicos
* **Deep Space:** Solar System Edge, Nexus, Shattered Planet, Black Hole, Oort Cloud, Sol, Skewer Shattered Planet*

# System Tech Cards

![Technology trees built around the system cards](https://assets-mod.factorio.com/assets/7ad0746adeb2dfefccbcd5bf1f5ef45be0512259.png)

There are eight cards, one for each system and one for Deep Space. Each is made from the cards before it and the science packs of its system, and late research spends all seven system cards.

Stronger labs accept later cards:

* **Lab:** Calidus
* **Biolab, Krastorio 2 advanced lab:** Solaris, Nyxaris
* **Moshine thermodynamics lab:** Vibrant, Vespera
* **Corrundum pressure laboratory, Krastorio 2 singularity lab:** Beetlejuice, Umbra
* **Omega lab:** Deep Space

# Routes and asteroids

Every route has a danger level from 1 to 10, and the star map colors it. A route's tooltip shows the largest asteroid, harvestable chunks, distance and suggested defenses, so you can see what a platform needs before it leaves. On dangerous routes asteroids can come in higher quality; on danger 10 they are all legendary. The Quality asteroids setting turns that off.

The two belts are crossings of their own: you survey a belt before you can fly through it, and belts have their own ore and salvage.

# Planets that need each other

A planet discovery can need the science of its neighbours. Partnership technologies unlock exchange recipes, which take an item from another planet and give more than the original recipe. The original stays available. Set Planetary interdependence to Deep for imports 50% larger, or to Off to remove all of this.

Recipes that made items from nothing by going in a circle are closed by default. For example, filling and emptying a container no longer gains from productivity. This is new in 3.0 and applies on Normal too. The Recipe loops setting can open them again or make the rule stricter.

Supported enemy mods get homes on planets that suit them, more of them at higher difficulty. Nauvis keeps vanilla enemies. With the optional Fulgora Replicators, Fulgora belongs to the replicators and the Electric enemies live on Ribbonia, and on Corrundum from Hard on.

# Projects and the Convergence

Projects are large goals that you build and fly, not only research. The Journal tracks them:

* **First Space Platform** and **First Voyage:** build a working platform hub, then fly it between two space locations.
* **Skybridge:** build orbital catapults at both ends of a corridor and carry a signed consignment between the two worlds.
* **Beltbreaker:** cross the Vibrant and Umbra belts by platform.
* **Dyson Sphere:** research the Dyson stages, then build satellites and receivers. The research needs Crucible science, so this comes late.
* **Transceiver:** research and activate the Krastorio 2 transceiver to open Deep Space.
* **Nexus Trials:** defeat all nine Nexus bosses.
* **Ark:** send a heavy platform with at least 3 thrusters, 4 ammo turrets and 2 assembling machines to Deep Space.
* **Convergence:** the victory.

The **Convergence** is five shipments to Deep Space, each with supplies from many planets on top of its main cargo:

* **Stellar:** 24 Dyson satellites
* **Industry:** 600 rare metals
* **Deep Space:** 180 promethium science packs
* **Resonance:** 400 superconductors
* **Ignition:** 120 singularity tech cards and 80 of each system card

Before the last shipment you keep a powered radar in each of the seven systems, and Ignition waits until all nine Nexus bosses are defeated. Then the final transmission ends the game.

# Expedition Journal

![The Quests, Projects and Systems views of the Journal](https://assets-mod.factorio.com/assets/ecac2c815226fab622595b40021033d997298357.png)

Open it with **Ctrl + Shift + J**. It shows what you have done and what comes next.

**Quests** track research, exploration and construction by chapter, and you can pin one to the screen. **Projects** show the goals above with their progress. **Systems** shows information from supported mods, such as Planet Express and Nexus. If you would rather not see what is ahead, turn on Hide future discoveries.

# Difficulty and settings

![The mod settings and the map presets](https://assets-mod.factorio.com/assets/675e5d1006a24e4608c4be97a58b5684c61b66bd.png)

Normal is recommended and leaves the map settings unchanged. The Difficulty setting needs a restart. A value you change by hand stays, Custom uses only your own values, and changes to world generation only reach new areas. The map generator has a matching Razi Protocol preset for each level.

| | Easy | Normal | Hard | Nightmare |
| --- | --- | --- | --- | --- |
| Asteroid population | 65% | 100% | 130% | 130% |
| Asteroid danger | base | base | +0.75 levels | +1.5 levels |
| Research price | 100% | 100% | 125% | 175% |
| Spoilage time | 140% | 100% | 82% | 65% |
| Rocket launch cost | 70% | 100% | 130% | 165% |
| Factory speed | 115% | 100% | 92% | 82% |
| Wall strength | 125% | 100% | 90% | 78% |
| Planets with themed enemies | none | 7 | 10 (11 with Fulgora Replicators) | 11 (12) |
| Recipe loops | Open | Closed | Strict | Strict |

Hard and Nightmare also turn each science pack into a card before it reaches a lab, and put nuclear power behind Vulcanus and Gleba science.

Other settings cover the star map look, route lines and tooltips, crafting menu cleanup, and fewer particles for slower computers.

# Wiki

![Pages of the wiki](https://assets-mod.factorio.com/assets/1a1a3c9e1ad8512e612b3dc42c7cbd170bed58b9.png)

[The Razi Protocol Wiki](https://wiki.razisrealm.com/factorio) covers installation, routes, cards, projects and settings, and has an Expedition Notebook for keeping a checklist in your browser. It is still being updated for 3.0, so some pages may be out of date.

( The wiki was made with the help of AI.  I'm not good at website development.  Just a warning! )

# Feedback

Report broken recipes, missing technologies and compatibility problems on [Discord](https://razisrealm.com/discord) or [GitHub](https://github.com/Raziphel/razi-protocol). Feedback on progression and balance helps most.

# Credits

**Development:** Razi, Alex Green.

The planets, machines, enemies and art you play with come from the authors of the mods in the Dependencies tab. Thanks to them, to Wube Software for Factorio and Space Age, and to everyone who tested and reported problems.

Full list: [Credits.txt](https://github.com/Raziphel/razi-protocol/blob/main/Credits.txt). If someone is missing or wrongly credited, please contact me.

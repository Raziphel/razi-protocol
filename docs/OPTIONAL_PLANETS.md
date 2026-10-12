# Optional Planet Expeditions

> **October 2026 update:** Razi now requires supported Factorio 2.1
> conventional worlds from this earlier optional list, including Eneas and the optional-world group; Cerys is mandatory too.
> See [Required Worlds & Bridge Roadmap](PLANETARY_BRIDGES_AND_MASTERY.md)
> for current dependency policy and the three unresolved compatibility blockers.
> The historical details below document the earlier integration pass.


Five new planet mods are supported as **non-mandatory** campaign destinations.
They are required installation dependencies of the current full pack, but
their worlds do not become progression gates. Installing them
does not alter the required seven-system mastery cards or transceiver victory.

These are external, separately downloadable mods. Razi Protocol contains no
copied artwork, control scripts, music, or surface generation from their authors.

| Planet | Mod ID | Razi region | Gameplay appeal | Status |
| --- | --- | --- | --- | --- |
| Igrys | `Igrys` | Solaris | Glass, mineral science, magic-fluid industry | 2.1 candidate, guarded routes |
| Rabbasca | `planet-rabbasca` | Nyxaris (Gleba moon) | Vault hacking, energy restrictions, bunnyhop equipment | 2.1 candidate, preserve native moon |
| Foliax | `foliax` | Nyxaris | Botany, arcane processing and improved biolabs | 2.1 candidate, guarded routes |
| Obsidiax | `obsidiax` | Vespera | No mining, fire-and-ice industry, cultivated rocks | 2.1 candidate, guarded routes |
| Carna | `carna` | Umbra | Frozen factories, salvage, mechanoids and plasma | 2.1 candidate, guarded routes |

### Design choices

* Optional planets retain their native research chains, discoveries, weather,
  entities, recycling, and specialized enemies.
* Native discovery technologies gain their host star's discovery prerequisite
  **only when no cycle would be created**.
* Planets adopting a Razi star retain their original prototype IDs. Source
  routes that bypass that star via a known different core system are removed,
  but other source-owned local or special travel routes are preserved.
* Rabbasca remains a Gleba moon, with its original orbital relationship. A
  Gleba-to-Rabbasca connection is added only if not provided natively.
* The five destinations never become required for frontier mastery or cards.
  Special integrations and bonus alternate recipes should be considered only
  after their complete Factorio 2.1 mod combinations have been run in-engine.

### Upstream links

- [Igrys](https://mods.factorio.com/mod/Igrys)
- [Rabbasca](https://mods.factorio.com/mod/planet-rabbasca)
- [Foliax](https://mods.factorio.com/mod/foliax)
- [Obsidiax](https://mods.factorio.com/mod/obsidiax)
- [Carna](https://mods.factorio.com/mod/carna)

### Validation before release

Test *each optional mod separately* with the complete Razi required modpack
before testing them together. Factorio's dependency loader will install those
mods' required assets and libraries when selected. In the full post-load dump,
verify every mod's planet prototype, system parent, discovery tech and space
connections. Check recipe craftability and labs, and test native surface
mechanics. Keep copies of old saves; changing a planet's star-system orbit and
space connections can affect existing space-platform routes.

Carna has substantial environment simulation and needs in-game performance and
K2SO checks before it can be considered a mature default choice.

**Note on game-version dependencies:** Rabbasca requires a modern Factorio
2.1.20 build; other planets may require their own assets and libraries. Let
the Factorio mod manager resolve those requirements before playing.

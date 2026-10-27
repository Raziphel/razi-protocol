# Automatic science tech cards

Razi Protocol 3 already has eight handcrafted system tech cards. Vanilla, K2SO and the installed planetary mods also contribute their own science packs, many of which are not tech cards.

The **Automatic planetary tech cards** startup option (on by default) discovers usable science from the final prototype graph, without maintaining a hardcoded mod-specific list. It selects visible science items used as technology ingredients AND supported by at least one existing lab. K2SO's existing tech cards and generic research-data items are not duplicated.

For each science item it creates an individual `razi-<source>-tech-card`, copies the source item prototype including durability/science capacity, spoilage and artwork, and adds a no-productivity 1:1 conversion recipe. Research consumes the cards with unchanged amounts and prerequisites. Labs accept them **only** if they already accepted the original science item; original science, native recipes and the eight system-card manufacturing chains stay intact for source compatibility. Science whose names don't contain `science`, hidden or unused items, and items no installed lab accepts are intentionally skipped rather than guessed at.

**Save compatibility:** existing science inventories remain, but new research uses the converted cards. A new 0.5-second conversion step per pack is required. Disable this startup option before loading an established factory if that is undesirable. Changing the option after setting up production may require factory redesign. No prototype is renamed or removed.

**Unverified:** This is prototype-stage code that still requires a real Factorio startup, K2SO/Space Age/planet science and spoilage checks, plus loading an existing save. Structural regression checks cannot prove in-game compatibility. The log prints the number of packs found for the actual loaded mod combination.

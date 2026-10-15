# Rabbasca lava tile-effect startup crash (0.22.4)

**Symptom**: During Factorio's data.lua loading, the third-party
`planet-rabbasca` mod fails at `prototypes/tiles.lua:17`:

```
attempt to index field 'textures' (a nil value)
```

## Root cause

Rabbasca copies the vanilla Space Age lava tile-effect prototype and then
unconditionally executes:

```lua
lava_effect.water.textures[2].filename =
  "__rabbasca-assets__/graphics/recolor/textures/lava.png"
```

In some Factorio 2.1 mod combinations, `lava_effect.water.textures` is
nil or does not have a second texture. This is an **early, upstream
`data.lua` crash**. Razi Protocol explicitly depends on Rabbasca, so Razi's
own `data.lua`, `data-updates.lua`, and `data-final-fixes.lua` are too
late to catch the error. No runtime event handler can fix it.

### Minimal safe source fix

Replace that single line in Rabbasca's `prototypes/tiles.lua` with:

```lua
if lava_effect.water and type(lava_effect.water.textures) == "table"
    and type(lava_effect.water.textures[2]) == "table" then
  lava_effect.water.textures[2].filename =
    "__rabbasca-assets__/graphics/recolor/textures/lava.png"
end
```

If those textures exist, the recolor still applies unchanged. If they
do not exist, Rabbasca keeps the inherited lava effect instead of
crashing. It does **not** fabricate a possibly invalid texture structure.

## One-command repair of an installed Rabbasca ZIP

1. Exit Factorio, including its mod manager.
2. Download `tools/fix_rabbasca_startup.py` from this repository.
3. Run `python3 fix_rabbasca_startup.py` from any directory. On Windows,
   use `py -3 fix_rabbasca_startup.py` instead.
4. If your Factorio mods folder is nonstandard, pass
   `--mods-dir "/path/to/Factorio/mods"`. To target a specific
   installed archive, pass its full `planet-rabbasca_0.22.4.zip` path.
5. Restart Factorio. The patch preserves all files except that one
   source line and creates `.razi-backup` alongside the original ZIP.
   The backup is deliberately not a `.zip` to avoid double loading.

If the source is different, the script **refuses** to modify it.
It is safe to run twice. A future mod-manager update can replace your
local patched ZIP; repeat only if the upstream bug persists.

**No changes to Razi Protocol's gameplay or dependency list are needed.**
Once Rabbasca fixes the issue upstream, use its normal release rather
than carrying this local patch. This helper is a user-invoked remedy,
not an automatic mod-file mutator.

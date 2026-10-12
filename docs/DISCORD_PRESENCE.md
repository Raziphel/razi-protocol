# Razi Protocol Rich Presence

Original optional Razi Protocol Dev Discord activity integration.

## Architecture

Factorio cannot call Discord IPC from a mod. Razi's in-game script reads the
existing Expedition Journal and exports consenting players' chapter, current
quest, completion totals and optional location to a local state file.
The tiny desktop companion connects to the running Discord desktop client.
It uses only Node.js built-in modules, without a bot, server, npm dependencies
or any data being sent to a Razi backend.

The reference mod is [Discord Rich Presence](https://mods.factorio.com/mod/discord-rich-presence).
Razi's integration is original and the external mod is not required.

## Setup (Windows)

1. Create a Discord application named **Razi Protocol** at
   https://discord.com/developers/applications and copy its **Application ID**.
   An application ID is public. Do not use a bot token.
2. Optional: upload Razi's logo under Discord Rich Presence artwork with
   asset key **razi-logo**. Until that asset exists, the text will work but
   custom artwork may be absent.
3. In Factorio, Settings > Mod settings > Per player, enable
   **Share Razi expedition progress**. It is **off by default**.
4. With Node.js 18+ installed and Discord desktop open, run:

       node tools/razi-presence.js --app-id YOUR_APPLICATION_ID

5. You should see your chapter and pinned/selected/next active journal quest.
   The Discord application name is what displays **Playing Razi Protocol**.

For nonstandard Factorio installations, supply the absolute state file path:

       node tools/razi-presence.js --app-id YOUR_ID --file "C:\Factorio\script-output\razi-presence\state.json"

## Linux

Use the same command. By default the bridge looks at
`~/.factorio/script-output/razi-presence/state.json`.
Discord must be running and its local IPC socket must be accessible from
the companion. A sandboxed Discord installation may need IPC permissions.

## Display

- Title: **Razi Protocol** (Discord application name)
- Details: **Chapter number | localized Expedition Journal chapter title**
- State: **Quest: translated pinned/selected/next active objective**
- If quest sharing is off: campaign milestone count
- Timer: active game session, measured from Factorio simulation ticks
- Logo: optional `razi-logo` artwork; planet/platform in image tooltip
  if enabled and artwork configured

Existing Journal technology and boss-win rules remain authoritative.
Side quests are included when actively selected or pinned. Research and
progression are never changed by sharing.

## Privacy

- Export is per-player **opt-in**, and Factorio writes each export only on
  the consenting player's local client via `for_player`.
- The export excludes player name, multiplayer server/IP, save name, chat,
  inventory, coordinates and any account or Discord credentials.
- Sharing quest title and location can each be disabled independently.
- Disabling sharing immediately writes a disabled marker.
- Missing/paused/closed games make the companion clear activity after 60s.
- The companion ignores incomplete/stale JSON and schema changes.
- Discord updates are rate limited to 15 seconds; no polling is done
  inside Factorio other than one lightweight export every 900 ticks.
- Closing Discord doesn't affect the game. All Discord connectivity is
  in the separate desktop script.

## Troubleshooting

Preview the current file without contacting Discord:

       node tools/razi-presence.js --preview

Or specify a custom path with `--file`. If `fresh` is false, enable the
per-player setting and load a game with Razi Protocol Dev enabled.
Discord must be the desktop client, not merely Discord in a browser.

Check the syntax of the companion with:

       node --check tools/razi-presence.js

To show branded artwork, upload `razi-logo` under your Discord application's
Rich Presence assets. No app ID is bundled because one must be created and
controlled by the owner of Razi Protocol.

The Factorio/Discord integration still needs an end-to-end desktop playtest.

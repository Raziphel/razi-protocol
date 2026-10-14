# Razi Protocol Rich Presence

Razi Protocol exports Expedition Journal progress locally for an optional Discord Rich Presence companion.

## Hard limit: a mod alone cannot update Discord

A Factorio mod cannot open Discord IPC sockets, call the Discord Social SDK, or
launch programs. Discord requires a local program to set a player's activity.
A Discord application ID, webhook, server, or bot cannot remotely set other
users' playing status. The mod package cannot start a companion automatically.
Thus **installing only the Factorio mod will not display branded Rich Presence**.

## Discord application

The public Razi Protocol Discord Application ID is **1559834052867915857**.
It is included in the companion. No player needs to register an application
or supply an ID or bot token. The Discord app's configured name should be
Razi Protocol. An optional Rich Presence asset keyed **razi-logo** must be
uploaded by the app owner to display the custom logo.

## Game configuration

The mod now exports chapter, selected quest and milestone progress locally
by default. No player setting changes are required. In Settings > Mod settings
> Per player, players can turn **Export expedition progress** off entirely,
disable quest sharing, or explicitly enable location sharing (off by default).

The file is written to the **local player's** Factorio script-output directory
using helpers.write_file(..., for_player), not a multiplayer shared export.
No names, server IPs, save names, chats, positions, items, authentication,
Discord tokens or account credentials are included. No Razi backend receives
the information. It is a local file, not a network request.

## Companion (one-time external setup is still required)

Install Node.js 18+ and open Discord's desktop app. From the repository run:

    node tools/razi-presence.js

No npm dependencies or --app-id arguments are needed. The optional --app-id or
RAZI_DISCORD_APP_ID override is useful during development.

Windows default state location:
%APPDATA%\Factorio\script-output\razi-presence\state.json

Linux default state location:
~/.factorio/script-output/razi-presence/state.json

For nonstandard installations:

    node tools/razi-presence.js --file "C:\Factorio\script-output\razi-presence\state.json"

The companion must keep running during play. Discord desktop must be running,
and on Linux its IPC socket must be accessible to the companion.

## Display

- Application: **Razi Protocol** (from the Discord application name)
- Details: chapter number and translated Expedition Journal chapter title
- State: pinned / selected / next active quest, or completed milestone count
- Timer: elapsed game session
- Artwork: optional **razi-logo**, optional planet/platform tooltip

Nothing about sharing changes game progression or Journal completion.

## Performance and failure behavior

- Game writes every 900 ticks (15 game seconds), plus join/setting updates.
- Discord updates are rate limited to at most once every 15 seconds.
- Companion skips malformed state, unknown schemas, and >60s stale files.
- Disabling export immediately writes a disabled marker to clear presence.
- Discord closing/disconnecting does not affect Factorio.
- The bridge uses local Discord IPC and built-in Node.js modules only.

## Local tests

    node --check tools/razi-presence.js
    node tests/test_discord_presence.js
    python -m unittest tests.test_discord_presence
    node tools/razi-presence.js --preview

An actual Discord + Factorio desktop integration test is still needed.

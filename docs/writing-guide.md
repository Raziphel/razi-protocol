# Writing the story text

This guide is for a writer who adds story text to Razi Protocol and wants to see it in the game. You do not need to know Lua. You write in plain text files, start the game, and look at your text in the journal.

The story text lives in six files in `locale/en/`. They start empty. Every text has its own place, called a slot. The list of all slots is in [story-slots.md](story-slots.md).

## Setup (Windows 10)

You need Factorio 2.1 (Steam or the installer from factorio.com) and [GitHub Desktop](https://desktop.github.com/).

### 1. Clone the repository and switch to `dev`

1. In GitHub Desktop: File > Clone repository > URL, enter `Raziphel/razi-protocol`. Keep the suggested local path, usually `C:\Users\<your name>\Documents\GitHub\razi-protocol`. Click Clone.
2. Click Current Branch and choose `dev`. Writer mode exists only on `dev`; the default branch is the released version without it.
3. Click Fetch origin. If the button then says Pull origin, click it.

### 2. Install Razi Protocol and its mods once

1. Start Factorio, open Mods > Install, find Razi Protocol and install it. The game also installs the mods it needs.
2. Restart the game when it asks, then quit Factorio.

### 3. Replace the installed copy with your clone

Factorio must see only one copy of the mod: your clone.

1. Press Win+R, type `%APPDATA%\Factorio\mods` and press Enter. The mods folder opens.
2. Delete the file `razi-protocol_<version>.zip` there. Leave the other files.
3. Press Win+R, type `cmd` and press Enter. In the black window paste this line and press Enter:

   ```
   mklink /J "%APPDATA%\Factorio\mods\razi-protocol" "%USERPROFILE%\Documents\GitHub\razi-protocol"
   ```

   The second path is your clone; change it if you cloned somewhere else. The answer is `Junction created for …`. This needs no administrator rights.

The mods folder now has a folder `razi-protocol` that is your clone: every edit you make in the clone is in the game, and switching branches in GitHub Desktop switches the mod.

If you use the zip version of Factorio, the mods folder is `mods` inside the Factorio folder instead.

### 4. Install what the `dev` version needs

Start Factorio and open Mods. The `dev` version needs some mods the released one does not. If Razi Protocol shows missing mods, install each of them by name in the Install tab and restart the game. If a mod cannot be found or the game still refuses to load, ask in the dev chat.

## Writer mode

Writer mode shows the story slots to you only. Other players see nothing of it. You switch it on in the game chat. You must be an admin; in a single-player game you always are.

Open the console with the key under Esc (`` ` ``, the same key as `~`) and type a command, then press Enter. If the key does nothing, look up Toggle console in Settings > Controls.

| Command | What it does |
| --- | --- |
| `/razi-writer on` | Turn writer mode on. |
| `/razi-writer off` | Turn it off. |
| `/razi-writer keys on` | Show the slot key when you hover over a text. `keys off` hides it. |
| `/razi-writer quest <id>` | Open the journal on a quest, for example `/razi-writer quest first-signal`. |
| `/razi-writer chapter <id>` | Open the journal on a chapter cover, for example `/razi-writer chapter calidus`. |
| `/razi-writer records` | Open every Archive record, also those whose quest is not done. `records off` goes back. |

The ids are in [story-slots.md](story-slots.md).

In writer mode a slot with no text shows a grey stub:

```
[slot razi-story-quest.first-signal — quest dossier, story block, up to 900 characters]
```

It tells you the section and key to write, where the text appears, and how many characters fit. When you have written the text, the stub is replaced by your text. The text that came with the repository is never shown in writer mode.

Quest titles and Archive record titles are different. Without your text they show the name the game gives the quest (or the record id), so the lists stay readable.

To see later quests and chapters, research everything with `/razi-cheat`. It unlocks research in stages. `/razi-cheat status` shows how far it is, and `/razi-cheat cancel` stops it. Use a save you do not need.

The journal opens with the button at the top left of the screen or with Ctrl+Shift+J.

## Where text goes

The files are in `locale\en` of your clone (`Documents\GitHub\razi-protocol\locale\en`). Windows may hide the `.cfg` ending and show them as `story-quests` and so on. Open one with right-click > Open with > Notepad (or VS Code). In Notepad keep the encoding UTF-8 (File > Save as shows it at the bottom).

| File | What is in it |
| --- | --- |
| `story-quests.cfg` | Quest titles, the story text of a quest, field notes, industrial briefs, field assignments |
| `story-chapters.cfg` | The line under a chapter name, and the parts of a chapter cover |
| `story-records.cfg` | Archive records: title, origin line, text |
| `story-projects.cfg` | The text under each project in the Projects tab |
| `story-welcome.cfg` | The messages in chat when a player first joins |
| `story-finale.cfg` | The text of the Convergence final panel |

A file is split in sections. A section has its name in square brackets on its own line, for example `[razi-story-quest]`. Under it, one line is one text:

```
key=text
```

The key is the id of the quest, chapter, record and so on. Take the section and key from [story-slots.md](story-slots.md). Examples:

```
[razi-story-quest]
first-signal=Your text here.

[razi-story-quest-title]
first-signal=Your text here.

[razi-story-chapter-summary]
calidus=Your text here.
```

Rules:

- One text is one line. Do not break the line. For a line break inside a text, write `\n`.
- Write the key exactly as in the list. Do not rename keys or sections. A key that is not in the list is a mistake.
- Write a key only once in its section.
- A line that starts with `#` is a comment and is ignored.
- Colors: `[color=red]text[/color]`. Bold: `[font=default-bold]text[/font]`.
- `__1__`, `__2__` are filled in by the game. Use them only where the slot list says so (the `journal` line of `story-welcome.cfg` gets the unread count as `__1__`).
- Keep each text under the length in the list.

## See it in game

1. Save your edit in the editor.
2. Close Factorio completely and start it again. The game reads the text files when it starts. This is the safe way to see a change; whether loading the save again is enough was not checked.
3. Load or start a save.
4. Type `/razi-writer on` in the chat.
5. Open the journal and look at your text. Use `/razi-writer quest <id>` or `/razi-writer chapter <id>` to jump to it, and `keys on` to see the slot key of a text.

If a text is missing or the stub is still there, check the key and the section name against the slot list, and that the text is on one line after `=`.

## Send it

Do this in GitHub Desktop.

1. Make a branch for your work. Click Current Branch, then New Branch. Name it `story/<topic>`, for example `story/calidus-chapter`. Make sure it is created from `dev`. Click Create Branch.
2. Write and test. The Changes tab shows the files you changed. They should only be `locale/en/story-*.cfg` files.
3. Commit. In the Summary box write what you did, in this form: `feat(story): write the Calidus chapter texts`. Click Commit to `story/<topic>`.
4. Push. Click Publish branch the first time, and Push origin after that.
5. Click Create Pull Request. The browser opens on GitHub. Check that the base branch is `dev`. Use the same words as in the commit for the title, and a short list of what you wrote as the description. Click Create pull request.

Your pull request is checked and merged into `dev`. The check is only about the format of the files, not about your text. If you add more text later, make a new branch from `dev` again.

## Slots

[story-slots.md](story-slots.md) lists every slot: the file and section, the key, where it is seen, when it appears and how long the text can be.

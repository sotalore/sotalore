# CLAUDE.md (sl-lua)

Notes for the agent working on the SotaLore in-game Lua plugin. The repo-root `CLAUDE.md` still applies
(notably: do not stage or commit unless asked). Work only inside `sl-lua/`.

## What this is

A Lua addon for *Shroud of the Avatar* (display name **SotaLore**, slug and folder `sl-recipes`). It
browses the player's known recipes and writes JSON files that an admin uploads to the SotA Lore web
app. Lua cannot POST and has no clipboard, so files are the only way out.

- The code is split into modules (see "Code organisation"). `manifest.json` lists them in load order
  and holds the package metadata (`min_api_version` 37).
- `EXPORT-FORMAT.md`: **the contract with the importer, and yours to keep accurate.** Change it in the
  same change as any export change, and flag breaking changes in it. The app side reads exactly what it
  describes.
- `FROM-THE-APP.md`: written by the app-side agent (requests, how the site uses exports, the site's data
  model). **Read it, never edit it.** Answer requests by updating `EXPORT-FORMAT.md`.
- Real example outputs are in `data/plugin-examples/` (repo root). `.gitignore` ignores `sotalore-*.json`
  everywhere else so game output is never committed by accident.

## Code organisation

Darren is new to Lua, so the layout is meant to be easy to read: each file does one job and starts with a
comment saying what it is for. This is the pattern the game's own multi-file example addon uses.

| File | Job |
|------|-----|
| `core.lua` | creates the one global table `SotaLore`; shared helpers in `SotaLore.util` (JSON writing, text clipping, file writing, `perItem`) and file names in `SotaLore.files` |
| `recipes_export.lua` | `SotaLore.RecipeExport`: known recipes to JSON files, the "already exported" list |
| `items.lua` | `SotaLore.Items`: the items file for the bags; exports only new or changed items (`new`), everything (`all`) or marks them exported (`baseline`), in time slices |
| `finds_data.lua` | `SotaLore.Finds`: the per-scene find list (items, creatures, nodes), saving it, writing the finds file |
| `finds_ui.lua` | `SotaLore.FindsUI`: the small finds window |
| `recipes_ui.lua` | `SotaLore.RecipesUI`: the recipe list and recipe windows, with the export buttons |
| `item_details.lua` | `SotaLore.ItemDetails`: captures what item tooltips say (quest item, tool, no trade, salvage lists) by hovering, `/slore capture` |
| `hoverlog.lua` | `SotaLore.HoverLog`: a diagnostic (`/slore hoverlog`) that writes the tooltip text of items under the mouse to chat |
| `main.lua` | the only file with `ShroudOn...` callbacks, the `/slore` command and the key binding; read it first |

Rules for keeping it working:

- The files run in the order `manifest.json` lists them and share one environment. A file may only use
  modules from files listed **before** it (at load time). A new file must be added to the manifest.
- Everything is `local` except the single global `SotaLore` (all addons share one global environment, so a
  second global invites clashes). Share things between files by hanging them on `SotaLore`.
- Files can't load each other (`require` and `dofile` are not allowed) and the `Shroud...` functions don't
  exist while a file loads: **do not call the game's API at the top level of a file**, only inside
  functions (`Shroud.UI` is the one exception). `local UI = Shroud.UI` at the top is fine.
- Only `main.lua` defines `ShroudOn...` functions; each should just call into a module.
- Data modules (`recipes_export`, `finds_data`) know nothing about windows. They tell a window about
  changes through a hook (`Finds.onChange`, `RecipeExport.onProgress`) that the UI file sets.

## What the finds window is for

Darren walks a scene with the finds window up, then saves the list for upload. The goal is to keep the
site's data about each scene current:

1. **Scene information**: the scene's kind flags, player cap and level/skill caps (`info`).
2. **Creatures** that can be met in the scene (the ones fought) and **what they can drop**.
3. **Gathering nodes** available in the scene and **what each yields**.

A creature's drops are only attributed when its corpse is field dressed (the node is the creature's name).
Corpse loot taken another way has no source, so some drops are unattributed.

### The gathering activities

Five kinds, which the data does not label (a node name that is also in `creatures` is a creature):

- **Mining** (a "Copper Vein"), **forestry** (a Pine or Maple tree), **foraging** (a garlic or cotton plant):
  a node in the world that is harvested. `ShroudOnGatherResults` gives its name and loot.
- **Field dressing**: not a world node. The creature is killed first (or its corpse is found), then the
  corpse is "skinned". `ShroudOnGatherResults` gives the creature's name as the node.
- **Fishing**: an activity of its own, very different from the others. **Not handled yet**; Darren will
  cover it later. Do not assume it fits the node model.

### Interrupted harvests (open problem)

The first four activities can be interrupted. Finished: `ShroudOnGatherResults` fires. Interrupted: it
does **not** fire, and the node (or corpse) simply becomes a lootable thing holding the items earned so far.
Those items arrive through `ShroudOnItemsGained` with no source, so they are counted under `items` but
never under `nodes`. Darren wants to find a better way to track these; it may not be possible.

**Ruled out: the mouse.** Tracking what the player points at (`ShroudGet*UnderMouse`) will not work: the game
can loot any corpse near where the player stands without clicking it, and a corpse that needs skinning is
skinned automatically. The player often never points at the thing.

Untested ideas:

- At the moment of a gain, read the current target (`ShroudHasTarget`, `ShroudGetTargetName`,
  `ShroudIsTargetDead`); a corpse being looted or skinned may still be the target. Test with a debug log
  before building on it.
- Use the combat lines: a `death` line with a time and creature key, then loot arriving soon after, suggests
  that corpse. Nearby auto-loot can take several corpses at once, so this is a guess to label as one.
- Map an item name to the node(s) that gave it in completed harvests in the same scene, and attribute
  an unattributed gain only when that mapping is unique (Iron Ore comes from "Iron Vein" and nothing else).
  Label such guesses in the file; never mix them into the confirmed `nodes`.
- If either of the first two ideas works, it might also attribute plain corpse loot (not just interrupted
  skinning) to the creature it came from.

## Environment

- The game's folder `...\Catnip Games\Shroud of the Avatar(DEV)\Lua\sl-recipes` is a **Windows junction to
  this folder**. Edit here (`C:\dev\sotalore\sl-lua`). Editing through the game's path once failed with odd
  "file already exists" errors.
- The addon's output files are written to the game's `Lua/` folder, **one level above the plugin folder**
  (`sotalore-export.json`, `-one.json`, `-items.json`, `-finds.json`), not into `sl-lua/`. To use one as
  an example, copy it from there into `data/plugin-examples/`.
- **The game cannot be launched from this session.** A standalone Lua (5.5, installed with scoop; `lua` and
  `luac` on the PATH) is available on Darren's machine: use `luac -p file.lua` to syntax-check every file
  after an edit. For behaviour, write a throwaway fake-game script (stub `Shroud.UI`, `Shroud.Command`,
  the `Shroud...` getters and saved variables, then call the `ShroudOn...` callbacks) and compare the output
  files with the previous version's; the 0.5.1 refactor was verified that way (old single file vs the
  modules gave byte-identical output). It is only a fake game, and the game's interpreter is older
  (5.2-style), so say plainly that a change is untested in game. Darren tests in game (`/lua reload`,
  `/lua check sl-recipes`) and reports errors or pastes the output files.
- Edit tool calls in parallel on one file can collide; make edits to one file one at a time.
- Bump the version together in `core.lua` (`local Version`), `manifest.json` and the heading of
  `EXPORT-FORMAT.md`.

## Slash command, windows, saved data

- Command is `/slore` (`/sotalore` is refused: `sota` is a reserved prefix). Subcommands: `export`,
  `exportall`, `baseline`, `new` (open the list showing only recipes "Export new" would export), `items` (new or changed items), `itemsall`, `baselineitems`, `finds` (toggle the finds window), `savefinds`, `clearfinds`,
  `gatherlog`, `checkrecipes`, `capture`, `hoverlog`; other text searches the recipe list.
- An addon may own at most **8 windows**: the list (1), the finds window (1) and up to 6 recipe windows.
- Account-scope saved variables: `exported` (recipe ids already exported; "Export new" = not in it),
  `itemSigs` (a fingerprint per item for what was last exported; no catalog of items is kept), `itemDetails` (captured tooltips), `exported` (recipes), `finds` (the per-scene list), `track` (tracking toggle).

## API facts learned in play (docs are at https://catnipgames.net/lua/reference.html)

- Read the docs by downloading the page, stripping the HTML to text and searching it; a summarising
  fetch loses detail. The docs and the live API can differ and the API version moves (it was 40).
- **Bag item `weight` and `value` are for the whole stack**, not "one item" as documented. The plugin
  divides by `quantity` (`perItem`). Darren was going to file this as an API bug; if the game fixes it,
  `perItem` would then divide wrongly, so re-check against a recipe's per-item weight first.
- **`ShroudGetRecipe(id)` can return nil for a recipe `ShroudGetKnownRecipes` lists** (first seen with newly
  learned recipes: the detail window said "You no longer know this recipe" and exports silently dropped
  them). `util.getRecipe(id, categoryKey)` falls back to `ShroudGetRecipeBook(categoryKey)`; exports now warn in
  chat about recipes they could not read, and `/slore checkrecipes` lists the unreadable ones. On Darren's
  character 103 of 1,234 known recipes failed (Alchemy gem fragment and fracture recipes, Tanning fishing-trophy
  recipes); the recipe book had them. Before 0.5.2 they were silently left out of every export. Cause unknown.
- **The game stops a callback that runs longer than 1 second (5 seconds while the plugin starts).** The guide says
  to spread work across frames or use `ShroudRegisterPeriodic`. Long jobs here (the recipe export, `/slore
  checkrecipes`) work in slices of `util.sliceLimit` seconds per frame, cut by time as well as count because
  recipes with many group slots are far slower to read than simple ones. `util.slow(what, since)` writes a
  "SotaLore slow: ..." line to chat when a step takes over 0.3 s, to find the one that is too slow. A single
  call that is itself slow (`ShroudGetRecipeBook` for a whole craft skill, saving a big saved variable) cannot
  be sliced. A "Lua Watchdog ... exceeded its execution time budget" message seen once during exports on
  2026-10-17; the cause was not identified before the slicing and the slow-step messages were added.
- **A stopped callback must leave the job's state consistent.** The 0.7.1 export once wrote 10 recipes twice: the game
  stopped a callback (the watchdog) after a batch of recipes had been stored but before the position was
  advanced, so the next frame read the same batch again. `ShroudGetKnownRecipes` itself lists every id once (checked:
  1,234 entries, 1,234 different recipes). Since 0.7.2 the export stores each recipe under its id and advances
  one recipe at a time, so reading a recipe again changes nothing. Keep any multi-frame job idempotent like that.
- A bag item's `key` (`item:` + 32 hex) is the same key recipes use for ingredients and results; this is the
  only game item id there is. Recipe `id` is a signed 32-bit integer and can be negative.
- `ShroudOnItemsGained` ("Recently Looted") excludes items already owned, moves, equipping, login and
  scene changes, but includes bank/chest/vendor/crafting-station takes. The API has no locked flag.
- Combat lines (`ShroudOnCombatEvents`) are the only way to see creatures: there is no call that lists a
  scene's creatures. A creature's level shows only when it is the target and Animal Lore allows it.
- `ShroudOnGatherResults` node is the resource name for mining and harvesting, and **the creature's name
  for field dressing**. Its `items` include "N Producer Experience" entries that are not items (filtered).
  An interrupted harvest sends nothing (see "Interrupted harvests" above). Corpse and chest loot has no
  source.
- Group slots in recipes list at most 30 choices; the larger "any item of this kind" groups are truncated
  (`complete: false` in `groups`). Names repeat, so groups are identified by `groupKey`.
- `Shroud.UI` windows start closed; `Show()` is refused for 3 s after the player closes it
  (so clicking a recipe again right after closing its window does nothing until 3 s have passed). That
  is the game protecting players from misbehaving add-ons: **leave it alone, do not work around it** (no
  retry loops, no fresh window ids to dodge it). Darren decided this on purpose. Change
  callbacks can fire before `ShroudOnStart` has built the windows, so guard them.
- The game has a hotkey that switches tooltips off. While they are off the `...UnderMouse` calls see nothing,
  so `/slore capture` and `/slore hoverlog` capture nothing, and the plugin can't tell that from "not pointing at
  an item". Nothing to do about it for now; the capture-on message in chat reminds the player.
- Lua cannot open the folder, run slash commands or reach the clipboard. `/lua path` (typed by the player)
  opens the output folder.

## Working style

- Keep `main.lua` in the plain style it has: local helpers, comments for the non-obvious "why".
- One topic per PR. Do not commit or open a PR unless asked; describe in the PR what is verified in game
  and what is not.

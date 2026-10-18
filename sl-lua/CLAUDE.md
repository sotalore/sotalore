# CLAUDE.md (sl-lua)

Notes for the agent working on the SotaLore in-game Lua plugins. The repo-root `CLAUDE.md` still applies
(notably: do not stage or commit unless asked). Work only inside `sl-lua/`.

## What this is

Two Lua add-ons (packages) for *Shroud of the Avatar*, one folder each. A package folder must be flat (no
subfolders), and its folder name is its slug:

| Folder (= slug) | Name | For | Global table |
|-----------------|------|-----|--------------|
| `sl-admin/` | SotaLore Admin | site admins: recipe, item and per-scene find exports, as files to upload | `SotaLoreAdmin` |
| `sl-skills/` | SotaLore Skills | players: copy their trained skills into the site's skill planner | `SotaLoreSkills` |

Until 2026-10-18 there was one package, `sl-recipes`; it became `sl-admin` (the skills work moved out).

- **The two must stay independent.** All add-ons share one global environment, so they never use the same
  global name, and `sl-skills` must not use anything from `sl-admin`: most players will only have `sl-skills`.
  Each has its own small `core.lua`; a little duplication (JSON helpers) is the price of that.
- Each has its own `manifest.json` (load order and package metadata) and its own version number. Every file
  either writes starts with `"plugin"` (the slug) and `"pluginVersion"`.
- The shared docs stay here at the top of `sl-lua/`, outside the packages:
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

`sl-admin/`:

| File | Job |
|------|-----|
| `core.lua` | creates the one global table `SotaLoreAdmin`; shared helpers in `SotaLoreAdmin.util` (JSON writing, text clipping, file writing, `perItem`) and file names in `SotaLoreAdmin.files` |
| `recipes_export.lua` | `SotaLoreAdmin.RecipeExport`: known recipes to JSON files, the "already exported" list |
| `item_details.lua` | `SotaLoreAdmin.ItemDetails`: captures what item tooltips say (quest item, tool, no trade, salvage lists) by hovering, `/sladmin capture` |
| `items.lua` | `SotaLoreAdmin.Items`: the items file for the bags; exports only new or changed items (`new`), everything (`all`) or marks them exported (`baseline`), in time slices |
| `finds_data.lua` | `SotaLoreAdmin.Finds`: the per-scene find list (items, creatures, nodes), saving it, writing the finds file |
| `finds_ui.lua` | `SotaLoreAdmin.FindsUI`: the small finds window |
| `recipes_ui.lua` | `SotaLoreAdmin.RecipesUI`: the recipe list and recipe windows, with the export buttons |
| `hoverlog.lua` | `SotaLoreAdmin.HoverLog`: a diagnostic (`/sladmin hoverlog`) that writes the tooltip text of items under the mouse to chat |
| `main.lua` | the only file with `ShroudOn...` callbacks, the `/sladmin` command and the key binding; read it first |

`sl-skills/`:

| File | Job |
|------|-----|
| `core.lua` | creates the one global table `SotaLoreSkills`; a few helpers in `SotaLoreSkills.util` (JSON writing, file writing, the file header) |
| `skills.lua` | `SotaLoreSkills.Skills`: the trained skills (`ShroudGetSkills`), the skills file, and the paged base 36 code the player copies into the site |
| `skills_ui.lua` | `SotaLoreSkills.SkillsUI`: the skills window with the code in a text box, pages, Refresh and Save file |
| `main.lua` | the `ShroudOn...` callbacks, the `/slskills` command and the key binding |

Rules for keeping them working:

- The files of a package run in the order its `manifest.json` lists them and share one environment. A file
  may only use modules from files listed **before** it (at load time). A new file must be added to the
  manifest.
- Everything is `local` except the package's single global (`SotaLoreAdmin` or `SotaLoreSkills`). Share things
  between files by hanging them on it. Check with `luac -o NUL -l -l file.lua` that a file reads no stray
  globals (a local function used before it is defined shows up as one).
- Files can't load each other (`require` and `dofile` are not allowed) and the `Shroud...` functions don't
  exist while a file loads: **do not call the game's API at the top level of a file**, only inside
  functions (`Shroud.UI` is the one exception). `local UI = Shroud.UI` at the top is fine.
- Only `main.lua` defines `ShroudOn...` functions; each should just call into a module. (The game keeps each
  package's callbacks apart, so both packages having a `ShroudOnStart` is fine.)
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

- The game loads a package only from `Lua/<slug>/`. Each package folder here is linked into the game's Lua
  folder with a **Windows junction**: `...\Catnip Games\Shroud of the Avatar(DEV)\Lua\sl-admin` to
  `C:\dev\sotalore\sl-lua\sl-admin`, and `...\Lua\sl-skills` to `C:\dev\sotalore\sl-lua\sl-skills` (before the
  split a single junction `Lua\sl-recipes` pointed at `sl-lua`). Edit here (`C:\dev\sotalore\sl-lua`), never
  through the game's path: that once failed with odd "file already exists" errors. Remove a junction with
  `cmd /c rmdir <path>`, which removes only the link; a recursive delete can go through it into the repo.
- The plugins' output files are written to the game's `Lua/` folder, **one level above the plugin folders**
  (`sotalore-export.json`, `-one.json`, `-items.json`, `-finds.json`, `-skills.json`), not into `sl-lua/`. To
  use one as an example, copy it from there into `data/plugin-examples/`.
- **Saved variables are kept per slug**: `Lua\SavedVariables\<slug>.account.json` (and per character). Renaming
  a package starts it with empty saved data unless that file is copied to the new slug's name while the game
  is closed or logged out (the game writes it at logout). `sl-recipes.account.json` was the admin plugin's.
- **The game cannot be launched from this session.** A standalone Lua (5.5, installed with scoop; `lua` and
  `luac` on the PATH) is available on Darren's machine: use `luac -p file.lua` to syntax-check every file
  after an edit. For behaviour, write a throwaway fake-game script (stub `Shroud.UI`, `Shroud.Command`,
  the `Shroud...` getters and saved variables, then call the `ShroudOn...` callbacks) and compare the output
  files with the previous version's; the 0.5.1 refactor was verified that way (old single file vs the
  modules gave byte-identical output). It is only a fake game, and the game's interpreter is older
  (5.2-style), so say plainly that a change is untested in game. Darren tests in game (`/lua reload`,
  `/lua check sl-admin`, `/lua check sl-skills`) and reports errors or pastes the output files.
- Edit tool calls in parallel on one file can collide; make edits to one file one at a time.
- Bump a package's version together in its `core.lua` (`local Version`) and its `manifest.json`, and mention
  it in `EXPORT-FORMAT.md` where a format changed.

## Naming rules for every SotaLore plugin

Keep every plugin (these two and any later one) named the same way, so players and admins can guess the
command from the plugin's name. For a plugin about `<name>`:

| What | Rule | sl-admin | sl-skills |
|------|------|----------|-----------|
| Folder and slug | `sl-<name>` | `sl-admin` | `sl-skills` |
| Display name (manifest `name`, `ScriptName`) | `SotaLore <Name>` | SotaLore Admin | SotaLore Skills |
| Slash command | `/sl<name>` (lower case, no hyphen; the game allows `[a-z][a-z0-9]{2,23}`) | `/sladmin` | `/slskills` |
| Key binding label | `SotaLore <Name>: ...` | SotaLore Admin: toggle list | SotaLore Skills: toggle window |
| Window titles | start `SotaLore` | SotaLore: Known Recipes, SotaLore Finds | SotaLore Skills |
| Chat lines | the game prefixes `[Add-on: <display name>]` itself | | |
| Output files | `sotalore-<kind>.json`, `"plugin"` = the slug in the header | | `sotalore-skills.json` |
| Global table (the only global the plugin defines besides its `ShroudOn...` callbacks) | `SotaLore<Name>` | `SotaLoreAdmin` | `SotaLoreSkills` |

`/sotalore` itself is refused by the game ("sota" is a reserved prefix), which is why the prefix is `sl`. Before
2026-10-18 the admin plugin's global was `SotaLore` and its command `/slore`.

## Slash commands, windows, saved data

- `sl-admin`: `/sladmin` (until 2026-10-18 `/slore`). Subcommands: `export`,
  `exportall`, `baseline`, `new` (open the list showing only recipes "Export new" would export), `items` (new or
  changed items), `itemsall`, `baselineitems`, `finds` (toggle the finds window), `savefinds`, `clearfinds`,
  `gatherlog`, `checkrecipes`, `capture`, `hoverlog`; other text searches the recipe list. The command's help
  text must be at most 120 characters.
- `sl-skills`: `/slskills` opens the skills window, `/slskills file` saves the skills file.
- An add-on may own at most **8 windows**. `sl-admin`: the list (1), the finds window (1) and up to 6 recipe
  windows. `sl-skills`: the skills window.
- `sl-admin` account-scope saved variables: `exported` (recipe ids already exported; "Export new" = not in it),
  `itemSigs` (a fingerprint per item for what was last exported; no catalog of items is kept), `itemDetails`
  (captured tooltips), `finds` (the per-scene list), `track` (tracking toggle). `sl-skills` keeps none.
## API facts learned in play (docs are at https://catnipgames.net/lua/reference.html)

- Read the docs by downloading the page, stripping the HTML to text and searching it; a summarising
  fetch loses detail. The docs and the live API can differ and the API version moves (it was 40).
- **Bag item `weight` and `value` are for the whole stack**, not "one item" as documented. The plugin
  divides by `quantity` (`perItem`). Darren was going to file this as an API bug; if the game fixes it,
  `perItem` would then divide wrongly, so re-check against a recipe's per-item weight first. Some stacks report
  no `quantity` (missing or 0; three potions, found by the site agent): the number can't be made per-item, so
  `util.perItem` returns nil (null in the file) and `ItemDetails.perItem` then tries the captured tooltip, which
  shows "Quantity: 638 | Stack Weight: 191.4 | Stack Value: 6,380" for a stack (so that potion is 0.3 and 10 gold).
  Before 0.8.1 it passed the raw stack total through. The tooltip's "Merchant pays" for a stack is also a whole-stack
  price (divided by the quantity), and tooltip numbers use thousands commas ("6,380").
- **A crafted item's salvage list is its own** (it depends on the materials), not the kind's, although it shares
  the base item's `key`. The tooltip title of crafted gear ends with the base item's name in brackets; the plugin
  exports the title (`details.title`) so the site can use it.
- **`ShroudGetRecipe(id)` can return nil for a recipe `ShroudGetKnownRecipes` lists** (first seen with newly
  learned recipes: the detail window said "You no longer know this recipe" and exports silently dropped
  them). `util.getRecipe(id, categoryKey)` falls back to `ShroudGetRecipeBook(categoryKey)`; exports now warn in
  chat about recipes they could not read, and `/sladmin checkrecipes` lists the unreadable ones. On Darren's
  character 103 of 1,234 known recipes failed (Alchemy gem fragment and fracture recipes, Tanning fishing-trophy
  recipes); the recipe book had them. Before 0.5.2 they were silently left out of every export. Cause unknown.
- **The game stops a callback that runs longer than 1 second (5 seconds while the plugin starts).** The guide says
  to spread work across frames or use `ShroudRegisterPeriodic`. Long jobs here (the recipe export, `/sladmin
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
  so `/sladmin capture` and `/sladmin hoverlog` capture nothing, and the plugin can't tell that from "not pointing at
  an item". Nothing to do about it for now; the capture-on message in chat reminds the player.
- Lua cannot open the folder, run slash commands or reach the clipboard. `/lua path` (typed by the player)
  opens the output folder.

## Working style

- Keep `main.lua` in the plain style it has: local helpers, comments for the non-obvious "why".
- One topic per PR. Do not commit or open a PR unless asked; describe in the PR what is verified in game
  and what is not.

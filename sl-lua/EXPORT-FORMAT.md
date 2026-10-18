# SotaLore plugin export format (plugin v0.9.0)

Context for an AI session working on importing this data into a fansite database for the game
*Shroud of the Avatar*. The data comes from an in-game Lua addon (SotaLore; folder/slug `sl-recipes`, in this folder).
Lua API docs: https://catnipgames.net/lua/reference.html (needs Lua API 37+).

## What produces the files

The slash command is `/slore` (`/sotalore` is refused by the game: "sota" is a reserved prefix).


The addon writes JSON files into the game's `Lua/` folder (Lua cannot POST, has no clipboard). The files are
named `sotalore-<kind>.json`; before plugin 0.7.0 they were called `sl-recipes-<kind>.json` (same contents and
shapes), so an older file may still carry that name.

| File | Written by | Contents |
|------|-----------|----------|
| `sotalore-export.json` | "Export new" / "Export all" buttons, `/slore export`, `/slore exportall` | many recipes |
| `sotalore-one.json` | "Save this recipe to file" in a recipe window | one recipe |

Both files have the same shape. Each export overwrites the previous file of that name.
"Export new" sends only recipes not exported before (remembered per account); "Export all" sends
every recipe the character knows. `/slore baseline` marks everything as already exported. In the recipe list, the "New only" toggle (or `/slore new`) shows exactly the recipes "Export new" would send.

**Each recipe `id` appears once in a file** (plugin v0.7.2 and later). A `sotalore-export.json` written by 0.7.1 or
earlier can repeat recipes: if the game stopped the plugin part way through an export (it does when a callback runs
over a second), the batch it was reading was written twice (10 recipes, identical both times, in the one file seen).
The game's own list of known recipes has no repeats. If an importer sees a repeated `id`, the entries are the same
recipe: use either.

A recipe the game lists but will not hand over (`ShroudGetRecipe` returns nothing, and the recipe book does not
have it either) is left out of the file and is **not** marked as exported; the plugin says so in chat after the
export ("WARNING: N recipes could not be read and are NOT in the file"). So `count` can be lower than the number
of recipes the character knows, and the missing ones keep showing up as new.

**Full exports made before plugin v0.5.2 are incomplete.** Until then the plugin dropped every recipe that
`ShroudGetRecipe` could not read, without saying so. On the author's character that was 103 of 1,234 known
recipes (the file had 1,131): Alchemy gem recipes such as Combine Gem Fragments and Fracture Gem/Jewel, and
Tanning trophy recipes such as Arapaima Trophy, Peacock Bass Trophy and Spotted Bass Trophy. Plugin v0.5.2 reads
them from the recipe book instead, so a fresh `"scope": "all"` export has all of them. Do not retire site
recipes because an older full export lacks them.

## Hard limits of the source (the API cannot do these)

- **Only recipes the character has learned.** No unlearned recipes, no "how it is learned/taught".
  Merge exports from several characters; recipe `id` is the merge key.
- No item properties beyond name, key, quantity and stat rows (no price, notes, source, use).
- Nothing about the character is exported (carried counts are deliberately dropped).
- Recipes that roll their product from a list have `results` = `[]` (no fixed yield).

### Items file

`sotalore-items.json` (the "New items" and "All items" buttons, `/slore items`, `/slore itemsall`) lists the items in
the character's top-level bags (not worn gear, nested containers, bank or chests). The bags hold many things that
never leave (gear, quest items, tools), so like the recipe files it has a `scope`:

| `scope` | Written by | Meaning |
|---------|-----------|---------|
| `"new"` | "New items" / `/slore items` | only items not exported before, or **changed** since: the weight or value is different, or details were captured or changed by hovering. Never the whole list, even if it happens to hold everything. |
| `"all"` | "All items" / `/slore itemsall` | every item in the bags, plus any item whose tooltip was captured earlier. |

`/slore baselineitems` marks everything in the bags as already exported without writing a file (for items the
site already has). The plugin remembers what it last exported as a short fingerprint per item (it does not keep a
catalog of items between exports, so nothing grows however many items turn up), shared by all of the account's
characters. A file from before plugin v0.8.0 has no `scope` and was always the whole list (an accumulating catalog
of every item seen).

```json
{ "apiVersion": 40, "pluginVersion": "0.8.0", "type": "items", "scope": "new", "count": 2, "items": [
  {"key": "item:...", "name": "Wax", "weight": 0.05, "value": 1, "createdBy": "", "details": null}, ... ] }
```

`key` is the same item key used in recipes (join on it). `weight` is for one item; `value` is thegame's gold value for one item (not verified to be the same as the fansite `price`). Items with no
key are skipped. Each entry also has `createdBy`, the API's field of that name. **Do not rely on it to spot
crafted items:** in play it is empty even for items whose tooltip says "Crafted by <player>" (two crafted daggers
both read `createdBy` empty and a `creationDate` of "January 1, 0 PC"), so it is probably not the crafter. If it
is ever filled, the same `key` can appear more than once, once per `createdBy` value. Crafted items of one kind
share the base item's `key` ("Bronze Dagger +10" and "+11" are one key, with the +N in the name). The API has
no "locked", "quest item", "bound" or item-type
flag (the only item fields are name, quantity, weight, value, key, icon, durability,
createdBy/creationDate/creationScene, fish length, and PvP trophy provenance), so quest items cannot be told
apart from other items here. **Names can carry formatting markers** (for example `[u]The Cleansing Manifesto[/u]`):
that is the game's own text, passed through unchanged, so strip markers like `[u]`, `[/u]` before matching by name.

**`details`** is what the item's tooltip said, captured while the player pointed at the item in the bags with
capture on (the "Capture" toggle next to "Export my items", or `/slore capture`; the API has no field for any of it), or `null` for an item that was never hovered. It is keyed by
the item `key`, so every entry of that key shares it. Holding Ctrl while hovering gives the full tooltip.
The tooltip is English text, so these flags depend on the game language.

```json
"details": { "crafted": false, "types": ["Quest Item"], "questItem": true, "artifact": false, "tool": false, "consumable": false,
             "noTrade": true, "noSell": false, "noValue": false, "indestructible": false,
             "merchantPays": null, "effects": [],
             "text": "Vigilante Plans Stage 2\nQuest Item\nValue: 0\nNo Trade",
             "yields": null, "salvage": [] }
```

- `types` is the list of tooltip lines that name a kind of item, in tooltip order. **One item can have several**: the
  Shroud of the Avatar reads `["Avatar Artifact", "Cloak", "Quest Item"]`, Bonesteel Crown `["Dread Artifact",
  "Universal Heavy Armor (Head)", "Quest Item"]`. Values seen: Quest Item, Tool, Consumable, Fishing Bait, Ammo,
  Artifact, Dread Artifact, Avatar Artifact, Music Instrument, Offhand Item, Necklace, Ring, Cloak, and armor and
  weapon lines such as "Leather Light Armor (Head)", "Longsword - Bladed", "Mace - Bludgeon" (which is the best
  hint for the site's `use`). **There is no list of kinds: a type line is recognised by its shape** (short, not the
  title, no colon, digit, percent, plus, comma, full stop, ! or ?, and not "No Trade", "Equipped" and similar), so it
  is a heuristic that can miss an unusual line or take a short description for a type. `text` is always complete.
  Files written before plugin 0.6.2 have no `types`.
- The flags come from tooltip lines: `questItem` "Quest Item", `artifact` a line "Artifact" or ending " Artifact"
  (Dread Artifact, Avatar Artifact), `tool` "Tool", `consumable`
  "Consumable", `noTrade` "No Trade", `noSell` "Cannot be sold to merchants", `noValue` "No Value", `indestructible`
  "Durability: Indestructible". "Equipped" is a state of the one item, not of the kind, so it is not stored.
- Everything in `details` except `crafted` items is worked out **when the file is written**, from the tooltip text
  stored at capture time (plugin v0.7.3 and later), so an item captured by an older plugin version gets today's
  rules without being hovered again. In a file from before 0.7.3, `types`, `artifact` and similar can be missing
  or empty for older captures even though `text` shows them: read `text` if in doubt.
- `merchantPays` is the tooltip's "Merchant pays: 100 - 125" as `{min, max}` (a single number gives min = max), or
  `null` when the tooltip has no such line. That is what a merchant pays for it, which may be the site's `price`.
  **It is per item.** For a stack the tooltip gives the whole stack's price ("Quantity: 638 ... Merchant pays: 5,104 -
  6,380"), so the plugin divides it by the stack's quantity (8 - 10). Numbers with thousands commas are read correctly
  (plugin v0.8.1 and later; before that a stack's price was written whole, and a comma number was misread).
- `effects` is the list under the tooltip's "Item Effects" heading, for example "+1 Double Slash Attack Count Bonus",
  as plain strings; empty when there is no such heading.
- `text` is the whole tooltip, one line per line, for anything else (the type line such as "Dagger - Bladed", bonuses,
  the description). **It also holds state of the one item that was hovered**: "Quantity: 6", "Durability: 35/35",
  "Major Repairs: 0", masterwork and engraving lines. Treat those as noise, and the first hovered item of a kind is
  not necessarily typical (a masterworked tool, for example, still reads "Tool").
- `salvage` is the tooltip's "Salvage Components" list: `{name, min, max, chance}` where `min`..`max` is how many
  of that item comes back and `chance` is the percentage ("Metal Scrap  1 - 50  90.5%" is min 1, max 50, chance 90.5; a
  single number gives min = max). `yields` is the "Salvage or Reshape Yields:" line, when there is one.
- `title` is the tooltip's first line. For gear that was crafted and then given a pattern it ends with the base item's
  name in brackets, for example `Supple Virtue Aeronaut Boots +15 (Supple Fortified Leather Boots +15)`, while the
  item's `name` is only the part before the brackets. It is the closest thing the tooltip gives to "what it was made
  from" (plugin v0.8.1 and later; older captures have `null`).
- **A crafted item** (tooltip "Crafted by <name>") is unique, so for it only `crafted: true`, `title`, `salvage` and
  `yields` are stored; the flags and `text` are left out of `details` for it. **Its salvage list is that one item's, not
  the kind's**: it depends on what the item was made of (Epic Leather Boots +13 give Yard of Simple Leather, Supple Epic
  Leather Gloves +12 give Yard of Supple Leather, Bronze Dagger +11 gives Bronze Hilt and Bronze Dagger Blade), although
  they share the base item's `key`, and a reshaped item's "Eternal Pattern" yields line is its own too. Only use a
  crafted item's salvage if its name, less "+N" and any "of ..." enchantment, is the base item's name.
- An item that is not in the bags when hovered (a chest, a vendor) can't be tied to a key and is skipped.
- Entries can appear for items that are no longer in the bags, if they were captured earlier.

Not yet verified against a real file.

### Finds file (items and creatures per scene)

`sotalore-finds.json`, written by the **Save** button of the "SotaLore Finds" window (open it with the
list window's "Finds window" button or `/slore finds`; `/slore savefinds` also saves). The small window
is meant to stay up during play: it shows the current scene, how many distinct items and creatures are on
the list, and has **Save** (writes the file, keeps the list), **Reset** (clears the list; needs a second
click within 4 seconds) and a **Tracking** toggle (turn it off while banking or shopping, which the API
cannot tell apart from loot). The list accumulates account-wide across sessions and characters until
reset (`/slore clearfinds` resets without the confirmation click). Save never clears; Reset is separate.

**Items.** The addon listens to the game's `ShroudOnItemsGained` callback (the backpack's "Recently
Looted" rule) and credits every gain to the scene the character is in. It counts: loot from bodies and
chests, purchases, harvests, mail taken, accepted trades, and items taken out of a bank, a lot chest or a
crafting station. It does NOT count: locked/other items already owned, moving items between bags,
equipping, logging in, changing scenes. Gains while the crafting window is open are ignored.

**Creatures.** The API cannot list what is in a scene, so the addon records the creatures the player
fights: from the combat lines (`ShroudOnCombatEvents`), the opponent in any hit, miss, block, parry,
dodge or death line that involves you or your pet (the target when you or your pet act, the source when
you or your pet are hit). Only creatures that actually fight you show up: nothing that is just standing
nearby, and nothing the player only talks to. Heals and falls are ignored. PvP scenes and battlegrounds
are skipped entirely, since the opponents are players. A creature is counted once per individual per
visit to a scene (using the combat line's per-scene creature key, which the API does not expose as an id).

**Nodes.** When a gathering action finishes (`ShroudOnGatherResults`), the addon records the node's name and
what its loot window held. This is the only place a gathered item is tied to where it came from. Seen in
play: mining and harvesting give the resource node's name ("Copper Vein", "Cotton Plant", "Maple Tree"),
and **field dressing a corpse gives the creature's name** ("Rabbit", "Small Wolf Spider"), so the items of
a field-dressed creature (Leather Scrap, Spider Silk, Venom Sack, even the carcass itself) are tied to that
creature. Nothing tells the two kinds apart in the data; a name that is also in `creatures` is a creature.
An interrupted harvest sends nothing. The loot window also lists the experience reward as items ("60
Producer Experience", once per swing); those are dropped and the reward is in `experience` instead. The same
items also arrive through `ShroudOnItemsGained`, so they are still counted under `items` as well; `nodes`
is the attribution, not extra stock. Each result is also written to chat as `SotaLore gather: node=...`
while the gather log is on (default on; `/slore gatherlog` toggles it) so unknown node kinds can be seen.
Loot taken from a corpse or chest has no source in the API, so it is not attributed to anything.

```json
{ "apiVersion": 40, "pluginVersion": "0.7.1", "type": "finds", "scenes": [
  { "scene": "Scene Name", "rawName": "InternalSceneName",
    "info": { "isOverworld": false, "isDungeon": true, "isBasement": false, "isSiege": false,
              "isBattleground": false, "isPvp": false, "isPot": false, "maxPlayers": 8,
              "levelCap": 0, "skillCap": 0, "craftingSkillCap": 0 },
    "items": [ {"key": "item:..." , "name": "Wax", "quantity": 12, "times": 4,
                "weight": 0.05, "value": 1} ],
    "creatures": [ {"name": "Wolf", "seen": 7, "levelMin": 4, "levelMax": 6} ],
    "nodes": [ {"name": "Iron Ore Vein", "harvests": 5, "failed": 1, "experience": 120,
                "items": [ {"name": "Iron Ore", "quantity": 16} ] } ] } ] }
```

`scene`/`rawName` are the game's display and internal scene names (as `ShroudGetSceneInfo` gives them;
overworld tiles are not split out). `info` is the scene's details from `ShroudGetSceneInfo`: the kind
flags (`isOverworld`, `isDungeon`, `isBasement`, `isSiege`, `isBattleground`, `isPvp`, `isPot`),
`maxPlayers`, and the caps (`levelCap`, `skillCap`, `craftingSkillCap`; the example values above are
placeholders, a scene with no cap probably reads 0 or -1, not yet verified). It is the scene's details as
last seen when something was recorded there, so it is `null` only for finds recorded before this was
added. Not in the API, so not exported: scene type (town, mine, control point...), region, tier, parent
map, and a player dungeon's owner or name (the owner is a player, so it is deliberately left out).

Items: `quantity` = total units gained, `times` = number of separate gain events. `key` is `null` when the
item could not be matched to a top-level bag item (for example it went straight into a nested container);
such items are identified by name only. `weight`/`value` come from the matching bag item and are
**per item**. The API says so but actually reports the numbers for the whole stack (a stack of 31 Animal
Hide read 12.4 where the recipe stats say 0.4 each), so the plugin divides by the stack size and rounds to 4
decimals. This correction is in plugin 0.4.0; finds or catalogs saved by earlier versions hold stack totals
for weight and value, so reset the list and treat older files as wrong for those two fields. Prefer the
recipe stat-row `weight` where an item has one.

**When the game reports no stack size** (a missing or zero `quantity`; seen on three potion stacks) the number
cannot be made per-item from the API's numbers. From plugin v0.8.1, if the item's tooltip was captured and shows a
stack ("Quantity: 638 | Stack Weight: 191.4 | Stack Value: 6,380"), the per-item numbers come from it (weight 0.3, value
10; the weight only when the stack weighs 10 or more, because the tooltip rounds it); otherwise `weight` and `value`
are `null` for that item, in the items and finds files alike. Before 0.8.1 the raw stack total was written instead
(Cure Plague Potion: weight 191.4, value 6380 for 638 potions); such numbers are not rounded to 4 decimals, which is
how to recognise them. So a `null` weight or value means "not known", and hovering the item with capture on can fill it.

Nodes: `name` is the node's name as the game gives it (the example above is made up; real ones seen:
Copper Vein, Cotton Plant, Maple Tree, and creature names for field dressing). `harvests` counts finished nodes, `failed` how many of those failed, `experience` the
producer experience they paid, `items` what the loot windows held, by name and total quantity (no item
keys here; join to `items` by name). A scene with no gathering has an empty `nodes` list; older saved
finds have none.

Creatures: `name` is the name the combat line prints (creatures of one name are merged; the API gives
no creature type or id). `seen` = individuals fought, summed over visits. `levelMin`/`levelMax` are the
creature's level when it was the player's current target and the game's Animal Lore rule lets the level
be read; otherwise `null`. A scene with only creatures has an empty `items` list and the reverse. Not
yet verified against a real file, including whether creature names match the site's.

### Skills (file and code), plugin v0.9.0, under evaluation

The site keeps, per avatar, each skill's current level and a target level. The target exists only on the site;
the current level comes from `ShroudGetSkills()`, which lists only the skills the character has **trained** (an
untrained skill is simply absent: read it as level 0). The level used is `trainedLevel` (what the experience has
bought), not `level`, which a scene's skill cap can lower. The "Skills window" button (or `/slore skills`) shows the
skills; `/slore skillsfile` or the window's "Save file" writes `sotalore-skills.json`.

**The file** (`"type": "skills"`) has the header, `character` (the avatar's name) and `skills`, one entry per trained
skill, sorted by `id`: `id` (the game's stable number), `key` (the game's stable name, e.g. "Fireball"), `name`,
`school`, `schoolKey`, `subcategory` (the names the skills window shows, in the player's language), `trainedLevel`,
`level`, `effectiveLevel`, `experience`, `grandmaster`, `mode`. It is for loading the skill list into the site
once (matching the site's own skills to the game's ids) and for checking sizes.

**The code** is for the player to copy and paste without saving a file. A plugin text box holds at most 1024
characters and Lua cannot reach the clipboard, so the code is cut into pages of up to 1000 characters; the window
shows one page at a time and the player copies each in turn (click the box, Ctrl+A, Ctrl+C). A page reads

    SLS1|<page>/<pages>|<id digits>|<o or ->|<character>|<entries>|<check>

`SLS1` is the format. `<entries>` is a run of fixed-width entries, each a skill `id` then its `trainedLevel`, both
**base 36, lower case**: the id in `<id digits>` characters, the level in 2. If any id is negative the plugin adds
2147483648 to every id and writes `o` in the fourth field (subtract it again); otherwise it writes `-`.
`<check>` is two base 36 digits: with `sum = 0`, for each byte `b` of `<entries>`: `sum = (sum * 31 + b) mod 1296`;
the check is `sum` in 2 digits. The pages of one code have the same `<pages>` and `<id digits>`, and the
site should accept them in any order. The character name has `|` and control characters removed.

Not decided yet: how many pages a real character needs (that depends on the real skill ids), and whether to send
ids at all or something the site can map more compactly.

## Every file starts the same way

Every file the plugin writes begins with the same three fields (added in plugin v0.7.1):

```json
{ "apiVersion": 40, "pluginVersion": "0.7.1", "type": "recipes", ... }
```

| Field | Meaning |
|-------|---------|
| `apiVersion` | The game's Lua API version when the file was written. |
| `pluginVersion` | The version of the plugin that wrote the file (`major.minor.patch`). It is the plugin's `Version` in `core.lua` and `manifest.json`. |
| `type` | What kind of file it is: `"recipes"` (`sotalore-export.json` and `sotalore-one.json`, which also have a `scope`), `"items"` (`sotalore-items.json`) or `"finds"` (`sotalore-finds.json`). Use it to refuse a file uploaded to the wrong place. |

**Files written before 0.7.1 have no `pluginVersion` or `type`** (the file name says the kind). Their plugin
version is unknown, so treat a missing `pluginVersion` as "older than 0.7.1", not as any particular version. This
matters for one thing: a `"scope": "all"` recipe file from before **0.5.2** is missing the recipes the game would
not hand over (about 100), and cannot be told apart from a complete one without the version.

## File shape

The recipe files (`"type": "recipes"`):

```json
{
  "apiVersion": 40,
  "pluginVersion": "0.7.1",
  "type": "recipes",
  "scope": "all",
  "count": 1142,
  "recipes": [ { ...recipe... }, ... ],
  "groups":  [ { ...group... }, ... ]
}
```

`apiVersion` is the game's Lua API version when the file was written. `count` = number of recipes.

`scope` says what the file holds (added in plugin v0.3.0; files from earlier versions have no `scope`,
so treat a missing one as unknown):

| `scope` | Written by | Meaning |
|---------|-----------|---------|
| `"all"` | "Export all" / `/slore exportall` | every recipe the character knows. Only this scope is a full export, the only kind that can show a recipe is gone from the game. |
| `"new"` | "Export new" / `/slore export` | only recipes not exported before. Never a full export, even if it happens to hold everything. |
| `"one"` | "Save this recipe to file" | exactly one recipe (`sotalore-one.json`). |

A recipe book can differ between characters, so even an `"all"` file only covers what that one character
knows; the uploader still decides whether to treat it as the whole game.

### Recipe

```json
{
  "id": 1969281546,
  "name": "Tall Rustic Cabinet",
  "category": "Carpentry",
  "categoryKey": "Crafting_Carpentry",
  "requiredLevel": 40,
  "refine": false,
  "station": "Carpentry Station",
  "locations": ["any"],
  "ingredients": [ ... ],
  "results": [ ... ]
}
```

| Field | Meaning |
|-------|---------|
| `id` | The game's recipe id. A **signed 32-bit integer and can be negative** (seen: 1969281546 and -2138056863), so the column must be a signed int; NOT the fansite's own id. Store as `game_recipe_id`. Believed stable across characters; not yet confirmed across patches. |
| `name` | Recipe name as the recipe book shows it. |
| `category` | Crafting skill display name (localized). |
| `categoryKey` | Same as the station key, never translated, e.g. `Crafting_Carpentry`. |
| `requiredLevel` | Required skill level. Equals the fansite's `proficiency`. |
| `refine` | true for refining recipes (31 of 1,142 in the first dump). |
| `station` | Name of the crafting station (localized). May be absent on old clients. |
| `locations` | `["any"]`, or `"Novia"` and/or `"HiddenVale"` when the recipe can only be made at stations there. |
| `results` | List of result items. **Absent** (not empty) when the client is below API 24. Empty list = random product / no fixed yield. |

`categoryKey` values seen: Crafting_Carpentry, Crafting_Milling, Crafting_Textiles, Crafting_Smelting,
Crafting_Alchemy, Crafting_Blacksmithing, Crafting_Cooking, Crafting_Tailoring, Crafting_Tanning,
Crafting_Butchery, Crafting_ObsidianForge, Crafting_ObsidianForge_SinglePlayer. The Obsidian Forge
ones are recipes tied to a station inside a dungeon; map them to a normal skill on the import side.

### Ingredient

```json
{
  "name": "Wooden Board", "quantity": 2, "optional": false, "tool": false,
  "key": "item:0123456789abcdef0123456789abcdef",
  "stats": [ {"key": "weight", "value": 1.5} ],
  "group": true, "groupKey": "group:123", "choiceCount": 7,
  "choices": [ {"key": "item:...", "stats": [ ... ]} ]
}
```

| Field | Meaning |
|-------|---------|
| `name`, `quantity` | Item name (localized) and count needed. |
| `optional`, `tool` | `tool: true` corresponds to the fansite item `use = "tool"`. |
| `key` | The game's item id: `item:` + 32 hex digits, same in every language. Present on plain ingredients; absent on group slots (the slot is a group, the members have keys). Also absent on a few generic placeholders in Repair/Salvage/Sow Seed recipes ("Worn Item", "Salvageable Item", "Seed"): match those by name. |
| `stats` | Plain ingredients only. Rows of `{key, value[, name]}`: the item's weight, and what this recipe's quantity of it adds to the finished item (recipe-specific). |
| `group` | Present and true when the slot accepts any member of a group (the fansite's "abstract" items, e.g. Wooden Board, Metal Sheet). |
| `groupKey` | `group:<number>`. Identifies the group; members are in the top-level `groups` list. |
| `choiceCount` | How many members the group has in total. |
| `choices` | Per-member `key` and recipe-specific `stats`. May be shorter than `choiceCount`. Names are in `groups`. |

### Result

```json
{ "name": "Crimson Pine Binding", "quantity": 4, "key": "item:...", "stats": [ ... ] }
```

`quantity` is the fixed yield of one successful craft before exceptional results and refining
bonuses. `stats` are the item's base values (weight, durability, weapon damage band, armour
resistance...), not including material bonuses.

### Stat rows

Units are not uniform: `critical` on a result is a percent (6 = 6%), but ingredient rows such as
`stat:WeaponCritBonus` are fractions (0.05 = 5%) and `stat:WeaponDamageBonus` is a flat amount. Treat
the numbers as the game's own display values and do not convert without checking the in-game tooltip.

`{ "key": "weight", "value": 1.5, "name": "Weight" }`. `key` is language-independent: `weight`,
`durability`, `damageMin`, `damageMax`, `critical` (percent), `parry`, `chargeSeconds`,
`resistance`, `avoidance`, or `stat:<Name>` (e.g. `stat:Strength`). `name` (only on stat rows) is the
localized label. `value` is a number, or `null` if it was not finite.

### Group (top-level `groups`)

```json
{ "groupKey": "group:123", "name": "Wooden Board", "choiceCount": 7, "memberCount": 7,
  "complete": true, "members": [ {"key": "item:...", "name": "Oak Board"} ] }
```

Members are merged (union) across every recipe in the file, sorted by `groupKey` and member `key`.
`complete` = `memberCount >= choiceCount`. When false the list is partial: a slot lists at most
30 choices, and a group too large to pick from lists only the materials the character carries.
Use it to check the fansite's own group membership; trust only `complete: true` groups to be full.

## Mapping to the existing fansite schema

Seen from one sample fansite recipe (id 1686, "Tall Rustic Cabinet"):

| Fansite | Export |
|---------|--------|
| recipe `id` | no equivalent: add a `game_recipe_id` column, fill from `id` |
| `craft_skill.key` (`carpentry`) | `categoryKey` minus `Crafting_`, lowercased (Obsidian Forge: map by hand) |
| `proficiency` | `requiredLevel` |
| `recipe_key` (`carpentry-38:1-709:1-1335:2`) | skill key + sorted `item_id:count` pairs. Rebuild it from ingredient names → `item_id` for the first match; afterwards match on `game_recipe_id` |
| ingredient `item_id`, `count` | match by `name` the first time; store the game's `key` on the item as a new column (e.g. `game_item_key`) so later syncs match by key |
| item `abstract: true` | an ingredient with `group: true`; members from `groups` |
| item `use = "tool"` | ingredient `tool: true` |
| `teachable`, price, notes, effects... | not available from the game |

Suggested first import: (1) match ingredients to items by name and record `game_item_key`;
(2) build the `recipe_key`, match recipes, store `game_recipe_id`; (3) list unmatched recipes and
unmatched ingredient names for manual review; (4) compare `groups` to the fansite's group tables.

## Verified against a real file

A real v0.2.0 single-recipe file (recipe "Spear", API 38) matches this document: station
"Carpentry Station", `locations: ["any"]`, two group ingredients (`group:13` "Spear Head", 9 members;
`group:49` "Wooden Handle", 8 members; both `complete: true`), one plain ingredient with `key`
(Wax x3), and one result with `key` and stats. The groups included some non-obvious members
(Light/Dark Unicorn Horn as Spear Head choices). A group's `name` is the slot's label, so use
`groupKey` as the identity. Group choices carry only `key` and `stats` inside the recipe; their
names are in `groups`.

## Verified against a complete full export (plugin 0.5.2)

`data/plugin-examples/sotalore-export.json`: `"scope": "all"`, API 40, **1,234 recipes** (the character knows
1,234; no duplicate ids, 604 negative), 3,994 ingredient slots (877 are group slots), 240 groups, 1.9 MB. Every
recipe has a `station`; every `locations` is `["any"]`; no stat `value` is `null`.

- **The 103 recipes older plugin versions dropped are in it**, with the same fields as any other recipe
  (station, ingredients with keys and stats, group slots, results with key and stats). Examples: Combine Gem
  Fragments, Fracture Gem/Jewel (Alchemy), Arapaima/Peacock Bass/Spotted Bass Trophy (Tanning). Counts per
  `categoryKey`: Carpentry 299, Blacksmithing 187, Smelting 162, Alchemy 127, Cooking 126, Tailoring 109,
  Tanning 101, Butchery 53, Milling 30, Textiles 26, Obsidian Forge 12, Obsidian Forge single-player 1,
  **Farming 1**. Note `Crafting_Farming`: dropping `Crafting_` gives `farming`, but the site's skill is called
  `agriculture`, so that one needs a mapping.
- 71 recipes have an empty `results` list (Reshape, Repair, and similar recipes with no fixed product).
- **10 ingredients are plain (not group) but have no `key`**: generic placeholders in the Repair Item,
  Salvage Item and Sow Seed recipes ("Worn Item", "Salvageable Item", "Seed"). They stand for "whatever
  item you choose", not a real item, so match them by name and do not expect a key.
- Groups: 202 are `complete: true`; 38 are cut off at exactly 30 members (see the note below) and 35 recipes
  use one of them.

The sections below describe an earlier full export (plugin 0.4.0, 1,130 recipes) that found the same
patterns; its group figures are superseded by the numbers above.

## Verified against an earlier full export

A full export from one character (API 38): 1,130 recipes (559 with negative ids, no duplicate ids),
3,759 ingredient slots (742 are group slots), 152 groups, file size 1.7 MB. Every recipe has a
`station`, and every `locations` is `["any"]`. Every plain ingredient and every result has a `key`.
60 recipes have an empty `results` list (random product), none are missing the field. No stat
`value` was `null`. Stations: one per skill, plus "Obsidian Forge" (13 recipes, categoryKeys
`Crafting_ObsidianForge` 12 and `Crafting_ObsidianForge_SinglePlayer` 1).

Groups: 117 are `complete: true` (largest has 27 members). The other 35 are all cut off at exactly 30
members: the API's per-slot limit. They are the large "any item of this kind" groups (reshape
targets such as "Tailoring Reshaped Item" with 370 choices, and "... Patterns" / "... Equipment"
groups of 30-350). For these the 30 listed members are an arbitrary subset (the game lists the ones
the character can craft with first, then carried ones), so do NOT treat their member lists as
complete or import them as authoritative; use `groupKey` and `choiceCount` only. 31 recipes use
such a group. Two different groups share the name "Gem Fragment": identify groups by `groupKey`,
never by name. Recipe count differs from an earlier export of the same character (1,142 vs
1,130), so the recipe book contents can change between runs.

## Known uncertainties

- Recipes read through the recipe-book fallback look identical to the others in the example file, but only
  by inspection of a few (the eight named above); there is no per-recipe marker saying which path was used.
- Recipe `id` stability across characters, patches and test/live servers.
- Whether ingredient names always equal the fansite item names (localization, renames).
- File size: with group choices and stats the file may be several MB.

# SotaLore plugin export format (plugin v0.2.0)

Context for an AI session working on importing this data into a fansite database for the game
*Shroud of the Avatar*. The data comes from an in-game Lua addon (SotaLore; folder/slug `sl-recipes`, in this folder).
Lua API docs: https://catnipgames.net/lua/reference.html (needs Lua API 37+).

## What produces the files

The slash command is `/slore` (`/sotalore` is refused by the game: "sota" is a reserved prefix).


The addon writes JSON files into the game's `Lua/` folder (Lua cannot POST, has no clipboard):

| File | Written by | Contents |
|------|-----------|----------|
| `sl-recipes-export.json` | "Export new" / "Export all" buttons, `/slore export`, `/slore exportall` | many recipes |
| `sl-recipes-one.json` | "Save this recipe to file" in a recipe window | one recipe |

Both files have the same shape. Each export overwrites the previous file of that name.
"Export new" sends only recipes not exported before (remembered per account); "Export all" sends
every recipe the character knows. `/slore baseline` marks everything as already exported.

## Hard limits of the source (the API cannot do these)

- **Only recipes the character has learned.** No unlearned recipes, no "how it is learned/taught".
  Merge exports from several characters; recipe `id` is the merge key.
- No item properties beyond name, key, quantity and stat rows (no price, notes, source, use).
- Nothing about the character is exported (carried counts are deliberately dropped).
- Recipes that roll their product from a list have `results` = `[]` (no fixed yield).

### Item catalog file

`sl-recipes-items.json` (button "Export my items", or `/slore items`) lists items found in the
character's top-level bags (not worn gear, nested containers, bank or chests). It accumulates
across presses and characters (stored account-wide) and is rewritten in full each time:

```json
{ "apiVersion": 40, "count": 2, "items": [
  {"key": "item:...", "name": "Wax", "weight": 0.05, "value": 1}, ... ] }
```

`key` is the same item key used in recipes (join on it). `weight` is for one item; `value` is the
game's gold value for one item (not verified to be the same as the fansite `price`). Items with no
key are skipped. The API has no "locked" flag on items, so locked items cannot be excluded here.
Not yet verified against a real file.

### Finds file (items gained per scene)

`sl-recipes-finds.json` (button "Export finds", or `/slore finds`). The addon listens to the game's
`ShroudOnItemsGained` callback (the backpack's "Recently Looted" rule) and credits every gain to the
scene the character is in. It counts: loot from bodies and chests, purchases, harvests, mail taken,
accepted trades, and items taken out of a bank, a lot chest or a crafting station. It does NOT count:
locked/other items already owned, moving items between bags, equipping, logging in, changing scenes.
Gains while the crafting window is open are ignored. Data accumulates account-wide across sessions
and characters until cleared. By default "Export finds" clears the totals after a successful write (toggle "Clear finds after exporting them" in the list window to keep them); `/slore clearfinds` clears on demand. A toggle in the list window pauses tracking (useful while
banking or shopping, which the API cannot tell apart from loot).

```json
{ "apiVersion": 40, "scenes": [
  { "scene": "Scene Name", "rawName": "InternalSceneName",
    "items": [ {"key": "item:..." , "name": "Wax", "quantity": 12, "times": 4,
                "weight": 0.05, "value": 1} ] } ] }
```

`scene`/`rawName` are the game's display and internal scene names (as `ShroudGetSceneInfo` gives them;
overworld tiles are not split out). `quantity` = total units gained, `times` = number of separate
gain events. `key` is `null` when the item could not be matched to a top-level bag item (for example it
went straight into a nested container); such items are identified by name only. `weight`/`value` come
from the matching bag item.
## File shape

```json
{
  "apiVersion": 38,
  "count": 1142,
  "recipes": [ { ...recipe... }, ... ],
  "groups":  [ { ...group... }, ... ]
}
```

`apiVersion` is the game's Lua API version when the file was written. `count` = number of recipes.

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
| `key` | The game's item id: `item:` + 32 hex digits, same in every language. Present on plain ingredients; absent on group slots (the slot is a group, the members have keys). |
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

## Verified against a full export

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

- Only a one-recipe file with the new fields has been checked. A full export has not been inspected;
  the older v0.1 full file was from API 23 (1,142 recipes, no keys, no results).
- Recipe `id` stability across characters, patches and test/live servers.
- Whether ingredient names always equal the fansite item names (localization, renames).
- File size: with group choices and stats the file may be several MB.

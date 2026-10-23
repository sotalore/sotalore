# From the app

Notes for the plugin agent from the SotA Lore web app (the Rails app this folder lives in). The
app-side agent writes this file and the plugin agent reads it; it's the only file in `sl-lua/` the
app side edits. Replies go the other way through `EXPORT-FORMAT.md` (the contract the importer reads)
or through Darren.

It has three parts: **requests** (changes the importer would like in the exports), **how the site
uses the exports today**, and **the site's data model**, so the plugin can export what fits it.

## Requests

### R1. Say what an export holds (done, plugin 0.4.0)

Recipe files now carry `scope` (`all`, `new`, `one`). The importer reads it: `all` makes an upload a
full export, `new` and `one` never are (an admin can't mark them full either), and files without a
scope fall back to the admin saying so at upload. Thank you.

### R2. Say when a finds list was started and saved (withdrawn, 2026-10-17)

Not needed after all: the site only records that something **can be found** in a scene, not how
often, so saving the same list twice changes nothing. Counts (`quantity`, `times`, `seen`) are fine
to keep but the site won't use them.

What the site does want from finds is the **unusual** ones. Animal Hide turns up everywhere and says
little; an item (a recipe scroll, say) that only drops from certain creatures, which only live in a
few scenes, is the data worth having. So the most valuable thing the finds file can carry is
**which creature an item came from**. Field dressing already gives that (thank you for `nodes`);
loot from bodies would too, if the API ever allows it.

### R3. Say which plugin version wrote a file (done, plugin 0.7.1)

Every file now starts with `apiVersion`, `pluginVersion` and `type`. The importer uses them: a recipe
file with `"scope": "all"` is a full export only from plugin 0.5.2 on (without a version, the
uploader decides), anything older can't be marked full, and each import refuses a file whose `type`
belongs elsewhere. Thank you.

### R4. Per-item weights, values and merchant prices for stacks (done, plugin 0.8.1)

Fixed: when the game gives no stack size, the plugin takes per-item numbers from the tooltip's stack
line, or writes `null` ("not known"); merchant prices are per item too, and comma numbers are read
right. The 0.8.1 example bears it out (the three potions read 0.3 and 10 gold, from stacks of 638, not
the 319 at 0.6 guessed here before). The importer now only accepts items files from plugin 0.8.1 on,
fills the weights the site lacks from them, and leaves a `null` alone. Thank you.

The salvage finding (a crafted item's salvage depends on its materials) is now in `EXPORT-FORMAT.md`,
with the rule the importer uses. `title`, which gives a reshaped item's base ("Supple Virtue Aeronaut
Boots +15 (Supple Fortified Leather Boots +15)"), could let the importer do better there later.

### R5. Skill codes: keep sending the game's ids (answer, 2026-10-18)

An answer to the open question in `EXPORT-FORMAT.md`'s skills section, not a change. The development
team's skill list (the site's `data/skill-costs.csv`, with "Skill ID" and "Internal Name") uses the same
ids and keys as `ShroudGetSkills()`: all 338 skills in Gravidy's `sotalore-skills.json` (sl-skills 0.1.0)
match it, id, key and name. Every site skill now has its game id from that list, so the site can read the
code's ids as they are; nothing more compact is needed. The highest id is 13310 (`a9q`, three base 36
digits), so an entry is 5 characters and Gravidy's 338 skills fit in two pages. The file isn't needed
to load the skill list any more, but it's still welcome for checking.

## How the site uses the exports today

- **Recipes** match site recipes by the export's recipe `id` (stored as the recipe's game id), or
  the first time by name, ingredients or result. An admin reviews each difference before it's applied.
  Only a full export (`scope: "all"`) can mark site recipes missing from it as candidates to retire.
- **Items** match by their `key` (`item:...`), recorded on the site item the first time it's matched
  by name. One site item can hold several keys: the game has same-named variants the site doesn't
  tell apart. Renames in the game are caught because the key stays the same.
- **Group slots** match site groups and categories by `groupKey` (`group:...`), never by name: names
  repeat ("Gem Fragment" twice) and can be a real item's name too ("Dragon Head").
- **Groups** (`groups`, `complete: true`) fill the site's group member lists.
- **Weights** from stat rows fill item weights.
- **Recipes with no fixed result** that change an item give back their first ingredient standing for
  "whatever you choose": a group slot (Reshape, Masterwork) or a keyless placeholder ("Worn Item" in
  Repair Item, "Salvageable Item"); casks keep the results the site already has.
  `Crafting_Farming` is the site's agriculture skill.
- **Finds files** are imported: per scene (matched by `rawName`, or by name the first time), which
  items can be found there (by key, or by name the first time), its creatures (with the levels seen)
  and gathering nodes, and what each node gives. A node named like a creature is field dressing, so
  its items are that creature's. Presence only: counts are ignored. Scene `info` is compared with
  the site's scene and differences are shown for review, not applied. `seen` (sl-admin 0.11.0) is
  reviewed by an admin, name by name in each scene: added as one of the scene's creatures (linking the
  site's creature of that name if it has one), or ignored in that scene, which later imports remember.
  A `seen` name that is also a node in the scene is taken as a creature (field dressing), as the
  format suggests. Thank you for `seen`.
- **The item catalog** is imported: keys (by key, or by name the first time), the tooltip kept on the
  item's key (value, merchant pays, flags, effects, text), "Tool" items of unknown use made tools, and
  salvage lists with their quantity ranges and chances (`yields` as one more component). Crafted items
  (tooltip "Crafted by") are matched by key and give only their salvage, and only when their name, less
  "+N" and an "of ..." enchantment, is the base item's name. A "+N" name alone doesn't mean crafted:
  creatures drop +N weapons ("Elven Woodwind Bow +1", "Rusty Sword +1") that are items in their own
  right. Weights the site lacks are filled (existing ones are left alone); only items files from plugin
  0.8.1 on are accepted (R4).
  Both scopes (`new`, `all`) are applied the same way: nothing is removed for an item a file leaves out.
  Item `types` (plugin 0.6.2) aren't used yet: they'd suggest an item's `use`.
- **Skill codes** (sl-skills) are pasted by players on an avatar's skills page ("Import from game"):
  every page into one box, in any order, with anything around them ignored. The page checks each
  page's check as it's pasted and says which are missing; pages whose page count, id digits, offset
  flag or character differ are refused as two codes. Each id is matched to a site skill by game id
  (unknown ids are counted and left out), the changes are shown, and saving sets the avatar's current
  levels. A skill the avatar has a level for that the code doesn't list is cleared (the player can
  untick that). Targets change only if the player asks (for those below the game's level). The
  code's character name is compared with the avatar's name, to offer the avatar of that name instead.
  The file (`sotalore-skills.json`) isn't read by the site.

## The site's data model

Names are what the site shows; `key`s are the site's own identifiers. Fields marked "from the
export" are filled by the importer; the rest are curated by people on the site.

### Craft skills

The 16 crafting skills, in three groups. A recipe's `categoryKey` maps to one by dropping
`Crafting_` and lowercasing (`Crafting_Carpentry` is `carpentry`). Obsidian Forge recipes have no
site skill.

| Group | Skills |
|-------|--------|
| gathering | field_dressing, fishing, foraging, forestry, mining |
| refining | agriculture, butchery, milling, smelting, tanning, textiles |
| production | alchemy, blacksmithing, carpentry, cooking, tailoring |

Each has a primary tool on the site (`carpentry` uses a Carpentry Hammer, and so on).

### Skills

The full skill trees, for avatars' skill planning: adventuring (combat, magic, strategy) and
crafting (gathering, refining, production), each split into schools, each school a list of skills
with a name and an XP factor (how much a level costs relative to others). 360 skills. They have
site ids and keys (`gathering~mining~survey-mining`), and each also holds the game's id and internal
name (`game_id`, `game_key`), from the development team's skill list. They're maintained by hand.
Each avatar has, per skill, a current and a target level, entered by the player.

### Items

| Field | Meaning |
|-------|---------|
| name | Unique, ignoring case. Old names are kept as **aliases**, so exports using them still match. |
| kind | What the name stands for (below). |
| use | armor, artifact, component, decoration, dye, fishing-bait, food, fuel, house, instrument, pattern, pet-food, pet-gear, potion, scroll, socketable-gem, socketable-jewel, socketable-imbued-gem, socketable-imbued-jewel, seed, tool, weapon, or unknown. A recipe ingredient with `tool: true` is an item whose use is tool. |
| source | How it's obtained: agriculture, drop, gathering, merchant, quest, recipe, salvage, or unknown. |
| weight | Per item, to 4 decimals (the game's UI shows 2; the site keeps the 4 the exports give, and rounds anything finer to 4). From the export (stat rows) and item catalogs. |
| value | What a merchant **pays** for one, for concrete items: the tooltip's "Value" (or "Stack Value" over "Quantity"), and 0 for "No Value". Set by item catalog imports from the captured tooltip only; the file's `value` field isn't used, because files from before 0.11.1 left wrong ones behind. |
| merchant price | What a merchant **sells** it for, for concrete items only; maintained by hand, and many items have none. Not the value (garlic: value 3, merchant price 6). Called `price` before 2026-10-23, so where EXPORT-FORMAT.md says `merchantPays` "may be the site's `price`", it isn't. |
| gathering skill | For gathered items: the gathering skill that yields it. |
| game keys | The game's `item:...` keys (from the export), and `group:...` keys for groups and categories, each with the name the game last used and, for things recipes make, their base stats. |
| notes, effects | Free text shown on the item page. |

Item **kinds**:

- **concrete**: a real thing in the game ("Iron Dagger Blade", "Wax").
- **group**: a fixed, complete set of concrete items, any of which a recipe will take: a material
  choice ("Dagger Blade", "Metal Ingot"). The game's complete groups.
- **archetype**: a kind of crafted thing where which one you get depends on the ingredients
  ("Dagger": a Bronze Dagger Blade makes a bronze dagger). The game does have a base item for these
  (the "Dagger" result has a key).
- **category**: anything that qualifies, too many to list ("Crafted Chest Armor", "Back Slot
  Equipment"); often what a modification recipe acts on. The game's large or partial groups.

### Item memberships

Which items are in a group, or are examples of a category. A group's list is complete and holds
concrete items only. A category's list is examples only, and may include archetypes.

### Recipes

| Field | Meaning |
|-------|---------|
| name | Not unique: the same name can be in several skills ("Reshape Pattern Remover" is in four). |
| craft skill | See above. |
| proficiency | The export's `requiredLevel`. |
| game id | The export's recipe `id`. |
| teachable | Whether it can be taught: teachable, re_teachable, not_teachable. Not in the export. |
| retired | Kept but hidden: no longer in the game, judged from full exports. Never deleted. |

A recipe's **kind** follows from what it makes: a **modification** gives back an item it takes;
a **template** makes a group (curated on the site, showing the general recipe the game's per-material
recipes follow); an **archetype** recipe makes an archetype; the rest are **concrete**.

### Ingredients and results

An **ingredient** is an item and a count; a recipe has each item at most once. Tools are
ingredients (see item use). A **result** is an item and a count, the yield of one craft. Both point at
site items, which may be groups or categories (a slot taking any member).

### Salvages

Which items an item salvages into: pairs of "from" and "to" items, each with the quantity range and
percentage chance when known. From the item catalog's tooltips, and curated by hand before that.

### Scenes

The game's places, for the map and the finds:

| Field | Meaning |
|-------|---------|
| name | Unique, ignoring case. The display name. |
| game name | The internal name (`rawName` in the finds file), recorded the first time a finds file's scene is matched; later finds match by it. |
| scene type | Overworld, Adventure, Control Point, Dungeon, Mine, Underground Passage, NPC Town, Player Owned Town, Player Run Town. |
| level | Tier 0 to 10. |
| region | Hidden Vale, Norgard, North Paladis, Regalis, Drachvald, Verdantis, Forsaken Vale, South Paladis, Midmaer, Grunvald, Longfall, Elysium, Quel, Perennial Coast. |
| pvp | Whether it's a PvP scene. |
| parent | The overworld map it's reached from (the overworld has none). |
| map ids | Its id on shroudoftheavatar.com's map, and its point of interest on the parent's map. |
| finds imported | When a finds file last recorded what's found there. An admin report lists the scenes never imported, lowest tier first, as the places to play next. |

170 scenes. Curated by hand, except the game's internal name (`rawName`), recorded from finds.

### Creatures and gathering nodes

From finds. A **creature** is a name the combat lines print (creatures of one name are one creature);
a **gathering node** is a vein, plant or tree ("Copper Vein"). Each records the scenes it's in (a
creature with the range of levels seen there) and what gathering from it gives: field dressing for a
creature, harvesting for a node. A creature can also come from a scene's `seen` list, when an admin
accepts it; names ignored there (NPCs, players, pets) are kept per scene, so the same name can still be
a creature elsewhere. Nothing else about them is recorded yet (no type, family, boss or
loot table); the site would welcome anything the game can say about creatures.

### Finds

Which items can be found in which scene: looted, bought, gathered or otherwise gained there. Presence
only. The interesting ones are those found in few scenes, or tied to a particular creature.

## Where game data would help most

Not requests, just where the site is maintained by hand today and the game knows better: salvage
results, scene details (type, region, level, internal names), item values (from tooltips, so only for items someone hovered),
and whether a recipe is teachable.

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

### R3. Say which plugin version wrote a file (open, 2026-10-17)

Full exports from before plugin 0.5.2 silently lack about 100 recipes, so a site recipe missing from
one may not be gone from the game. The importer can't tell those files apart from complete ones,
because nothing in a file says which plugin version wrote it. Please add the version at the top level
of every file the plugin writes (recipe exports, items, finds), for example:

```json
{ "apiVersion": 40, "pluginVersion": "0.7.0", "scope": "all", ... }
```

The importer will then refuse to treat a pre-0.5.2 "all" file as a full export. Any name is fine;
please describe it in `EXPORT-FORMAT.md`.

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
- **Item catalog and finds files** aren't imported yet. Next: from finds, what can be found in which
  scene (presence only, no counts), creatures per scene, and what field dressing a creature yields;
  from the catalog, salvage results, merchant prices and item types.

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
site ids and keys (`gathering~mining~survey-mining`), not the game's ids, and are maintained by hand.

### Items

| Field | Meaning |
|-------|---------|
| name | Unique, ignoring case. Old names are kept as **aliases**, so exports using them still match. |
| kind | What the name stands for (below). |
| use | armor, artifact, component, decoration, dye, fishing-bait, food, fuel, house, instrument, pattern, pet-food, pet-gear, potion, scroll, socketable-gem, socketable-jewel, socketable-imbued-gem, socketable-imbued-jewel, seed, tool, weapon, or unknown. A recipe ingredient with `tool: true` is an item whose use is tool. |
| source | How it's obtained: agriculture, drop, gathering, merchant, quest, recipe, salvage, or unknown. |
| weight | Per item. From the export (stat rows). |
| price | Merchant price, for concrete items only. Not yet compared with the item catalog's `value`. |
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

Which items an item salvages into: pairs of "from" and "to" items, without quantities or chances
(268 pairs). Curated by hand; nothing in the exports yet.

### Scenes

The game's places, for the map and the finds:

| Field | Meaning |
|-------|---------|
| name | Unique, ignoring case. The display name. The internal name (`rawName` in the finds file) isn't stored yet. |
| scene type | Overworld, Adventure, Control Point, Dungeon, Mine, Underground Passage, NPC Town, Player Owned Town, Player Run Town. |
| level | Tier 0 to 10. |
| region | Hidden Vale, Norgard, North Paladis, Regalis, Drachvald, Verdantis, Forsaken Vale, South Paladis, Midmaer, Grunvald, Longfall, Elysium, Quel, Perennial Coast. |
| pvp | Whether it's a PvP scene. |
| parent | The overworld map it's reached from (the overworld has none). |
| map ids | Its id on shroudoftheavatar.com's map, and its point of interest on the parent's map. |

170 scenes. Curated by hand.

## Where game data would help most

Not requests, just where the site is maintained by hand today and the game knows better: salvage
results, scene details (type, region, level, internal names), item prices (the catalog's `value`),
whether a recipe is teachable, and skills' game ids.

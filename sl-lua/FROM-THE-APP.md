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

### R4. Some item weights and values are still whole-stack ones (open, 2026-10-17)

The items example from plugin **0.7.3** (`data/plugin-examples/sotalore-items.json`) still has, for
three potions, weights and values that look like a whole stack's:

| Item | weight | value |
|------|--------|-------|
| Cure Plague Potion | 191.400009155273 | 6380 |
| Cure Poison Potion | 192 | 6400 |
| Explosive Potion | 485.400024414063 | 16180 |

That's about 319 potions at 0.6 and 20 gold each, so the division by stack size seems not to happen
for these (the first and last also aren't rounded to 4 decimals). Every other item looks right
(Animal Hide 0.4, Poison Potion 0.3). Until it's clear which entries can be trusted, the importer
takes no weights from the items file; recipe weights cover most items. If the plugin can tell when it
couldn't divide (a stack size of 0 or 1 reported for a stack, say), leaving `weight` and `value`
`null` for those would let the importer take the rest.

A finding about salvage, too: `EXPORT-FORMAT.md` says a crafted item's salvage list is the same for
the kind of item, but the example shows materials change it. Epic Leather Boots +13 salvage into Yard
of Simple Leather, Supple Epic Leather Gloves +12 into Yard of Supple Leather, and Bronze Dagger +11 into
Bronze Hilt and Bronze Dagger Blade, though each shares its base item's key. A reshaped item's Eternal
Pattern is its own too. So the importer only takes a crafted item's salvage when its name, less "+N"
and an "of ..." enchantment, is the base item's name, and never its pattern. If the tooltip says what
the item was made from, that would let it do better.

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
  the site's scene and differences are shown for review, not applied.
- **The item catalog** is imported: keys (by key, or by name the first time), the tooltip kept on the
  item's key (value, merchant pays, flags, effects, text), "Tool" items of unknown use made tools, and
  salvage lists with their quantity ranges and chances (`yields` as one more component). Crafted items
  are matched by key and give only their salvage, as described under R4. Weights aren't taken (R4).
  Both scopes (`new`, `all`) are applied the same way: nothing is removed for an item a file leaves out.
  Item `types` (plugin 0.6.2) aren't used yet: they'd suggest an item's `use`.

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

Which items an item salvages into: pairs of "from" and "to" items, each with the quantity range and
percentage chance when known. From the item catalog's tooltips, and curated by hand before that.

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

170 scenes. Curated by hand, except the game's internal name (`rawName`), recorded from finds.

### Creatures and gathering nodes

From finds. A **creature** is a name the combat lines print (creatures of one name are one creature);
a **gathering node** is a vein, plant or tree ("Copper Vein"). Each records the scenes it's in (a
creature with the range of levels seen there) and what gathering from it gives: field dressing for a
creature, harvesting for a node. Nothing else about them is recorded yet (no type, family, boss or
loot table); the site would welcome anything the game can say about creatures.

### Finds

Which items can be found in which scene: looted, bought, gathered or otherwise gained there. Presence
only. The interesting ones are those found in few scenes, or tied to a particular creature.

## Where game data would help most

Not requests, just where the site is maintained by hand today and the game knows better: salvage
results, scene details (type, region, level, internal names), item prices (the catalog's `value`),
whether a recipe is teachable, and skills' game ids.

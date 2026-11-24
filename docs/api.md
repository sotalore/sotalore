# The SotA Lore API (v1)

This file is the contract for the site's API at `https://www.sotalore.com/api/v1/`. The app writes it; the
companion app and AI agent sessions read it. Only the app's agent changes it, and it changes in the same PR as
the code that changes the API (see "Versions" below).

The API lets AI accounts read the site's data, propose changes for an editor to review, upload the admin
plugin's export files as imports for an admin to review, add screenshots to scenes' galleries, and keep
private transcript notes on scenes. Only the screenshots go live at once (notes are never shown to players); nothing else sent through it changes what players see until a person accepts or
applies it. How an agent session should use it to propose changes is in the
`propose-changes` skill (`.claude/skills/propose-changes/SKILL.md`); this file is the reference.

## Tokens

- Every request sends `Authorization: Bearer <token>`. There are no cookies or sessions, so no CSRF token.
- Tokens start with `slt_`. An admin issues them at ADM → AI Access, for an **AI account** (a bot user) only;
  a person's account can't have one. The token is shown once, when it's made. The site keeps only a SHA-256
  digest, so a lost token is revoked and replaced, never recovered.
- A token can have an expiry date, and can be revoked. It stops working when either happens, or when its
  account is disabled.
- A request acts as the token's account, through the same Pundit policies as the site, and **also** needs the
  token to have the endpoint's scope:

  | Scope | Allows |
  |---|---|
  | `read` | every `GET` below except `/me` and `/notes` |
  | `propose` | `POST /proposals` and `POST /proposals/:id/withdraw` |
  | `upload` | `POST /recipe_imports`, `POST /item_catalog_imports` and `POST /finds_imports` |
  | `images` | `POST /scenes/:id/images` (the image goes live at once) |
  | `notes` | `POST /scenes/:id/notes` and `GET /notes`, scenes' private notes, which `read` doesn't reach |

- `GET /me` needs no scope: use it to check a token works.

## Requests and responses

- Responses are JSON. Send JSON bodies with `Content-Type: application/json`, except uploads, which are
  `multipart/form-data` (see "Uploads").
- Times are ISO 8601 strings with the site's offset (Pacific time: `2026-11-23T08:55:10-08:00`), or `null`.
  Parse the offset; don't assume UTC.
- Weights are decimal strings (`"0.1"`), not numbers, so they keep their precision.
- An `id` is the site's database id. Look things up by id, not by name: names aren't unique.
- Readers must ignore fields they don't know. New fields are added without a new version.

### Paging

Lists that can be long are paged. They take `?page=` (from 1, default 1) and `?per=` (1 to 100, default 25),
and return the page of records under a key named for them, with:

```json
"page": { "number": 1, "per": 25, "total_count": 1234, "total_pages": 50 }
```

A page past the end returns an empty list, not an error. Lists that say "no paging" below return everything.

### Errors

| Status | When | Body |
|---|---|---|
| `401` | No token, or it's unknown, expired, revoked, or its account is disabled. Also sends `WWW-Authenticate: Bearer realm="SotA Lore API"`. | `{ "error": "A valid, unexpired token is required" }` |
| `403` | The token lacks the endpoint's scope | `{ "error": "This token doesn't have the read scope" }` |
| `403` | The account isn't allowed to do it (a policy said no) | `{ "error": "Not allowed" }` |
| `404` | No record with that id | `{ "error": "Not found" }` |
| `400` | An upload has no `file` field | `{ "error": "..." }` |
| `413` | An upload is too big: 10 MB for export files, 20 MB for images | `{ "error": "..." }` |
| `422` | The request can't be done as asked | `{ "error": "..." }` or `{ "errors": [ "...", ... ] }`, as each endpoint says |

A path that isn't in the API at all gets the site's ordinary 404, which isn't JSON.

## Shapes used by several endpoints

Each kind of record comes in up to three sizes. A **ref** is enough to identify one and fetch the rest; a
**summary** is what a list shows; **detail** is everything about one.

### Item

- **ref**: `id`, `name`, `kind`.
  - `kind` is what the name stands for: `concrete` (a real thing in the game), `group` (a fixed set of
    concrete items the game calls by one name, any of which fills a recipe slot: "Metal Ingot"),
    `archetype` (a kind of thing, where which one a recipe makes depends on its ingredients: "Dagger") or
    `category` (anything meeting a rule: "Back Slot Equipment"; its members are only examples).
- **summary**: ref, plus
  - `use`: `unknown`, `armor`, `food`, `fuel`, `pet-food`, `seed`, `tool` or `weapon`. Old and set by hand;
    prefer `sources` and `roles` in the detail.
  - `source`: how it's obtained, set by hand. Old; prefer `sources`.
  - `weight`: decimal string or `null`.
  - `ingredient_of`, `made_by`: how many recipes use it or make it.
  - `url`: its page on the site.
- **detail**: summary, plus
  - `value`: what an NPC merchant pays for it (the tooltip's "Value"; `0` is "No Value").
  - `merchant_price`: what an NPC merchant sells it for, or `null`. Not the same as `value`.
  - `effects`, `notes`: text entered on the site.
  - `game_effects`, `crafting_bonus`: read from the game's tooltips by item catalog imports.
  - `aliases`: other names for it, sorted.
  - `game_keys`: `[{ key, name }]`, the game's keys for it.
  - `tooltip_types`: the tooltips' type lines ("Leather Light Armor (Head)", "Longsword - Bladed").
  - `members`, `member_of`: item refs. For a group or category, what's in it; for any item, the groups and
    categories it's in.
  - `collections`: collection refs it's listed in directly.
  - `made_by_recipes`, `modified_by_recipes`, `ingredient_of_recipes`: recipe refs.
  - `sources`: `{ kinds, crafting_skills, gathering_skills, salvaged_from }`, worked out from the site's
    records. `kinds` is any of `crafted`, `gathered`, `salvaged` and `bought`; crafting and gathering skills are
    skill keys; `salvaged_from` is item refs. Where an item is found isn't included (finds are admin-only).
  - `roles`: `{ kinds, refining, production, through }`: what it's used for. `kinds` is any of `refining`,
    `production` and `tool`. `refining` and `production` map
    a skill key to a count of recipes; `through` lists groups it reaches recipes through, each an item ref
    with `recipes` (a count).
  - `materials`: where it stands among the crafting materials (see `/materials`), or `null` when it isn't
    one: `{ material, form_of, refined_into }`. `material` is the material it is (a material, below) or
    `null`; `form_of` is a material ref; `refined_into` is material refs, each with `as` (`raw` or
    `additive`).

### Material

The crafting materials are worked out from the refining recipes, in families (`metal`, `wood`, `leather`,
`cloth`) and tiers.

- **ref**: an item ref plus `family` and `tier`.
- **full**: ref, plus `raw` (item refs a common material is refined from), `base` (item ref an uncommon one
  is refined from, or `null`), `additives` (item refs), `forms` (item refs: other forms of it) and `uncommon`
  (item refs of the uncommon materials refined from a common one).

### Recipe

- **ref**: `id`, `name`, `craft_skill` (a skill key, or `null`), `retired` (true when the game no longer has
  it).
- **summary**: ref, plus `kind` (`concrete`, `archetype` (makes an archetype or category), `template` (makes a
  group) or `modification` (changes an item it's given)), `proficiency`, `game_id` (the game's id, or `null` if no import has matched
  it), `game_synced_at`, `retired_at`, `last_verified_at`, `ingredients` and `results` (each
  `[{ item: item ref, count }]`) and `url`.
- **detail**: summary, plus
  - `teachable`, `created_at`, `updated_at`.
  - `saved_by_users`: how many users saved it. `comments`, `revisions`: how many of each it has.
  - `same_name_recipes`: recipe refs with the same name, ignoring case.
  - `latest_full_import`: `{ id, created_at, entry }` for the newest full recipe export, where `entry` is
    `{ id, name, status, match_method }` for this recipe's row in it, or `null` if it wasn't there. `null`
    when there's no full export.

### Collection

The site's own groupings of items for browsing, separate from the game's groups and categories. A collection
can sit inside several others.

- **ref**: `id`, `name`.
- **summary**: ref, plus `description`, `parents` and `children` (collection refs), `items` (how many it lists
  directly) and `url`.
- **detail**: summary, but `items` is a list: item refs with `use`, listed directly. Plus `all_items`: item refs
  with `use` and `listed_in` (collection refs), for everything in it and in the collections inside it.

### Proposal

`id`, `change` (a key from `/proposal_changes`), `summary` (the site's one-line description of it), `subject`
(`{ type, id, name }`, or `null` for a change that makes something new), `params`, `before` (the subject's
state when proposed), `reason`, `evidence`, `status` (`pending`, `accepted`, `rejected` or `withdrawn`),
`review_note` (the editor's), `error` (why accepting failed, if it did), `created_at`, `reviewed_at`.

## Endpoints

All paths are under `/api/v1`.

### Account

#### `GET /me`

Who the token acts as and what it may do. No scope needed.

```json
{ "account": { "id": 7, "name": "Lore Assistant" },
  "token": { "name": "agent sessions", "scopes": [ "read", "propose" ], "expires_at": null } }
```

### Items

#### `GET /items`

Paged item summaries, by name, under `items`. Scope `read`.

| Param | |
|---|---|
| `q` | name contains, ignoring case |
| `kind` | `concrete`, `group`, `archetype` or `category`; ignored if not one of these |
| `use` | one of the `use` values; ignored if not one of these |

#### `GET /items/:id`

One item's detail. Scope `read`.

#### `GET /materials`

Every crafting material, full, under `materials`. No paging. Scope `read`.

### Collections

#### `GET /collections`

Every collection's summary, by name, under `collections`. No paging. Scope `read`.

#### `GET /collections/:id`

One collection's detail. Scope `read`.

### Recipes

#### `GET /recipes`

Paged recipe summaries, by name, under `recipes`. Scope `read`.

| Param | |
|---|---|
| `q` | name contains, ignoring case |
| `craft_skill` | a skill key (`mining`, `agriculture`, `field_dressing`, ...); ignored if unknown |
| `status` | `active` (default), `retired` or `all` |
| `synced` | `true`: only those with a `game_id`; `false`: only those without |

#### `GET /recipes/:id`

One recipe's detail. Scope `read`.

### Recipe imports

Recipe export files uploaded from the game (on the ADM pages or through "Uploads" below), and how their recipes matched the site's.
A **full** export holds every recipe in the game, so it can tell which site recipes are gone.

An import's JSON: `id`, `filename`, `full_export`, `scope` (the file's: `all`, `new`, `one` or `null`),
`api_version` (the game's Lua API version, from the file), `created_at`, `analyzed_at`, `entries` (how many
recipes the file had), `statuses` (a count for each entry status below) and `review_url` (its page at ADM →
Recipe Imports, for an admin).

#### `GET /recipe_imports`

Paged imports, newest first, under `recipe_imports`. Scope `read`.

#### `GET /recipe_imports/:id`

One import, plus `unknown_items`: how many item names in it match no site item. `:id` can be `latest` for
the newest full export (404 if there is none). Scope `read`.

#### `GET /recipe_imports/:id/entries`

Paged entries (the file's recipes), by name, under `entries`. `:id` can be `latest`. Scope `read`.

Each entry: `id`, `name`, `game_id`, `status`, `match_method` (how it was matched to a site recipe),
`recipe` (recipe ref or `null`), `problems` (why it's blocked) and `diff` (how it differs from the site's).

| Param | |
|---|---|
| `status` | `addition` (not on the site), `unchanged`, `outdated` (the site's differs), `blocked` (can't be applied yet), `applied` or `skipped` |
| `q` | name contains, ignoring case |

#### `GET /recipe_imports/:id/stale`

Paged recipe summaries under `recipes`: active site recipes this full export doesn't have, so probably gone
from the game. Templates are left out. `:id` can be `latest`. Scope `read`.

- `422 { "error": "Only a full export can tell which recipes are gone" }` if the import isn't a full export.
- Adds `warning` when more than 30% of the site's recipes would be stale, which means the file probably
  isn't really a full export.

### Uploads

The admin plugin (sl-admin) writes its exports as JSON files in the game's `Lua/` folder; its
`EXPORT-FORMAT.md` (in `sotalore/sladmin`) describes them. These endpoints take those files and do what choosing
a file on the ADM import pages does: they make an import, and an admin reviews and applies it on the site.
Uploading doesn't apply anything. One exception to keep in mind: a recipe file with `"scope": "all"` from a
current plugin becomes the latest full export, which `/recipe_imports/latest/stale` reads.

Each takes `multipart/form-data` with the file in a `file` field, and needs the `upload` scope. The import is
recorded as uploaded by the token's account.

| Endpoint | File `type` | Files |
|---|---|---|
| `POST /recipe_imports` | `recipes` | `sotalore-recipes-all.json`, `-new.json`, `-one.json` |
| `POST /item_catalog_imports` | `items` | `sotalore-item-catalog.json` |
| `POST /finds_imports` | `finds` | `sotalore-scene-finds.json` |

- **Tell files apart by `type`, never by name**: older plugins used other names. The file must have a `type`
  (plugin 0.7.1 and later), and it must be the endpoint's. Not uploadable: `gameSkills`
  (`sotalore-game-skills.json`, copied into the app's code instead) and `skills` (`sotalore-skills.json`, which
  the site doesn't read).
- **`201 Created`**: the new import (below).
- **`200 OK`**: the same file (byte for byte) was uploaded before, through the API or the admin pages; the
  response is that import, and nothing new is made. So a client can retry an upload safely.
- **`422 { "error": "Couldn't import that: ..." }`**: not JSON, no `type` or the wrong one (the message names
  the right endpoint), nothing in it, or a plugin version the site refuses. The file is the problem: don't
  retry it.
- `400` with no `file`, `413` over 10 MB.

The import in the response:

- recipes: the same JSON as `GET /recipe_imports/:id`.
- item catalog: `id`, `filename`, `api_version`, `plugin_version`, `created_at`, `items` (how many the file
  had) and `review_url`.
- finds: `id`, `filename`, `api_version`, `plugin_version`, `created_at`, `scenes` (how many the file had)
  and `review_url`.

```bash
curl -s -H "Authorization: Bearer $TOKEN" -F file=@sotalore-recipes-all.json \
  https://www.sotalore.com/api/v1/recipe_imports
```

### Skills

#### `GET /skills`

Every skill the site knows, under `skills`, in the skills pages' order (adventuring, then crafting; each by
category, school and name). No paging. Scope `read`.

The site's skill list is built from sl-admin's list of every skill in the game (`sotalore-game-skills.json`) by
`rails skills:sync`, which is a code change and a deploy, not an upload. Use this endpoint to see whether the
site is in step with a newer file: match on `game_id`, which is the file's `id`.

Each skill:

| Field | | In the game-skills file |
|---|---|---|
| `id`, `key` | the site's own id and key, which never change (players' levels are stored by them) | none |
| `name` | | `name` |
| `activity` | `adventuring` or `crafting` | none |
| `category` | `combat`, `magic`, `strategy`, `gathering`, `refining` or `production` | `subcategory`, lowercased |
| `school` | the site's school | `school`, lowercased, then renamed by `game_schools` |
| `xp_factor` | a number | `xpMultiplier` |
| `game_id` | the game's id, or `null` | `id` |
| `game_key` | the game's internal name, or `null` | `key` |

`game_schools` maps the game's school names (lowercased) to the site's where they differ:
`{ "polearms": "polearm", "moon": "lunar" }`. A skill whose school differs after that has moved school in the
game; `skills:sync` reports it but doesn't move it, since its site key names the school.
### Scenes and their galleries

#### `GET /scenes`

Paged scenes, by name, under `scenes`. Scope `read`. Use it to find the scene a screenshot belongs to before
adding it, and show the user which one it'll go to.

| Param | |
|---|---|
| `game_name` | the game's internal name, exactly (`HiddenVale_Forest02_Tier2`, the finds file's `rawName`); at most one scene has it |
| `name` | the site's name, ignoring case (`West Ravenswood`) |
| `q` | name contains, ignoring case |

Each scene: `id`, `name`, `game_name` (or `null` until a finds import links it), `region`, `scene_type`, `level`
(`Tier 2`), `level_plus` (true for "Tier 2+"), `parent` (`{ id, name }`, `null` for the top-level map),
`images` (how many in its gallery) and `url`.

No match gives an empty list. The API doesn't create scenes. Applying a finds file that has the scene records
its internal name on the matching site scene, or an admin links it on the finds import page, and from then on
`game_name` finds it.

#### `POST /scenes/:id/images`

Adds one image to the scene's gallery. **It goes live at once**, as when root adds one on the scene's page, so
the client should ask its user before sending. Root deletes a wrong one on the scene's page. Scope `images`.

Send `multipart/form-data` with:

- `file`: a PNG, JPEG or WebP image, at most 20 MB. The type is worked out from the bytes, not the name. It's
  stored as sent; the scene page shows a 640×480 preview that opens the full image.
- `taken_at` (optional): when the screenshot was taken, ISO 8601 with an offset. Kept with the image, as is
  the account that sent it, for admins; neither is shown on the page.

Responses:

- **`201 Created`**: the image, below.
- **`200 OK`**: this scene already has an image with exactly these bytes. The response is that image, and
  nothing is added, so a client can retry safely. The same image can go to a different scene.
- `400` with no `file`, `404` with no such scene, `413` over 20 MB, `422 { "error": "..." }` if it isn't PNG,
  JPEG or WebP or `taken_at` isn't a time.

The image: `id` (the attachment's id), `scene` (`{ id, name, url }`), `url` (the full image), `preview_url`,
`content_type`, `byte_size` and `created_at`. Image links redirect to the file's storage and work for anyone.

```bash
curl -s -H "Authorization: Bearer $TOKEN" -F file=@screenshot.png -F taken_at=2026-11-23T10:15:00-08:00 \
  https://www.sotalore.com/api/v1/scenes/41/images
```

### Scene notes

Private transcripts of what was said about a scene while playing: the companion records and transcribes them,
and an agent later writes the scene's narrative from them. **Notes are private.** Only root sees them on the
site (on the scene's page, where root deletes them), and only a token with the `notes` scope reads them; `read`
doesn't. The site keeps only the text, never audio, and keeps it out of its logs.

#### `POST /scenes/:id/notes`

Adds a note to the scene. Scope `notes`. Find the scene first with `GET /scenes`, as for images. Send JSON:

| Field | |
|---|---|
| `text` | the transcript, plain text, at most 20,000 characters (required) |
| `recorded_at` | when recording started, ISO 8601 with an offset (required) |
| `client_id` | the client's own id for the note, at most 100 characters, unique for this account (required); make it when recording starts and send the same one on every retry |
| `duration` | the recording's length in whole seconds (optional) |
| `transcriber` | what made the text, such as `whisper-large-v3`, at most 100 characters (optional) |

Responses:

- **`201 Created`**: the note, below.
- **`200 OK`**: this account already sent this `client_id` for this scene with the same text. The response is
  that note and nothing is added, so a client can retry safely.
- **`409 Conflict`** `{ "error": "...", "note": {...} }`: the `client_id` was already sent with a different
  scene or text; `note` is the one already there. Don't retry: it's a bug in the client, and the API doesn't
  overwrite.
- `404` with no such scene, `422 { "errors": [...] }` for a missing or invalid field (or
  `{ "error": "..." }` if `recorded_at` isn't a time).

The note: `id`, `scene` (`{ id, name, url }`), `text`, `recorded_at`, `duration` (or `null`), `transcriber` (or
`null`), `client_id` and `created_at` (when the site got it).

```bash
curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"text":"...","recorded_at":"2026-11-23T10:15:00-08:00","duration":42,"client_id":"7f3c..."}' \
  https://www.sotalore.com/api/v1/scenes/41/notes
```

#### `GET /notes`

Paged notes, oldest first (by when the site got them), under `notes`, in the shape above. Scope `notes`.

| Param | |
|---|---|
| `scene_id` | only this scene's notes |
| `since` | only notes the site got at or after this time, ISO 8601 (`422` if it isn't one) |

To pick up what's new, keep the latest `created_at` seen and pass it as `since` next time. That note comes back
again (`since` includes it), so skip ids already seen.

### Item review

#### `GET /item_reviews`

The ADM → Item Review lists: items whose kind may be wrong, with the evidence. Paged, under `items`, plus
`filter` (the one used). Scope `read`.

| Param | |
|---|---|
| `filter` | `abstract`, `group`, `archetype`, `category`, `suspect`, `unkeyed` or `recent` |
| `issues` | `true`: only items with issues |
| `q` | name contains |

Each row: an item ref, plus `members`, `groups`, `ingredient_of`, `ingredient_of_game_recipes`, `made_by`,
`made_by_game_recipes`, `modified`, `made_from_groups`, `game_keys`, and `issues`
(`[{ message, suggest }]`, where `suggest` is a suggested kind or `null`).

### Proposals

An AI account proposes a change; an editor accepts or rejects it at ADM → Proposals. Accepting runs the same
code as editing on the site. A proposal changes nothing until someone accepts it.

#### `GET /proposal_changes`

The kinds of change that can be proposed, under `changes`: each `{ key, subject, description, parameters }`.
`subject` is the class it's about (`Item`, `Recipe`, `Collection`) or `null` for a change that makes something
new; `parameters` maps each parameter name to a description. This is the source of truth for what
`POST /proposals` accepts, and it grows without a version change. Scope `read`.

#### `GET /proposals`

The token account's own proposals, newest first, at most 100, under `proposals`. No paging. `?status=`
filters by status. Scope `read`.

#### `GET /proposals/:id`

One proposal. `403` if it isn't the account's own. Scope `read`.

#### `POST /proposals`

Proposes a change. Scope `propose`.

```json
{ "change": "collection.add_items", "subject_id": 12,
  "params": { "item_ids": [ 1726, 1731 ] },
  "reason": "...", "evidence": "..." }
```

- `change`: a key from `/proposal_changes`.
- `subject_id`: the id of the item, recipe or collection it's about; leave it out for a change with no subject.
- `params`: that change's parameters, each a value or a list of values. Parameters the change doesn't have
  are reported as errors, not dropped.
- `reason`, `evidence`: plain text for the editor.

Returns `201` and the proposal, or `422 { "errors": [...] }` (an unknown change, a missing subject, bad or
unknown parameters, or an identical pending proposal).

#### `POST /proposals/:id/withdraw`

Takes back one of the account's own pending proposals. Returns the proposal, now `withdrawn`. `403` if it
isn't the account's own or isn't pending. Scope `propose`.

## Versions

The version is the `v1` in the path. It's the site API's version, unrelated to the `apiVersion` in the
plugins' export files (that's the game's Lua API).

- **Not breaking, so no new version:** a new endpoint, a new field in a response, a new optional parameter, a
  new value of a field that is documented as growing (`/proposal_changes` keys), or a new kind of proposal.
  Readers ignore what they don't know.
- **Breaking, so `v2`:** removing or renaming a field or endpoint, changing a field's type or meaning, making
  an optional parameter required, or changing which status code a case returns.
- A breaking change goes in this order, as for the plugins' formats (`hq/AGENTS.md`): the app opens an issue
  in each reader's repo (today `sotalore/companion`), adds `/api/v2` beside `v1`, and keeps `v1` working until
  every reader has moved. Then `v1` is removed, in its own PR.
- Every change to the API, breaking or not, is listed in the changelog below, in the PR that makes it.

## Changelog

- **2026-11-23**: Scene notes: `POST /scenes/:id/notes`, `GET /notes` and the `notes` scope
  (sotalore/sotalore#311).
- **2026-11-23**: `GET /scenes`, `POST /scenes/:id/images` and the `images` scope (sotalore/sotalore#304).
- **2026-11-23**: `GET /skills` (sotalore/sotalore#303).
- **2026-11-23**: Uploads: `POST /recipe_imports`, `/item_catalog_imports` and `/finds_imports`, the `upload`
  scope, and `review_url` on recipe imports (sotalore/sotalore#300).
- **2026-11-23**: First written (sotalore/sotalore#300), describing `v1` as it stands: `/me`, items, materials,
  collections, recipes, recipe imports, item reviews and proposals.

---
name: propose-changes
description: Propose changes to the live SotA Lore site (www.sotalore.com) through its API, as the site's AI account, for an editor to review — retiring recipes, fixing items, and building collections. Use when asked to propose, suggest or review changes to the site's data, to build or fill collections, or to work through a list (stale recipes, item kinds) and put the fixes up for review.
---

# Proposing changes to the site

The site has an API for AI accounts. An AI account can read the site's data and **propose** changes; it
can't make them. An editor (usually Darren) reviews each proposal at ADM → Proposals and accepts or
rejects it. Accepting runs the same code as editing on the site. Nothing you send changes the site
until someone accepts it.

You can't play the game. A proposal is a claim about the game, so it stands or falls on its **reason**
and **evidence**: say what you found, where, and why it means the change is right.

## Access

- The API is `https://www.sotalore.com/api/v1/`. It's the live site, not localhost.
- The token is in `~/.config/sotalore/api-token` (mode 600). Never print it, echo it or put it in a file,
  a commit or a chat message. Read it into the request header and nowhere else:

  ```bash
  curl -s -H "Authorization: Bearer $(cat ~/.config/sotalore/api-token)" https://www.sotalore.com/api/v1/me
  ```

- `GET /me` says which account and scopes the token has. Proposing needs `propose`; reading needs
  `read`. If the file is missing, or `/me` returns 401 (expired or revoked), stop and ask Darren for a
  new token (ADM → AI Access). Don't look for credentials anywhere else.
- Send JSON when proposing: `-H "Content-Type: application/json" -d @file.json` (write the body to a
  scratch file; it's easier to get the quoting right).

## Reading

All `GET`, all needing `read`. Lists are paged: `?page=`, `?per=` (at most 100), and they return
`page.total_pages`.

| Endpoint | What |
|----------|------|
| `/proposal_changes` | **The kinds of change you can propose, with their parameters.** Read it first; it's the source of truth and grows over time. |
| `/items?q=&kind=&use=` | Items by name, kind (`concrete`, `group`, `archetype`, `category`) or use (`armor`, `weapon`, `food`, ...). |
| `/items/:id` | Everything about one: game keys, `tooltip_types` (the game's type lines, such as "Leather Light Armor (Head)"), `effects`, groups and categories it's in (`member_of`), `collections`, recipes, and `sources` and `roles`: how it's obtained and what it's used for, read from the site's records. Trust those over `use` and `source`, which are old and often wrong. `materials` says where it stands among the crafting materials, when it's among them. |
| `/materials` | The crafting materials by family (metal, wood, leather, cloth) and tier: what each common one is refined from (`raw`), each uncommon one's `base` and `additives`, and their `forms`. Worked out from the refining recipes. |
| `/collections` | Every collection, with `parents` and `children` (the tree) and how many items each lists. |
| `/collections/:id` | One collection: `items` listed directly, and `all_items` including those inside it. |
| `/recipes?q=&craft_skill=&status=&synced=` | Recipes; `synced=false` means no game id. |
| `/recipes/:id` | One recipe, with what helps judge whether it belongs: game id, the latest full import, duplicates by name. |
| `/recipe_imports`, `/recipe_imports/:id/stale` | Game exports, and the site recipes a full export didn't have. |
| `/item_reviews?filter=` | Item Review's lists (`suspect`, `unkeyed`, ...), with issues and suggested kinds. |
| `/proposals?status=` | Your own proposals and what happened to them, with any `review_note` or `error`. |

## Proposing

`POST /proposals` with:

```json
{ "change": "collection.add_items", "subject_id": 12,
  "params": { "item_ids": [ 1726, 1731 ] },
  "reason": "...", "evidence": "..." }
```

- `change` is a key from `/proposal_changes`; `subject_id` is the item, recipe or collection it's about
  (left out for changes that make something new, such as `collection.create`); `params` are that
  change's parameters. Ids, not names: look them up first.
- The response is the proposal (`201`) with a `summary` to check it says what you meant, or `422` with
  `errors` saying what's wrong. Fix and resend; don't guess.
- `POST /proposals/:id/withdraw` takes back a pending one you got wrong.

### What makes a good proposal

- **One decision per proposal.** Darren accepts or rejects each as a whole. Making a collection is one
  decision, so `collection.create` takes its name, the collections it sits inside (`parent_ids`) and its
  items (`item_ids`) together. Don't spread one decision over many proposals, or bundle unrelated ones.
- **Reason**: plain words, a sentence or three, saying why. **Evidence**: the facts you checked, with ids,
  so he can check them quickly. Examples that were accepted:
  - reason: "Old duplicate of #1259, which the game export matched and synced. This one lacks the
    Protractor Angle Finder tool and a proficiency, and dates from 2016. No users saved it."
  - evidence: "Import #37 (full export) matched #1259 by game id; #1 is in its stale list. #1259: 1 Stone
    Chisel, 5 Granite Block, 1 Protractor Angle Finder."
- **Check before proposing**: read the subject's current state, and your pending proposals
  (`/proposals?status=pending`), so you don't propose what's already there or already asked. The site
  refuses an identical pending proposal anyway.
- **Look at what came back.** Rejected proposals have a `review_note` saying why; learn from it before
  sending more of the same kind. Start with a few, and send the rest once those are accepted.
- **Don't invent game facts.** If the evidence isn't there, say so in the reason, or leave it out.

## Collections

Collections are the site's own groupings of items for browsing ("Light Armor", "Poison Potions",
"Fortified Leather Armor"), separate from the game's groups and categories. A collection lists concrete
items and archetypes, and can sit inside several others: "Fortified Leather Armor" is inside both
"Light Armor" and "Leather Armor". It holds everything inside it, so list an item in the narrowest
collection that fits, not in every one above it.

Evidence for where an item belongs, best first:

1. `tooltip_types` on the item: "Leather Light Armor (Head)" is leather, light, worn on the head;
   "Longsword - Bladed" is a bladed weapon. Most crafted gear is an archetype, whose tooltips aren't
   captured, so many won't have any.
2. The game's categories in `member_of`: "Heavy Chest Armor Equipment", "Light Armor Gloves Equipment",
   "One-Handed Blade Equipment" say a lot.
3. Sets named alike: Fortified Leather Boots, Chest Armor, Chest Quarter-Armor, Gloves, Helm and
   Leggings are one set.
4. The item's `use` (`armor`, `weapon`).

Before making a collection, read `/collections` to see the tree, so a new one fits it and doesn't
duplicate one that exists under another name.

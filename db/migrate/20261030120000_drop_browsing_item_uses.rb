class DropBrowsingItemUses < ActiveRecord::Migration[8.1]
  # These only sorted items for browsing, which collections now do (Artifacts,
  # Dyes, Fishing Bait, Houses, Imbued Gems, Imbued Jewels, Pet Gear, Potions),
  # or nothing needs: decoration, pattern, and those no item has. Those items'
  # use becomes unknown (0). It's the site's bookkeeping, not a change in the
  # game, so no revisions.
  def up
    execute 'UPDATE items SET use = 0, updated_at = now() WHERE use IN (6, 8, 9, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22)'
  end

  # Which items had these uses isn't kept.
  def down
  end
end

class DropComponentItemUse < ActiveRecord::Migration[8.1]
  # "component" (3) only ever meant some recipe takes an item, which ItemRoles
  # now works out from the recipes, so those items' use becomes unknown (0).
  # It's the site's bookkeeping, not a change in the game, so no revisions.
  def up
    execute 'UPDATE items SET use = 0, updated_at = now() WHERE use = 3'
  end

  # Which items were components isn't kept, and ItemRoles says it anyway.
  def down
  end
end

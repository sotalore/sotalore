# frozen_string_literal: true

# Single-recipe files from the plugin (sl-recipes-one.json) have the same
# shape as full exports, and were taken for them. A single recipe is never a
# full export.
class UnmarkSingleRecipeFullExports < ActiveRecord::Migration[8.1]
  def up
    execute 'UPDATE recipe_imports SET full_export = false WHERE full_export AND entries_count < 2'
  end

  def down
  end
end

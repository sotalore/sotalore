# frozen_string_literal: true

# What a recipe export file says it holds (plugin 0.4+): "all", "new" or
# "one". Null for older files, which don't say.
class AddExportScopeToRecipeImports < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_imports, :export_scope, :string
  end
end

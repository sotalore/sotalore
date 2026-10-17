# frozen_string_literal: true

# The plugin version that wrote a recipe export (plugin 0.7.1+): full exports
# before 0.5.2 are incomplete.
class AddPluginVersionToRecipeImports < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_imports, :plugin_version, :string
  end
end

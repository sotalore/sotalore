class AddProficiencyToRecipes < ActiveRecord::Migration[5.0]
  def change
    add_column :recipes, :proficiency, :integer
  end
end

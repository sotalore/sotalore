# frozen_string_literal: true

# Applies analyzed RecipeImportEntries to the site:
#
# * unchanged - links the recipe to the game recipe and marks it verified
# * outdated  - updates the recipe to match the game, via RecipeForm so a
#               revision comment records what changed and who did it
# * addition  - creates the recipe, likewise via RecipeForm
#
# Every applied recipe gets game_id/game_synced_at set, is un-retired, and is
# marked verified by the applying user. Entries that fail to save become
# blocked with the validation errors as problems.
class RecipeImportApplier

  attr_reader :user

  def initialize(user, lookup: ItemLookup.new)
    @user = user
    @lookup = lookup
  end

  # Returns true when applied.
  def apply(entry)
    return false unless entry.applicable?

    gr = entry.game_recipe
    recipe = entry.recipe || Recipe.new
    applied = false
    problems = []

    Recipe.transaction do
      unless entry.unchanged?
        form = RecipeForm.new(recipe, user)
        unless form.save(form_attributes(gr))
          problems = form.errors.full_messages + recipe.errors.full_messages
          raise ActiveRecord::Rollback
        end
      end

      now = Time.current
      recipe.update_columns(game_id: gr.game_id, game_synced_at: now, retired_at: nil)
      recipe.verify!(user)
      entry.update_columns(status: RecipeImportEntry.statuses[:applied],
                           recipe_id: recipe.id, applied_at: now, updated_at: now)
      applied = true
    end

    unless applied
      entry.update_columns(status: RecipeImportEntry.statuses[:blocked],
                           problems: problems.uniq.presence || [ 'Could not be saved' ])
    end
    applied
  end

  private

  def form_attributes(gr)
    {
      name: gr.name,
      craft_skill: gr.craft_skill.to_param,
      proficiency: gr.proficiency,
      ingredients_attributes: lines_attributes(gr.ingredients),
      results_attributes: lines_attributes(gr.results),
    }
  end

  def lines_attributes(lines)
    lines.each_with_index.to_h do |line, i|
      item_id = @lookup.id_for(line.name) or
        raise ArgumentError, "Unknown item #{line.name.inspect}"
      [ i.to_s, { 'item_id' => item_id.to_s, 'count' => line.count.to_s } ]
    end
  end

end

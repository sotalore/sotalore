# frozen_string_literal: true

# Finds the site's old per-combination recipes that an archetype recipe
# from the game covers, so they can be deleted along with what they make.
# "Copper Two-Handed Sword with Copper Hilt" is one of the choices of the
# game's "Two-handed Sword" recipe (see ArchetypeOptions); the game has no
# such recipe or item.
#
# An old recipe (no game id) is a candidate when its result is named after
# the archetype, followed by nothing, " with " or " of " ("Bronze Shortsword
# with Iron Hilt", "Longsword of Crushing/Iron Longsword with Copper Hilt",
# but not "Epic Plate Leggings Half-Armor", a kind of its own), and the
# archetype recipe is in the same craft skill. It *fits* when every
# ingredient is one the archetype recipe takes, or a member of a group it
# takes; counts aren't compared. Candidates that don't fit usually use
# materials the game no longer has ("Crimson Pine"), and are listed with
# what doesn't fit, for an admin to judge.
class ArchetypeCleanup

  Candidate = Data.define(:recipe, :archetype_recipe, :misfits, :items) do
    def fits? = misfits.empty?
  end

  # A result of the old recipe, and whether deleting the recipe deletes it.
  # +kept_because+ says why not.
  ResultItem = Data.define(:item, :kept_because) do
    def deleted? = kept_because.nil?
  end

  def candidates
    @candidates ||= old_recipes.filter_map { candidate_for(_1) }
                               .sort_by { [ _1.archetype_recipe.name.downcase, _1.recipe.name.downcase ] }
  end

  # { archetype recipe => [ Candidate ] }
  def by_archetype_recipe = candidates.group_by(&:archetype_recipe)

  # Deletes the candidates with the given recipe ids, and the items they
  # make that nothing else needs. Returns [ recipes, items ] deleted.
  def delete!(recipe_ids)
    ids = recipe_ids.map(&:to_i)
    doomed = candidates.select { ids.include?(_1.recipe.id) }
    Recipe.transaction do
      items = doomed.flat_map { |c| c.items.select(&:deleted?).map(&:item) }.uniq
      doomed.each { Recipe.find(_1.recipe.id).destroy! }
      items.each { Item.find(_1.id).destroy! }
      [ doomed.size, items.size ]
    end
  end

  private

  def old_recipes
    Recipe.active.where(game_id: nil)
          .includes(ingredients: :item, results: { item: %i[ game_keys group_memberships ] })
          .reject { _1.template? || _1.modification? }
  end

  def archetype_recipes
    @archetype_recipes ||=
      Recipe.active.where.not(game_id: nil).includes(ingredients: :item, results: :item)
            .select { |r| r.archetype? && r.ingredients.any? { _1.item.group? } }
  end

  def group_members
    @group_members ||= ItemMembership.joins(:group).merge(Item.kind_is_group).pluck(:group_id, :member_id)
                                     .group_by(&:first).transform_values { |pairs| pairs.to_set(&:last) }
  end

  def candidate_for(recipe)
    named = archetype_recipes.select { _1.craft_skill == recipe.craft_skill && named_after?(recipe, _1) }
    return if named.empty?

    # The closest: one it fits, then the longest name ("Epic Cloth Gloves"
    # over "Cloth Gloves").
    best = named.max_by { |a| [ misfits(recipe, a).empty? ? 1 : 0, archetype_names(a).map(&:size).max ] }
    Candidate.new(recipe, best, misfits(recipe, best), recipe.results.map { result_item(_1.item) })
  end

  def archetype_names(recipe)
    recipe.results.map(&:item).select(&:archetype?).map(&:name)
  end

  def named_after?(recipe, archetype_recipe)
    patterns = archetype_names(archetype_recipe).map do |name|
      /(?:\A|[\s\/])#{Regexp.escape(name)}(?=\z| with | of )/i
    end
    recipe.results.any? { |result| patterns.any? { result.item.name.match?(_1) } }
  end

  # What keeps +recipe+ from fitting +archetype_recipe+: ingredients it
  # doesn't take, and what it takes that +recipe+ lacks.
  def misfits(recipe, archetype_recipe)
    @misfits ||= {}
    @misfits[[ recipe.id, archetype_recipe.id ]] ||= begin
      pool = archetype_recipe.ingredients.map(&:item)
      extra = recipe.ingredients.map(&:item).reject do |item|
        index = pool.index { |slot| slot == item || group_members[slot.id]&.include?(item.id) }
        index && pool.delete_at(index)
      end
      extra.sort_by(&:name).map { "#{_1.name} isn't in the game's recipe" } + pool.sort_by(&:name).map { "no #{_1.name}" }
    end
  end

  def result_item(item)
    kept_because =
      if !item.concrete? then "it's #{item.kind_label}"
      elsif item.game_keys.any? then 'it has a game key'
      elsif item.results_count > 1 then 'other recipes make it'
      elsif item.ingredients_count.positive? then 'recipes use it'
      elsif item.group_memberships.any? then "it's in a group or category"
      end
    ResultItem.new(item, kept_because)
  end

end

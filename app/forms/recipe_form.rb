class RecipeForm < ApplicationForm

  attr_reader :recipe
  alias_method :recipe, :model

  after_save :record_revision_comment

  def initialize(*args)
    super
    @orig_ingredients = CountedItemList.new(recipe.ingredients)
    @orig_results     = CountedItemList.new(recipe.results)
  end

  delegate :id, :persisted?,
           :name, :name=,
           :item_count, :item_count=,
           :craft_skill=,
           :proficiency, :proficiency=,
           :teachable, :teachable=,
           :results, :ingredients,
         to: :recipe

  def craft_skill
    recipe.craft_skill&.to_param
  end

  validates :craft_skill, presence: true
  validates :name, presence: true
  validate  :has_non_empty_results
  validate  :has_non_empty_ingredients
  validate  :recipe_key_is_unique

  def setup_for_view
    results.build(count: nil) while results.length < 6
    ingredients.build(count: nil) while ingredients.length < 10
  end

  def ingredients_attributes=(attrs={})
    update_items_from_attributes(recipe.ingredients, attrs)
  end

  def results_attributes=(attrs={})
    update_items_from_attributes(recipe.results, attrs)
  end

  private

  def update_items_from_attributes(proxy, attrs)
    remaining = proxy.to_a.dup
    attrs.values.each do |ing|
      count   = ing['count'].to_i
      item_id = ing['item_id'].to_i
      if item = proxy.find { |i| i.item_id == item_id }
        if count > 0
          remaining.delete(item)
          item.count = count
          # else it stays in 'remaining' and is deleted
        end
      elsif count > 0
        proxy.build do |item|
          item.item_id = item_id
          item.recipe  = recipe
          item.count   = count
        end
      end
    end
    remaining.each(&:mark_for_destruction)
  end

  def has_non_empty_results
    if non_empty_results.empty?
      errors.add(:results, 'must have at least one item as output')
    end
  end

  def has_non_empty_ingredients
    if non_empty_ingredients.empty?
      errors.add(:ingredients, 'must have at least one ingredient')
    end
  end

  def non_empty_results
    results.select { |r| r.item_id.present? && r.count.to_i > 0 }
  end

  def non_empty_ingredients
    ingredients.select { |r| r.item_id.present? && r.count.to_i > 0 }
  end

  def recipe_key_is_unique
    recipe.set_recipe_key
    return unless recipe.recipe_key
    other = Recipe.find_by(recipe_key: recipe.recipe_key)
    if other && other.id != recipe.id
      errors.add(:base, %Q{This recipe already exists as "#{other.name}"})
    end
  end

  def record_revision_comment
    @orig_ingredients.compare_to(recipe.ingredients)
    ingredient_changes = @orig_ingredients.as_json

    @orig_results.compare_to(recipe.results)
    result_changes = @orig_results.as_json

    any_changes = ingredient_changes.any? ||
                  result_changes.any? ||
                  recipe.previous_changes.any?

    return unless any_changes

    what_changed = recipe.previous_changes.except(
      :recipe_key, :id, :updated_at, :created_at)

    if cs = what_changed[:craft_skill]
      what_changed[:craft_skill] = cs.map { |c| c&.name }
    end
    all_changes = {changes: what_changed}

    if ingredient_changes.any?
      all_changes[:ingredient_changes] = ingredient_changes
    end

    if result_changes.any?
      all_changes[:result_changes] = result_changes
    end

    recipe.comments.create!(
      author: current_user,
      comment_type: 'revision',
      body: all_changes.to_json)
  end
end

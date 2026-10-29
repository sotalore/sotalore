# frozen_string_literal: true

# The crafting materials, worked out from the refining recipes when read
# rather than kept by hand. Refining makes the common materials from what's
# gathered (Copper Ingot from Copper Ore, Pine Timber from Pine Wood), and
# refining a common one again with a gathered additive makes an uncommon one
# (Bronze Ingot is Copper Ingot and Tin Ore, Hard Maple Timber is Maple Timber
# and Sooty Bark). Each is refined into forms that production takes (Coil of
# Bronze Wire, Hard Maple Board, Hardened Leather Strap).
#
# Only the refining recipes that feed production count (see
# .refining_recipes), and only those of the skills that make gear materials;
# a material's family is its skill's. Fuel and tools (coal, creosote, curing
# salt, molds) don't count as what a recipe takes. A material is refined
# again, which leaves out what refining makes from gathered things and
# production takes as it is (dyes, glass).
class Materials

  FAMILIES = { 'smelting' => 'metal', 'milling' => 'wood', 'tanning' => 'leather', 'textiles' => 'cloth' }.freeze
  TIERS = %w[ common uncommon ].freeze

  # +raw+ is what a common one is refined from (Copper Ore); +base+ and
  # +additives+ what an uncommon one is (Copper Ingot, Tin Ore). +forms+ are
  # what it's refined into next. Each is an Item, or a list of them.
  Material = Data.define(:item, :family, :tier, :raw, :base, :additives, :forms) do
    def common? = tier == 'common'
    def uncommon? = tier == 'uncommon'
  end

  # The refining recipes that feed production, not retired: those a
  # production recipe takes what it makes from (directly or as one of a
  # group's items), or another that feeds production does. That leaves out
  # refining that makes only finished things: stone walls, rugs, mounted
  # heads, jewelry upgrades.
  # Works on ids, loading only the recipes it keeps: there are over a
  # thousand recipes.
  def self.refining_recipes
    active = Recipe.active
    refining = Recipe.active.where(craft_skill: CraftSkill::ALL.select { _1.category_key == 'refining' }.map(&:key))
                     .pluck(:id).to_set
    takers = Ingredient.where(recipe_id: active.select(:id)).pluck(:item_id, :recipe_id)
                       .group_by(&:first).transform_values { _1.map(&:last) }
    makes = Result.where(recipe_id: refining.to_a).pluck(:recipe_id, :item_id)
                  .group_by(&:first).transform_values { _1.map(&:last) }
    groups = ItemMembership.pluck(:member_id, :group_id).group_by(&:first).transform_values { _1.map(&:last) }
    users = refining.to_h do |id|
      items = makes.fetch(id, []).flat_map { [ _1 ] + groups.fetch(_1, []) }
      [ id, items.flat_map { takers.fetch(_1, []) }.uniq - [ id ] ]
    end

    feeding = Set.new
    loop do
      added = refining.reject { feeding.include?(_1) }.select do |id|
        users[id].any? { !refining.include?(_1) || feeding.include?(_1) }
      end
      break if added.empty?
      feeding.merge(added)
    end
    Recipe.where(id: feeding.to_a).includes(:ingredients, :results).sort_by { [ _1.proficiency.to_i, _1.name ] }
  end

  # Whether a recipe of one of FAMILIES' skills takes or makes +item+: a
  # quick check before working the materials out.
  def self.involves?(item)
    recipes = Recipe.active.where(craft_skill: FAMILIES.keys)
    recipes.where(id: Ingredient.where(item_id: item.id).select(:recipe_id))
           .or(recipes.where(id: Result.where(item_id: item.id).select(:recipe_id))).exists?
  end

  # By family (in FAMILIES order), then tier, then name.
  def all
    @all ||= build.sort_by { [ FAMILIES.values.index(_1.family), TIERS.index(_1.tier), _1.item.name.downcase ] }
  end

  # { family => materials }, in FAMILIES order.
  def by_family = all.group_by(&:family)

  def find(item) = all.find { _1.item == item }

  # The uncommon materials refined from +material+.
  def uncommon_of(material) = all.select { _1.base == material.item }

  # The material +item+ is a form of, if it is one.
  def form_of(item) = all.find { _1.forms.include?(item) }

  # The materials +item+ is refined into: as what a common one is refined
  # from, or an additive to an uncommon one.
  def refined_into(item) = all.select { _1.raw.include?(item) || _1.additives.include?(item) }

  # The recipe that makes +material+ from what's gathered, rather than from
  # scrap; the first to learn when there are several.
  def recipe_for(material)
    making = recipes_making(material.item).select do |recipe|
      takes(recipe).all? { gathered?(_1) || find(_1)&.common? }
    end
    making.min_by { [ takes(_1).size, _1.proficiency.to_i ] }
  end

  # { item => how many } one +material+ takes in gathered goods and fuel,
  # through the material it's refined from: one Bronze Ingot takes 8 Copper
  # Ore, 2 Tin Ore and 4 Chunk of Coal. Tools aren't used up, so aren't
  # counted. Counts can be fractions (one Leather takes ½ Curing Salt).
  def takes_per_unit(material)
    recipe = recipe_for(material) or return {}
    made = recipe.results.find { _1.item_id == material.item.id }.count
    recipe.ingredients.each_with_object(Hash.new(0)) do |ingredient, totals|
      item = items[ingredient.item_id]
      next if item.use_is_tool? || ItemRoles.new(item).tool?
      count = Rational(ingredient.count, made)
      base = find(item)
      next totals[item] += count unless base
      takes_per_unit(base).each { |taken, n| totals[taken] += n * count }
    end
  end

  private

  def build
    commons
    uncommons
    forms
    # Something also made from a material (Iron Bar, from Iron Ore or Iron
    # Ingot) is a form of it.
    formed = @found.values.flat_map { _1[:forms] }
    @found.reject! { |_, m| formed.include?(m[:item]) }
    @found.values.map do |m|
      Material.new(item: m[:item], family: m[:family], tier: m[:tier], raw: m[:raw], base: m[:base],
                   additives: m[:additives], forms: m[:forms].uniq.sort_by { _1.name.downcase })
    end
  end

  # Refined from gathered things alone, and refined again.
  def commons
    @found = {}
    recipes.each do |recipe|
      takes = takes(recipe)
      next if takes.any? { crafted?(_1) } || takes.none? { gathered?(_1) }

      results(recipe).each do |item|
        next unless refined_again?(item)
        found = @found[item.id] ||= material(item, recipe, 'common')
        found[:raw] |= takes.select { gathered?(_1) }
      end
    end
  end

  # Refined from a common material and something gathered its own recipes
  # don't take, and refined again.
  def uncommons
    recipes.each do |recipe|
      base, others = from_one_material(recipe)
      next unless base && @found[base.id][:tier] == 'common'
      additives = others - recipes_making(base).flat_map { takes(_1) }
      next if additives.empty?

      results(recipe).each do |item|
        next unless refined_again?(item)
        @found[item.id] ||= material(item, recipe, 'uncommon').merge(base:, additives:)
      end
    end
  end

  # Refined from one material and nothing else crafted.
  def forms
    recipes.each do |recipe|
      base, = from_one_material(recipe)
      next unless base
      results(recipe).each { |item| @found[base.id][:forms] << item unless @found[item.id]&.dig(:base) }
    end
  end

  def material(item, recipe, tier)
    { item:, family: FAMILIES[recipe.craft_skill.key], tier:, raw: [], base: nil, additives: [], forms: [] }
  end

  # The material +recipe+ takes, and the rest it takes, when it takes one
  # material and nothing else crafted.
  def from_one_material(recipe)
    crafted, others = takes(recipe).partition { crafted?(_1) }
    return unless crafted.one? && @found[crafted.first.id]
    [ crafted.first, others ]
  end

  def recipes
    @recipes ||= self.class.refining_recipes.select { FAMILIES.key?(_1.craft_skill.key) && !_1.modification? }
  end

  def recipes_making(item) = recipes.select { |r| r.results.any? { _1.item_id == item.id } }

  # What +recipe+ takes, apart from fuel and tools.
  def takes(recipe) = recipe.ingredients.map { items[_1.item_id] }.reject { fuel_or_tool?(_1) }

  def results(recipe) = recipe.results.map { items[_1.item_id] }.select(&:kind_is_concrete?)

  def items
    @items ||= Item.where(id: recipes.flat_map { |r| (r.ingredients + r.results).map(&:item_id) })
                   .includes(:game_keys).index_by(&:id)
  end

  def fuel_or_tool?(item) = item.use_is_fuel? || item.use_is_tool? || ItemRoles.new(item).tool?

  def crafted?(item)
    @crafted ||= Result.joins(:recipe).merge(Recipe.active).distinct.pluck(:item_id).to_set
    @crafted.include?(item.id)
  end

  def gathered?(item)
    @gathered ||= HarvestYield.distinct.pluck(:item_id).to_set
    @gathered.include?(item.id)
  end

  def refined_again?(item)
    @taken ||= recipes.flat_map { |r| r.ingredients.map(&:item_id) }.to_set
    @taken.include?(item.id)
  end
end

# frozen_string_literal: true

# Fills in everything a template recipe implies (see Recipe::KINDS). Given
# "Metal Two-handed Sword Blade" made from 5 "Metal Ingot" (a group), this
# works out, for each member of the ingredient group ("Iron Ingot", ...):
#
#   - the concrete item  "Iron Two-handed Sword Blade"
#   - its membership in the result group
#   - a recipe making it, identical to the template but with the ingredient
#     group swapped for the member
#
# Names come from the groups' differing leading words: "Metal Ingot" vs
# "Iron Ingot" gives Metal => Iron, and that is swapped in the result group's
# name. Anything already there is left alone, so this is safe to rerun after
# adding members to the ingredient group.
#
# How hard a variant is to learn depends on its material (see Item#basic?):
# basic ones get proficiency 1 and are re-teachable; the rest get the
# template's proficiency and are not teachable. Both are only defaults, to be
# overridden per member when applying.
class TemplateExpansion

  Variant = Struct.new(:member, :names, :items, :recipe_name, :recipe, :memberships_missing, :proficiency, :teachable, keyword_init: true) do
    # Nothing left to create.
    def complete?
      recipe.present? && items.all?(&:last) && !memberships_missing
    end

    def underivable? = names.values.any?(&:nil?)
  end

  attr_reader :template, :error, :ingredient_group, :from_word

  def initialize(template)
    @template = template
    @result_groups = []
    analyze
  end

  def valid? = error.nil?

  # One Variant for each member of the ingredient group.
  def variants
    return [] unless valid?
    @variants ||= ingredient_group.members.includes(:aliases).map { |member| variant_for(member) }
  end

  # Creates what's missing for the given members (all of them if none given).
  # Returns the Recipes created.
  # +settings+ maps a member's id to { proficiency:, teachable: } for its new
  # recipe, replacing the defaults.
  def apply!(user, members: nil, settings: {})
    raise ArgumentError, error unless valid?

    wanted = members && Array(members).map(&:id)
    created = []
    Recipe.transaction do
      variants.each do |variant|
        next if wanted && wanted.exclude?(variant.member.id)
        created << create_variant(variant, user, settings[variant.member.id] || {})
      end
    end
    created.compact
  end

  private

  def analyze
    groups = template.ingredients.map(&:item).select(&:group?)
    @result_groups = template.results.map(&:item).select(&:group?)
    return @error = 'This recipe does not make a group.' if @result_groups.empty?
    return @error = 'This recipe does not take a group to vary.' if groups.empty?

    candidates = groups.filter_map do |group|
      word = leading_words(group, group.members.first)&.first
      [ group, word ] if word
    end
    # Prefer the group whose word the result is named after ("Metal Hilt").
    named = candidates.select { |_, word| @result_groups.any? { word_pattern(word).match?(_1.name) } }
    candidates = named if named.any?
    case candidates.size
    when 0 then @error = "Can't work out how #{groups.to_sentence} varies; it needs members that share an ending."
    when 1 then @ingredient_group, @from_word = candidates.first
    else @error = "More than one ingredient group could vary: #{candidates.map { _1.first.name }.to_sentence}."
    end
  end

  # The words in front of what two names share at the end:
  # "Metal Ingot" and "Iron Ingot" give [ "Metal", "Iron" ].
  def leading_words(group, member)
    return unless member
    a, b = group.name.split, member.name.split
    shared = 0
    shared += 1 while shared < [ a.size, b.size ].min - 1 && a[-1 - shared] == b[-1 - shared]
    return if shared.zero?
    [ a[0...-shared].join(' '), b[0...-shared].join(' ') ]
  end

  def word_pattern(word) = /(?<![[:alnum:]])#{Regexp.escape(word)}(?![[:alnum:]])/i

  def swap(name, member)
    from, to = leading_words(ingredient_group, member)
    return unless from&.casecmp?(from_word)
    # "Metal Hilt" becomes "Iron Hilt"; "Dagger Blade", which doesn't name
    # the material, becomes "Iron Dagger Blade".
    name.match?(word_pattern(from_word)) ? name.sub(word_pattern(from_word)) { to } : "#{to} #{name}"
  end

  def variant_for(member)
    names = @result_groups.to_h { |group| [ group, swap(group.name, member) ] }
    return Variant.new(member: member, names: names, items: []) if names.values.any?(&:nil?)

    items = names.map { |group, name| [ name, Item.find_by_name(name).first ] }
    recipe_name = swap(template.name, member)
    proficiency, teachable = defaults_for(member)
    Variant.new(
      member: member, names: names, items: items, recipe_name: recipe_name,
      proficiency: proficiency, teachable: teachable,
      recipe: existing_recipe(member, recipe_name),
      memberships_missing: names.any? { |group, _| !membership_exists?(group, items.assoc(names[group])&.last) }
    )
  end

  def defaults_for(member)
    member.basic? ? [ 1, 're_teachable' ] : [ template.proficiency, 'not_teachable' ]
  end

  def membership_exists?(group, item)
    item && ItemMembership.exists?(group_id: group.id, member_id: item.id)
  end

  def existing_recipe(member, recipe_name)
    build_recipe(member, recipe_name, {}).then do |draft|
      Recipe.find_by_name(recipe_name) || Recipe.find_by(recipe_key: draft.recipe_key)
    end
  end

  # The template with +member+ in place of the ingredient group, and +items+
  # (group => item) in place of the result groups.
  def build_recipe(member, recipe_name, items, proficiency: nil, teachable: nil)
    recipe = Recipe.new(name: recipe_name, craft_skill: template.craft_skill,
                        proficiency: proficiency, teachable: teachable)
    template.ingredients.each do |ingredient|
      item = ingredient.item == ingredient_group ? member : ingredient.item
      recipe.ingredients.build(item: item, count: ingredient.count)
    end
    template.results.each do |result|
      recipe.results.build(item: items.fetch(result.item, result.item), count: result.count)
    end
    recipe.set_recipe_key
    recipe
  end

  def create_variant(variant, user, setting)
    return if variant.underivable?

    items = variant.names.to_h do |group, name|
      [ group, find_or_create_item(name, group, variant.member, user) ]
    end
    items.each do |group, item|
      next if membership_exists?(group, item)
      membership = ItemMembership.create!(group: group, member: item)
      RevisionRecorder.membership(membership, user, :added)
    end

    return if variant.recipe
    recipe = build_recipe(variant.member, variant.recipe_name, items,
                          proficiency: setting.fetch(:proficiency, variant.proficiency),
                          teachable: setting.fetch(:teachable, variant.teachable))
    recipe.save!
    recipe.comments.create!(author: user, comment_type: 'revision',
                            body: { changes: { template: [ nil, template.name ] } }.to_json)
    recipe
  end

  def find_or_create_item(name, group, member, user)
    Item.find_by_name(name).first || Item.create!(name: name, use: group.use, source: :recipe, basic: member.basic?).tap do |item|
      RevisionRecorder.call(item, user)
    end
  end

end

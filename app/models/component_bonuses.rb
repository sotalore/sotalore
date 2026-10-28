# frozen_string_literal: true

# Crafting bonuses of gear components, by their material and kind, so one
# captured tooltip covers every component of that kind and material. Bronze
# Dagger Blade, Bronze Longsword Blade and Bronze Mace Head all add +3 Melee
# and Ranged Damage, +5% Critical Chance and +5% Critical Damage; so would a
# Bronze Shortsword Blade whose tooltip nobody has captured yet.
#
# A component's kind is a group an archetype recipe takes ("Dagger Blade",
# "Metal Hilt", "Wooden Handle"), and its material the one its recipe takes,
# directly or as a form ("Hard Maple Board" is Hard Maple Timber), or failing
# that the one its name starts with (see Materials). Components with no
# material ("Bandit Dagger Blade", "Elven Hilt") have their own bonuses.
#
# Kinds go together into families on the evidence: two kinds whose captured
# bonuses agree for at least MIN_AGREEING materials, and disagree for none.
# Which go together is still being learned, so this is worked out when read;
# kinds with nothing captured yet go with the kinds GUESSES names, and say so.
class ComponentBonuses

  MIN_AGREEING = 2

  # Kinds with no bonus captured yet, and the kind each is guessed to add
  # what the same material does. The game's gear breakdown calls them all a
  # "Weapon Blade" or "Large Weapon Blade". Checked as captures come in: a
  # captured bonus that disagrees ends the guess.
  GUESSES = {
    'Hand Axe Blade' => 'Dagger Blade', 'War Hammer Head' => 'Dagger Blade',
    'Spear Head' => 'Dagger Blade', 'Trident Head' => 'Dagger Blade',
    'Two-handed Axe Blade' => 'Two-handed Sword Blade', 'Two-handed Hammer Head' => 'Two-handed Sword Blade',
    'Halberd Blade' => 'Two-handed Sword Blade'
  }.freeze

  # +bonus+ is the captured tooltip's lines: [] when it has none, nil when
  # no tooltip that would say has been captured.
  Component = Data.define(:item, :material, :bonus) do
    def captured? = !bonus.nil?
  end

  # A group of components. +captured+ is { material item => Component }, for
  # those whose bonus is captured.
  Kind = Data.define(:group, :components) do
    def name = group.name

    def captured
      components.select(&:captured?).group_by(&:material).transform_values(&:first)
    end
  end

  # Kinds whose components add the same for each material. +guessed+ are
  # those in it only by GUESSES. +captured+ is { material item => Component }.
  Family = Data.define(:kinds, :guessed, :captured) do
    def name = (kinds - guessed).map(&:name).to_sentence
  end

  # What a component adds, and the component whose tooltip says so. Inferred
  # when that's another component; +guessed+ when by GUESSES.
  Bonus = Data.define(:lines, :from, :guessed) do
    def inferred?(item) = from.item != item
  end

  # A comparison of two kinds sharing captured materials.
  Comparison = Data.define(:kinds, :agree, :differ)

  def initialize(materials = Materials.new)
    @materials = materials
  end

  # Whether +item+ is in a group an archetype recipe takes: a quick check
  # before working the bonuses out.
  def self.component?(item)
    archetype_takes = Ingredient.where(recipe_id: Recipe.active.archetypes.select(:id)).select(:item_id)
    ItemMembership.where(member_id: item.id, group_id: archetype_takes).exists?
  end

  # The groups archetype recipes take with at least two components of a
  # material, by name.
  def kinds
    @kinds ||= begin
      takes = Ingredient.where(recipe_id: Recipe.active.archetypes.select(:id)).select(:item_id)
      groups = Item.kind_is_group.where(id: takes).order(:name)
                   .includes(members: [ :game_keys, { recipes: [ :ingredients, :results ] } ])
      groups.filter_map do |group|
        components = group.members.filter_map { component(_1) }
        Kind.new(group:, components:) if components.size >= 2
      end
    end
  end

  # Largest first.
  def families
    @families ||= build_families.sort_by { [ -_1.kinds.size, _1.name ] }
  end

  def family_of(kind) = families.find { _1.kinds.include?(kind) }

  # The kind +item+ is a component of, and its family. An item in two kinds
  # ("Cotton Cloth Strap" is a Cloth Strap and a Cloth or Leather Strap)
  # finds them in the same family.
  def kind_for(item) = kinds.find { |k| k.components.any? { _1.item == item } }
  def family_for(item) = kind_for(item)&.then { family_of(_1) }

  # What +item+ adds: its own captured bonus, else what its family adds for
  # its material. Nil when nobody knows yet.
  def for_item(item)
    kind = kind_for(item) or return
    component = kind.components.find { _1.item == item }
    return Bonus.new(lines: component.bonus, from: component, guessed: false) if component.captured?

    family = family_of(kind)
    from = family.captured[component.material] or return
    Bonus.new(lines: from.bonus, from:, guessed: family.guessed.include?(kind))
  end

  # [ Family, Bonus ] for each family with a bonus captured for +material+
  # (an item), skipping those that add nothing.
  def for_material(material)
    families.filter_map do |family|
      from = family.captured[material]
      [ family, Bonus.new(lines: from.bonus, from:, guessed: false) ] if from&.bonus.present?
    end
  end

  # How each pair of kinds sharing captured materials compares: the
  # evidence families are made from.
  def comparisons
    kinds.combination(2).filter_map do |a, b|
      shared = a.captured.keys & b.captured.keys
      next if shared.empty?
      agree, differ = shared.partition { same?(a.captured[_1], b.captured[_1]) }
      Comparison.new(kinds: [ a, b ], agree:, differ:)
    end
  end

  private

  def component(item)
    material = material_of(item)
    return if material.nil? || material == item
    bonus = item.crafting_bonus
    Component.new(item:, material:, bonus: bonus.any? || item.crafting_bonus_known? ? bonus : nil)
  end

  def material_of(item)
    taken = item.recipes.reject { _1.retired? || _1.modification? }
                .flat_map { |r| r.ingredients.map(&:item_id) }.uniq
    found = taken.filter_map { |id| material_items[id] }.uniq
    return found.first if found.one?
    by_name(item, found.presence || @materials.all.map(&:item))
  end

  # The material +item+'s name starts with, longest first: "Hard Maple
  # Handle" is Hard Maple Timber, not Maple Timber.
  def by_name(item, candidates)
    candidates.sort_by { -short_name(_1).size }.find { item.name.start_with?("#{short_name(_1)} ") }
  end

  # What component names call a material: "Bronze" for Bronze Ingot,
  # "Carapacian Cloth" for Spool of Carapacian Thread, "Simple Leather" for
  # Leather.
  def short_name(material)
    name = material.name.sub(/ (Ingot|Timber)\z/, '').sub(/\ASpool of (.+) Thread\z/, '\1 Cloth')
    name == 'Leather' ? 'Simple Leather' : name
  end

  # { item id => material item }, for materials and their forms.
  def material_items
    @material_items ||= @materials.all.each_with_object({}) do |material, map|
      map[material.item.id] = material.item
      material.forms.each { map[_1.id] ||= material.item }
    end
  end

  def build_families
    families = kinds.map { { kinds: [ _1 ], guessed: [], captured: _1.captured } }
    while (pair = families.combination(2).find { |a, b| joinable?(a[:captured], b[:captured], MIN_AGREEING) })
      families -= pair
      families << merge(*pair)
    end
    GUESSES.each do |name, with|
      alone = families.find { |f| f[:kinds].one? && f[:kinds].first.name == name } or next
      target = families.find { |f| f[:kinds].any? { _1.name == with } } or next
      next unless joinable?(alone[:captured], target[:captured], 0)
      families -= [ alone, target ]
      families << merge(target, alone).merge(guessed: target[:guessed] + alone[:kinds])
    end
    families.map { Family.new(**_1) }
  end

  def joinable?(a, b, minimum)
    shared = a.keys & b.keys
    shared.size >= minimum && shared.all? { same?(a[_1], b[_1]) }
  end

  def merge(a, b)
    { kinds: a[:kinds] + b[:kinds], guessed: a[:guessed] + b[:guessed], captured: b[:captured].merge(a[:captured]) }
  end

  def same?(a, b) = a.bonus.sort == b.bonus.sort
end

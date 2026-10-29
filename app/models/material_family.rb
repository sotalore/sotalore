# frozen_string_literal: true

# One family of materials (metal, wood, leather, cloth) as the gathering
# and refining page shows it: what's gathered for it by gathering skill,
# the common materials refined from that, and the uncommon ones refined
# from those with an additive. See Materials.
class MaterialFamily

  # The items one gathering skill gathers for the family.
  Gathering = Data.define(:skill, :items)

  attr_reader :name, :materials

  def initialize(name, materials = Materials.new)
    @name = name
    @materials = materials
  end

  def all = @all ||= materials.by_family.fetch(name, [])
  def commons = all.select(&:common?)
  def uncommons = all.select(&:uncommon?)

  # What's gathered for it, raw goods before additives.
  def gathered = (all.flat_map(&:raw) + all.flat_map(&:additives)).uniq

  def additive?(item) = all.any? { _1.additives.include?(item) }

  # By gathering skill, in the game's order; anything gathered nobody has
  # seen yielded goes last, with no skill.
  def by_skill
    grouped = gathered.group_by { sources(_1).gathering_skills.first }
    (CraftSkill.gathering + [ nil ]).filter_map { |skill| Gathering.new(skill, grouped[skill]) if grouped[skill] }
  end

  def sources(item)
    @sources ||= {}
    @sources[item.id] ||= ItemSources.new(item)
  end

  # Whether +item+ is gathered for this family, or one of its materials.
  def include?(item) = gathered.include?(item) || all.any? { _1.item == item }

  # The items on +item+'s path through gathering and refining, to mark when
  # it's picked: a material, what it's refined from and its uncommon
  # versions; something gathered, and the materials refined from it.
  def path(item)
    if (material = materials.find(item))
      base = material.base && materials.find(material.base)
      [ item, material.base, *material.raw, *material.additives, *base&.raw,
        *materials.uncommon_of(material).map(&:item) ].compact.uniq
    else
      [ item, *materials.refined_into(item).map(&:item) ]
    end
  end
end

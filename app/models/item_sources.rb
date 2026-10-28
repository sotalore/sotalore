# frozen_string_literal: true

# How an item is obtained, read from what the site records rather than the
# item's stored +source+ and +gathering_skill+, which are old, set by hand
# and often wrong. An item can have several:
#
#   crafted   - a recipe makes it (by skill: smelting, blacksmithing, ...)
#   gathered  - a finds import saw a node or creature yield it; the node's
#               skill (see GatheringNode), or field dressing for a creature
#   salvaged  - salvaging something gives it (see ItemSalvage)
#   bought    - it has a merchant price, taken as a sign a merchant sells it
#   found     - a finds import saw it gained in a scene (looted, bought,
#               gathered or otherwise)
class ItemSources

  KINDS = %i[ crafted gathered salvaged bought found ].freeze

  attr_reader :item

  def initialize(item)
    @item = item
  end

  # The kinds that apply, in KINDS order.
  def kinds
    KINDS.select { |kind| public_send(:"#{kind}?") }
  end

  def crafted? = crafting_skills.any?
  def gathered? = gathering_skills.any?
  def salvaged? = salvaged_from.any?
  def bought? = item.merchant_price.present?
  def found? = scene_count.positive?

  # The skills of the recipes that make it, by name.
  def crafting_skills
    @crafting_skills ||= making_recipes.map(&:craft_skill).uniq.sort_by(&:name)
  end

  # The recipes that make it: not retired, and not modifications (which
  # change an item rather than make one).
  def making_recipes
    @making_recipes ||= item.recipes.reject { _1.retired? || _1.modification? }
  end

  # The skills that gather it, from what finds imports saw yield it.
  def gathering_skills
    @gathering_skills ||= begin
      skills = harvest_sources.map do |source|
        source.is_a?(Creature) ? CraftSkill.find('field_dressing') : source.gathering_skill
      end
      skills.compact.uniq.sort_by(&:name)
    end
  end

  # The gathering nodes and creatures seen yielding it.
  def harvest_sources
    @harvest_sources ||= item.harvest_yields.includes(:source).map(&:source).sort_by(&:name)
  end

  # Nodes seen yielding it that no editor has given a skill yet.
  def unskilled_nodes
    harvest_sources.select { _1.is_a?(GatheringNode) && _1.gathering_skill.nil? }
  end

  # The items that salvage into it, by name.
  def salvaged_from
    @salvaged_from ||= Item.where(id: item.item_salvages_as_result.select(:salvage_from_id)).order(:name).to_a
  end

  def scene_count
    @scene_count ||= item.scene_finds.count
  end
end

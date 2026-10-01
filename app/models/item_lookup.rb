# frozen_string_literal: true

# Resolves item names (as the game spells them) to Item ids, checking item
# names first and then ItemAlias names, case-insensitively. Loads everything
# up front so resolving a whole export is cheap.
class ItemLookup

  def initialize
    @ids = {}
    ItemAlias.pluck(:name, :item_id).each { |name, id| @ids[name.downcase] = id }
    @group_ids = Set.new
    Item.pluck(:name, :id, :abstract).each do |name, id, abstract|
      @ids[name.downcase] = id
      @group_ids << id if abstract
    end
  end

  def id_for(name)
    @ids[name.to_s.downcase]
  end

  def known?(name)
    !!id_for(name)
  end

  # Whether the name resolves to a group (abstract item).
  def group?(name)
    @group_ids.include?(id_for(name))
  end

end

# frozen_string_literal: true

# Resolves item names (as the game spells them) to Item ids, checking item
# names first and then ItemAlias names, case-insensitively. Loads everything
# up front so resolving a whole export is cheap.
class ItemLookup

  def initialize
    @ids = {}
    ItemAlias.pluck(:name, :item_id).each { |name, id| @ids[name.downcase] = id }
    @abstract_ids = Set.new
    Item.pluck(:name, :id, :kind).each do |name, id, kind|
      @ids[name.downcase] = id
      @abstract_ids << id unless kind == 'concrete'
    end
  end

  def id_for(name)
    @ids[name.to_s.downcase]
  end

  def known?(name)
    !!id_for(name)
  end

  # Whether the name resolves to an abstract item (anything but concrete).
  def abstract?(name)
    @abstract_ids.include?(id_for(name))
  end

end

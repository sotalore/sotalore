# frozen_string_literal: true

# Resolves item names (as the game spells them) to Item ids, checking item
# names first and then ItemAlias names, case-insensitively. Loads everything
# up front so resolving a whole export is cheap.
class ItemLookup

  def initialize
    @ids = {}
    ItemAlias.pluck(:name, :item_id).each { |name, id| @ids[name.downcase] = id }
    @kinds = {}
    Item.pluck(:name, :id, :kind).each do |name, id, kind|
      @ids[name.downcase] = id
      @kinds[id] = kind
    end
  end

  def id_for(name)
    @ids[name.to_s.downcase]
  end

  def known?(name)
    !!id_for(name)
  end

  # The kind of item (see Item::ITEM_KINDS) the name resolves to, if any.
  def kind_for(name)
    @kinds[id_for(name)]
  end

  def group?(name)
    kind_for(name) == 'group'
  end

end

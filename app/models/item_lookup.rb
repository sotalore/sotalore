# frozen_string_literal: true

# Resolves items as game exports name them to Item ids: by the game's key
# (see ItemGameKey) when there is one and the site knows it, otherwise by
# name, checking item names and then ItemAlias names, case-insensitively.
# Takes a GameRecipe::Line (or anything with a name and key) or a plain name.
# Loads everything up front so resolving a whole export is cheap.
class ItemLookup

  def initialize
    @ids = {}
    ItemAlias.pluck(:name, :item_id).each { |name, id| @ids[name.downcase] = id }
    @kinds = {}
    Item.pluck(:name, :id, :kind).each do |name, id, kind|
      @ids[name.downcase] = id
      @kinds[id] = kind
    end
    @key_ids = ItemGameKey.pluck(:key, :item_id).to_h
  end

  def id_for(line_or_name)
    if line_or_name.respond_to?(:key)
      @key_ids[line_or_name.key] || @ids[line_or_name.name.to_s.downcase]
    else
      @ids[line_or_name.to_s.downcase]
    end
  end

  def id_for_key(key)
    @key_ids[key]
  end

  def known?(line_or_name)
    !!id_for(line_or_name)
  end

  # The kind of item (see Item::ITEM_KINDS) it resolves to, if any.
  def kind_for(line_or_name)
    @kinds[id_for(line_or_name)]
  end

  def group?(line_or_name)
    kind_for(line_or_name) == 'group'
  end

end

# frozen_string_literal: true

# For imports of game files that name items the site may not know (finds,
# the item catalog): an unknown item becomes a new concrete item with the
# game's key, or an existing item takes it (the key, or the game's name as an
# alias when there's no key). The including class has an +analysis+ whose
# +unknown_items+ have a +key+ and +name+, and a +reset_analysis!+.
module GameItemResolution
  extend ActiveSupport::Concern

  class Error < StandardError; end

  included do
    const_set(:Error, GameItemResolution::Error) unless const_defined?(:Error, false)
  end

  def create_item!(name:, key: nil)
    unknown!(name, key)
    Item.transaction do
      item = Item.create!(name: name, kind: :concrete)
      item.game_keys.create!(key: key, name: name) if key
      item
    end
  end

  def use_item!(item, name:, key: nil)
    unknown!(name, key)
    if key
      item.game_keys.create!(key: key, name: name)
    elsif !item.name.casecmp?(name)
      item.aliases.create!(name: name)
    end
    item
  end

  private

  def unknown!(name, key)
    analysis.unknown_items.find { key ? _1.key == key : _1.key.nil? && _1.name.casecmp?(name) } or
      raise Error, "#{name} isn't an unknown item in this import"
    reset_analysis!
  end
end

# frozen_string_literal: true

# Compares the item weights in a recipe export with the site's, through the
# items' recorded game keys (see ItemGameKey), and sets them. An item is:
#
#   missing   - the site has no weight for it
#   same      - the site agrees with the game
#   different - the site has another weight (often rounded: 0.1 for 0.05)
#   conflict  - it has several game keys, which the game weighs differently,
#               so the site can't take one weight for all of them
class GameWeights

  STATUSES = %w[ missing different conflict same ].freeze

  Row = Data.define(:item, :weights, :status) do
    def weight = weights.first
  end

  def initialize(import, user)
    @import = import
    @user = user
  end

  def rows
    @rows ||= begin
      by_key = @import.entries.map { _1.game_recipe.item_weights }.reduce({}, :merge)
      by_item = Hash.new { |h, k| h[k] = [] }
      ItemGameKey.where(key: by_key.keys).pluck(:key, :item_id).each do |key, item_id|
        by_item[item_id] << BigDecimal(by_key[key].to_s)
      end
      items = Item.where(id: by_item.keys).index_by(&:id)
      by_item.map { |item_id, weights| row_for(items[item_id], weights.uniq.sort) }
             .sort_by { |row| [ STATUSES.index(row.status), row.item.name.downcase ] }
    end
  end

  def counts
    STATUSES.index_with { |status| rows.count { _1.status == status } }
  end

  # Sets the game's weight on up to +limit+ items with the given status
  # (missing or different), recording a revision on each. Returns how many
  # were set.
  def set!(status, limit: nil)
    raise ArgumentError, "Can't set #{status} weights" unless %w[ missing different ].include?(status)
    chosen = rows.select { _1.status == status }
    chosen = chosen.first(limit) if limit
    Item.transaction do
      chosen.each do |row|
        row.item.update!(weight: row.weight)
        RevisionRecorder.call(row.item, @user)
      end
    end
    chosen.size
  end

  private

  def row_for(item, weights)
    status =
      if weights.size > 1 then 'conflict'
      elsif item.weight.nil? then 'missing'
      elsif item.weight == weights.first then 'same'
      else 'different'
      end
    Row.new(item, weights, status)
  end

end

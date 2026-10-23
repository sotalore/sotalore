class AddValueToItems < ActiveRecord::Migration[8.1]
  # An item's value is what a merchant pays for one, from the game's tooltip
  # (see GameCatalog::Entry#tooltip_value). Item catalog imports set it on
  # concrete items; this fills it from the tooltips already recorded on their
  # game keys, the most recently seen first.
  def up
    add_column :items, :value, :integer

    Item.reset_column_information
    ItemGameKey.where("key LIKE 'item:%' AND catalog ? 'details'").includes(:item)
               .order(catalog_seen_at: :desc).group_by(&:item).each do |item, keys|
      next unless item.concrete?
      value = keys.lazy.filter_map { GameCatalog::Entry.new(_1.key, _1.name, nil, nil, _1.catalog['details']).tooltip_value }.first
      item.update_column(:value, value) if value
    end
  end

  def down
    remove_column :items, :value
  end
end

class SetGearUseFromTypeLines < ActiveRecord::Migration[8.1]
  # Item catalog imports now make gear of unknown use armor or weapons when
  # its tooltip's type line says so ("Leather Light Armor (Head)", "Longsword
  # - Bladed"; see GearType). This does the same for items imported before,
  # from the tooltips already kept on their game keys. Each is recorded as a
  # revision by the first root user, when there is one. The patterns are
  # copied here so the migration doesn't change if GearType does.
  ARMOR  = /\A\w+ (Light|Heavy) Armor \((Head|Torso|Hands|Legs|Feet)\)\z/
  SHIELD = /\A(Light|Heavy) Shield\z/
  WEAPON = /\A.+ - (Bladed|Bludgeon|Polearm|Ranged)\z/

  def up
    author = User.where('roles @> ?', '{root}').order(:id).first
    keys = ItemGameKey.where("catalog -> 'details' -> 'types' IS NOT NULL").includes(:item)
    keys.group_by(&:item).each do |item, item_keys|
      next unless item.use_is_unknown?
      lines = item_keys.flat_map { Array(_1.catalog.dig('details', 'types')) }
      use = lines.lazy.filter_map { |line| use_for(line.to_s.strip) }.first or next
      item.update_columns(use: Item.uses.fetch(use), updated_at: Time.current)
      author && item.comments.create!(author: author, comment_type: 'revision',
                                      body: { changes: { use: [ 'unknown', use ] } }.to_json)
    end
  end

  # The uses were unknown, so there's nothing better to put back.
  def down
  end

  private

  def use_for(line)
    if ARMOR.match?(line) || SHIELD.match?(line) then 'armor'
    elsif WEAPON.match?(line) then 'weapon'
    end
  end
end

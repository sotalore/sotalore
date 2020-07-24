class AbstractRecipe

  attr_reader :craft_skill

  def initialize(craft_skill, key)
    @craft_skill = craft_skill
    parse_key(key)
  end

  def ingredients
    Item.where(id: @item_ids).map do |item|
      [ item, @quantities[item.id] ]
    end
  end

  private
  def parse_key(key)
    @item_ids = []
    @quantities = {}
    key.split(',').each do |info|
      item_id, quantity = info.split(/[:*]/)
      quantity ||= 1
      @item_ids << item_id
      @quantities[item_id.to_i] = quantity
    end
  end
end

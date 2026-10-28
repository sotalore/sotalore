class ItemsController < ApplicationController

  def index
    items = Item.all
    items = items.by_name.page(params[:page]).per(200)
    authorize Item
    render Views::Items::Index.new(items: items)
  end

  def by_use
    use = params[:use]
    items = Item.where(use: use)
    items = items.by_name.page(params[:page]).per(200)
    if use == 'artifact'
      items = items.includes(:salvages_to)
    end
    authorize Item
    render Views::Items::ByUse.new(items: items, use: use)
  end

  # Armor, shields and weapons by what their tooltips say they are (see
  # GearType), filtered by ?kind=, ?weight=, ?material=, ?slot=, ?damage=.
  def gear
    authorize Item
    filters = GearType::FACETS.filter_map { |facet, values| [ facet, params[facet] ] if values.include?(params[facet]) }.to_h
    gear = GearType.items.select { |_, type| type.matches?(filters) }
    render Views::Items::Gear.new(gear: gear, filters: filters)
  end

  def show
    item = find_item
    authorize item
    used_in = item.recipe_uses.includes(results: :item).page(params[:page])
    market_price = Current.user.market_prices.find_or_initialize_by(item: item) if Current.user.not_null? && item.concrete?
    collections = policy(Collection).update? ? Collection.by_name.to_a : []
    sources, roles = (item.concrete? ? [ ItemSources.new(item), ItemRoles.new(item) ] : [])
    materials = Materials.new if item.concrete? && Materials.involves?(item)
    if item.concrete? && (materials&.find(item) || ComponentBonuses.component?(item))
      bonuses = ComponentBonuses.new(materials || Materials.new)
    end
    render Views::Items::Show.new(item: item, used_in: used_in, market_price: market_price,
                                  collections: collections, gear_type: GearType.for_item(item),
                                  sources: sources, roles: roles, materials: materials, bonuses: bonuses)
  end

  def new
    item = Item.new
    authorize item
    render Views::Items::New.new(item: item)
  end

  def edit
    item = find_item
    authorize item
    render Views::Items::Edit.new(item: item)
  end

  def create
    item = Item.new(permitted_params)
    authorize item
    if item.save
      RevisionRecorder.call(item, Current.user)
      redirect_to item
    else
      render Views::Items::New.new(item: item), status: :unprocessable_content
    end
  end

  def update
    item = find_item
    authorize item
    if item.update(permitted_params)
      RevisionRecorder.call(item, Current.user)
      redirect_to item
    else
      render Views::Items::Edit.new(item: item), status: :unprocessable_content
    end
  end

  def destroy
    item = find_item
    authorize item
    if item.destroy
      flash.notice = "The item '#{item}' has been destroyed'"
      redirect_to action: :index
    else
      flash.alert = 'Unable to delete this Item'
      redirect_to item
    end
  end


  private

  def find_item
    Item.with_data.find(params[:id])
  end

  def required_param
    case
    when params.key?(:seed)
      :seed
    else
      :item
    end
  end

  def permitted_params
    params.require(required_param).permit(
      :name, :use, :crafting_input, :source, :kind, :merchant_price, :gathering_skill,
      :weight, :notes, :effects,
      :yield, :buff_slots_used, :basic
    )
  end
end

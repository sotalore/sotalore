class ItemsController < ApplicationController

  def index
    @items = Item.all
    @items = @items.by_name.page(params[:page]).per(200)
    authorize Item
  end

  def by_use
    use = params[:use]
    @items = Item.where(use: use)
    @items = @items.by_name.page(params[:page]).per(200)
    if use == 'artifact'
      @items = @items.includes(:salvages_to)
    end
    authorize Item
  end

  def show
    @item = find_item
    authorize @item
    @used_in = @item.recipe_uses.includes(results: :item).page(params[:page])
  end

  def new
    @item = Item.new
    authorize @item
  end

  def edit
    @item = find_item
    authorize @item
  end

  def create
    @item = Item.new(permitted_params)
    authorize @item
    if @item.save
      RevisionRecorder.call(@item, current_user)
      redirect_to @item
    else
      render action: :new
    end
  end

  def update
    @item = find_item
    authorize @item
    if @item.update(permitted_params)
      RevisionRecorder.call(@item, current_user)
      redirect_to @item
    else
      render action: :edit
    end
  end

  def destroy
    @item = find_item
    authorize @item
    if @item.destroy
      flash.notice = "The item '#{@item}' has been destroyed'"
      redirect_to action: :index
    else
      flash.alert = 'Unable to delete this Item'
      redirect_to @item
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
      :name, :use, :crafting_input, :source, :instance_id, :abstract, :price, :gathering_skill,
      :weight, :notes, :effects,
      :yield, :buff_slots_used
    )
  end
end

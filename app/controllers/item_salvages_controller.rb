class ItemSalvagesController < ApplicationController

  def create
    @item_salvage = ItemSalvage.new(permitted_params)
    authorize @item_salvage
    @item_salvage.save
    redirect_to @item_salvage.salvage_from
  end

  def destroy
    @item_salvage = ItemSalvage.find(params[:id])
    authorize @item_salvage
    @item_salvage.destroy
    redirect_to @item_salvage.salvage_from
  end

  private
  def permitted_params
    permitted = params.require(:item_salvage).permit(
      :salvage_from_id, :salvage_to_name, :salvage_to_id
    ).except(:salvage_to_name)
  end
end

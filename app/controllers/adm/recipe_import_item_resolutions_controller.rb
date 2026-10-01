# frozen_string_literal: true

# Resolve an unknown item name from a recipe export by creating an item,
# renaming an existing one, or aliasing an existing one.
class Adm::RecipeImportItemResolutionsController < AdmController
  RESOLUTIONS = %w[create create_group rename alias].freeze

  def create
    @import = RecipeImport.find(params[:recipe_import_id])
    authorize(@import, :resolve_items?)
    name = params.require(:name)
    resolution = RecipeImportItemResolution.new(@import, Current.user)

    message =
      case params[:resolution].presence_in(RESOLUTIONS)
      when 'create'
        item = resolution.create(name)
        "Created item #{item.name}."
      when 'create_group'
        item = resolution.create(name, group: true)
        @import.analyze!
        redirect_to item_path(item), notice: "Created group #{item.name}. Add its members below."
        return
      when 'rename', 'alias'
        item = find_item or raise RecipeImportItemResolution::Error, 'Choose an existing item.'
        old_name = item.name
        if params[:resolution] == 'rename'
          resolution.rename(item, name)
          "Renamed #{old_name} to #{item.name}."
        else
          resolution.alias(item, name)
          "#{name} is now an alias of #{item.name}."
        end
      else
        raise ActionController::BadRequest, 'unknown resolution'
      end

    @import.analyze!
    redirect_back_or_to items_adm_recipe_import_path(@import), notice: message
  rescue RecipeImportItemResolution::Error, ActiveRecord::RecordInvalid => e
    redirect_back_or_to items_adm_recipe_import_path(@import), alert: e.message
  end

  private

  def find_item
    if params[:item_id].present?
      Item.find_by(id: params[:item_id])
    elsif params[:item_name].present?
      Item.find_by_name(params[:item_name].strip).first
    end
  end
end

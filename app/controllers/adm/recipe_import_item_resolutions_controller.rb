# frozen_string_literal: true

# Resolve an unknown item (or group slot) from a recipe export by creating an
# item (of any kind), renaming, aliasing or using an existing one; or adopt
# the game's new name for an item whose key the site knows.
class Adm::RecipeImportItemResolutionsController < AdmController
  CREATE_KINDS = { 'create' => 'concrete', 'create_group' => 'group',
                   'create_archetype' => 'archetype', 'create_category' => 'category' }.freeze
  EXISTING = %w[ rename alias use ].freeze
  ADOPT = %w[ adopt_name adopt_alias ].freeze
  RESOLUTIONS = (CREATE_KINDS.keys + EXISTING + ADOPT).freeze

  def create
    @import = RecipeImport.find(params[:recipe_import_id])
    authorize(@import, :resolve_items?)
    resolution = RecipeImportItemResolution.new(@import, Current.user)
    group_slot = params[:group_slot].present?

    message =
      case params[:resolution].presence_in(RESOLUTIONS)
      when *CREATE_KINDS.keys
        item = resolution.create(params.require(:name), kind: CREATE_KINDS[params[:resolution]],
                                                        group_slot: group_slot)
        item.concrete? ? "Created item #{item.name}." : "Created #{item.name} as #{item.kind_label}."

      when *EXISTING
        name = params.require(:name)
        item = find_item or raise RecipeImportItemResolution::Error, 'Choose an existing item.'
        old_name = item.name
        case params[:resolution]
        when 'rename'
          resolution.rename(item, name, group_slot: group_slot)
          "Renamed #{old_name} to #{item.name}."
        when 'alias'
          resolution.alias(item, name, group_slot: group_slot)
          "#{name} is now an alias of #{item.name}."
        else
          resolution.use(item, name, group_slot: group_slot)
          "#{item.name} now has the game's keys for #{name}."
        end

      when *ADOPT
        key = params.require(:key)
        old_name = ItemGameKey.find_by(key: key)&.item&.name
        item = resolution.adopt_game_name(key, as_alias: params[:resolution] == 'adopt_alias')
        if params[:resolution] == 'adopt_alias'
          "#{item.aliases.order(:created_at).last.name} is now an alias of #{item.name}."
        else
          "Renamed #{old_name} to #{item.name}."
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

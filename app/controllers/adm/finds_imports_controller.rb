# frozen_string_literal: true

# Upload, review and apply finds files from the game plugin (see FindsImport).
class Adm::FindsImportsController < AdmController
  include ResolvesGameItems

  def index
    authorize(FindsImport)
    page_title 'Finds Imports'
    render Views::Adm::FindsImports::Index.new(imports: FindsImport.newest_first.includes(:uploaded_by).page(params[:page]))
  end

  def create
    authorize(FindsImport)
    file = params[:file].presence
    unless file
      redirect_to adm_finds_imports_path, alert: 'Choose a finds file (sotalore-scene-finds.json).'
      return
    end
    import = FindsImport.create_from_json!(file.read, filename: file.original_filename, user: Current.user)
    redirect_to adm_finds_import_path(import), notice: "Imported #{import.finds.scenes.size} scenes."
  rescue JSON::ParserError, ArgumentError => e
    redirect_to adm_finds_imports_path, alert: "Couldn't import that: #{e.message.truncate(200)}"
  end

  def show
    @import = find_import
    authorize(@import)
    page_title @import.to_s
    render Views::Adm::FindsImports::Show.new(import: @import, analysis: @import.analysis,
                                              scenes: Scene.by_name.where(game_name: nil), open: open_section)
  end

  def destroy
    @import = find_import
    authorize(@import)
    @import.destroy
    redirect_to adm_finds_imports_path, notice: "Deleted #{@import}."
  end

  def apply
    @import = find_import
    authorize(@import)
    counts = @import.apply!
    summary = { items: 'item', creatures: 'creature', nodes: 'node', yields: 'yield' }
              .map { |key, noun| "#{counts[key]} #{noun.pluralize(counts[key])}" }.join(', ')
    redirect_to adm_finds_import_path(@import), notice: "Applied. New: #{summary}."
  end

  # Creates or uses an item for an unknown one (+resolution+ create or use),
  # creates many (+resolution+ create_many), or links an unmatched scene
  # (+resolution+ scene).
  def resolve
    @import = find_import
    authorize(@import)
    notice =
      case params[:resolution]
      when 'create_many'
        create_selected_items(@import)
      when 'create'
        item = @import.create_item!(name: params.require(:name), key: params[:key].presence)
        "Created #{item.name}."
      when 'use'
        item = find_item or raise FindsImport::Error, 'Choose an existing item.'
        @import.use_item!(item, name: params.require(:name), key: params[:key].presence)
        "#{item.name} is now #{params[:name]} in the game."
      when 'scene'
        scene = Scene.find_by(id: params[:scene_id]) or raise FindsImport::Error, 'Choose a scene.'
        @import.link_scene!(params.require(:name), scene)
        "#{scene.name} is now #{params[:name]} in the game."
      else
        raise ActionController::BadRequest, 'unknown resolution'
      end
    redirect_to review_path, notice: notice
  rescue FindsImport::Error, ActiveRecord::RecordInvalid => e
    redirect_to review_path, alert: e.message
  end

  private

  # Back to the review, with the section acted on still open.
  def review_path
    adm_finds_import_path(@import, open: open_section)
  end

  def find_import
    FindsImport.find(params[:id])
  end

  def find_item
    if params[:item_id].present?
      Item.find_by(id: params[:item_id])
    elsif params[:item_name].present?
      Item.find_by_name(params[:item_name].strip).first
    end
  end
end

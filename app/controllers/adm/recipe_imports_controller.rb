# frozen_string_literal: true

# Upload and review recipe exports from the game's recipe export plugin.
class Adm::RecipeImportsController < AdmController
  # Applying runs RecipeForm per recipe, so cap each request to stay well
  # inside the host's request timeout. Linking unchanged recipes is cheap.
  BULK_LIMITS = { 'unchanged' => 500, 'outdated' => 100, 'addition' => 100 }.freeze

  def index
    authorize(RecipeImport)
    @imports = RecipeImport.newest_first.includes(:uploaded_by).page(params[:page])
    page_title 'Recipe Imports'
    render Views::Adm::RecipeImports::Index.new(imports: @imports)
  end

  # Takes either an uploaded export file or JSON pasted from the game. A
  # single pasted recipe goes straight to its entry for review.
  def create
    authorize(RecipeImport)
    file = params[:file].presence
    json = file ? file.read : params[:json].to_s.strip
    if json.blank?
      redirect_to adm_recipe_imports_path, alert: 'Choose an export file, or paste recipe JSON.'
      return
    end

    import = RecipeImport.create_from_json!(json, filename: file&.original_filename,
                                            user: Current.user)
    if import.entries_count == 1
      entry = import.entries.first
      redirect_to adm_recipe_import_entry_path(import, entry),
                  notice: "Imported #{entry.name}."
    else
      redirect_to adm_recipe_import_path(import),
                  notice: "Imported #{import.entries_count} recipes."
    end
  rescue JSON::ParserError, ArgumentError => e
    redirect_to adm_recipe_imports_path, alert: "Couldn't import that: #{e.message.truncate(200)}"
  end

  def show
    @import = find_import
    authorize(@import)
    @status = params[:status].presence_in(RecipeImportEntry.statuses.keys)
    @entries = @import.entries.by_name.includes(:recipe)
    @entries = @entries.where(status: @status) if @status
    @entries = @entries.using_item(params[:item]) if params[:item].present?
    if params[:q].present?
      @entries = @entries.where('recipe_import_entries.name ILIKE ?',
                                "%#{RecipeImportEntry.sanitize_sql_like(params[:q])}%")
    end
    @entries = @entries.page(params[:page]).per(50)
    page_title @import.to_s
    render Views::Adm::RecipeImports::Show.new(import: @import, entries: @entries, status: @status)
  end

  def destroy
    @import = find_import
    authorize(@import)
    @import.destroy
    redirect_to adm_recipe_imports_path, notice: "Deleted #{@import}."
  end

  def analyze
    @import = find_import
    authorize(@import)
    @import.analyze!
    redirect_back_or_to adm_recipe_import_path(@import), notice: 'Re-analyzed.'
  end

  def apply_all
    @import = find_import
    authorize(@import, :apply?)
    status = params[:status].presence_in(BULK_LIMITS.keys) or
      raise ActionController::BadRequest, 'unknown status'

    lookup = ItemLookup.new
    applier = RecipeImportApplier.new(Current.user, lookup: lookup)
    entries = @import.entries.where(status: status).includes(:recipe).by_name
                     .limit(BULK_LIMITS[status])
    applied = entries.count { |entry| applier.apply(entry) }
    attempted = entries.size
    @import.analyze!

    remaining = @import.entries.where(status: status).count
    message = "Applied #{applied} of #{attempted} #{status} recipes."
    message << " #{attempted - applied} became blocked." if applied < attempted
    message << " #{remaining} remaining; apply again to continue." if remaining.positive?
    redirect_to adm_recipe_import_path(@import, status: status), notice: message
  end

  def items
    @import = find_import
    authorize(@import, :resolve_items?)
    names = @import.unresolved_item_names
    @names = Kaminari.paginate_array(names).page(params[:page]).per(25)
    @resolution = RecipeImportItemResolution.new(@import, Current.user)
    page_title "#{@import}: Unknown Items"
    render Views::Adm::RecipeImports::Items.new(import: @import, names: @names,
                                                resolution: @resolution)
  end

  def stale
    @import = find_import
    authorize(@import, :stale?)
    @retired = params[:retired].present?
    scope = @retired ? Recipe.retired : @import.stale_recipes
    @recipes = scope.by_name.page(params[:page]).per(50)
    page_title "#{@import}: #{@retired ? 'Retired' : 'Stale'} Recipes"
    render Views::Adm::RecipeImports::Stale.new(import: @import, recipes: @recipes,
                                                retired: @retired)
  end

  def retire_stale
    @import = find_import
    authorize(@import, :apply?)
    unless @import.full_export?
      redirect_to stale_adm_recipe_import_path(@import),
                  alert: 'Only a full export can tell which recipes are gone.'
      return
    end
    count = @import.stale_recipes.update_all(retired_at: Time.current)
    redirect_to stale_adm_recipe_import_path(@import), notice: "Retired #{count} recipes."
  end

  private

  def find_import
    RecipeImport.find(params[:id])
  end
end

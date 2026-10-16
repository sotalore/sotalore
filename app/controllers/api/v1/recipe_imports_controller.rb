# frozen_string_literal: true

# Recipe exports uploaded from the game, how their recipes matched the
# site's, and which site recipes the latest full one doesn't account for.
class Api::V1::RecipeImportsController < Api::BaseController
  before_action -> { require_scope!('read') }

  def index
    authorize(RecipeImport)
    render json: paged(:recipe_imports, RecipeImport.newest_first) { import_json(_1) }
  end

  def show
    import = find_import
    render json: import_json(import).merge(unknown_items: import.unresolved_item_names.size)
  end

  # ?status= (addition, unchanged, outdated, blocked, applied, skipped), ?q=,
  # ?page=, ?per=
  def entries
    import = find_import
    entries = import.entries.by_name.includes(:recipe)
    entries = entries.where(status: params[:status]) if params[:status].presence_in(RecipeImportEntry.statuses.keys)
    if params[:q].present?
      entries = entries.where('recipe_import_entries.name ILIKE ?',
                              "%#{RecipeImportEntry.sanitize_sql_like(params[:q])}%")
    end
    render json: paged(:entries, entries) { entry_json(_1) }
  end

  # Active site recipes this full export doesn't account for: gone from the
  # game, renamed beyond matching, or never real. Templates are left out
  # (they're curated on the site).
  def stale
    import = find_import
    unless import.full_export?
      render json: { error: 'Only a full export can tell which recipes are gone' }, status: :unprocessable_content
      return
    end
    recipes = import.stale_recipes.by_name.preload(ingredients: :item, results: :item)
    render json: paged(:recipes, recipes) { recipe_summary(_1) }
  end

  private

  def find_import
    import = params[:id] == 'latest' ? RecipeImport.latest_full : RecipeImport.find(params[:id])
    raise ActiveRecord::RecordNotFound unless import
    authorize(import, :show?)
    import
  end

  def import_json(import)
    { id: import.id, filename: import.filename, full_export: import.full_export?,
      api_version: import.api_version, created_at: import.created_at.iso8601,
      analyzed_at: import.analyzed_at&.iso8601, entries: import.entries_count,
      statuses: import.status_counts }
  end

  def entry_json(entry)
    { id: entry.id, name: entry.name, game_id: entry.game_id, status: entry.status,
      match_method: entry.match_method, recipe: entry.recipe && recipe_ref(entry.recipe),
      problems: entry.problems, diff: entry.diff }
  end
end

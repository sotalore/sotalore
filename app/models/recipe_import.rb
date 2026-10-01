# frozen_string_literal: true

# One uploaded recipe export from the game plugin. Each recipe in the export
# becomes a RecipeImportEntry, which is matched against site recipes and
# analyzed (see RecipeImportAnalyzer) for an admin to review and apply.
class RecipeImport < ApplicationRecord
  belongs_to :uploaded_by, class_name: 'User', optional: true
  has_many :entries, class_name: 'RecipeImportEntry', inverse_of: :recipe_import,
           dependent: :delete_all

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :full, -> { where(full_export: true) }

  # Builds (and saves) an import from export JSON. Raises ArgumentError or
  # JSON::ParserError on input that isn't a recipe export.
  def self.create_from_json!(json, filename: nil, user: nil)
    api_version, full, game_recipes = GameRecipe.parse_export(json)
    transaction do
      import = create!(filename: filename, api_version: api_version,
                       full_export: full, uploaded_by: user)
      now = Time.current
      rows = game_recipes.uniq(&:game_id).map do |gr|
        {
          recipe_import_id: import.id,
          game_id: gr.game_id,
          name: gr.name,
          payload: gr.payload,
          created_at: now,
          updated_at: now,
        }
      end
      RecipeImportEntry.insert_all!(rows) if rows.any?
      import.update_columns(entries_count: rows.size)
      import.analyze!
      import
    end
  end

  def self.latest_full
    full.newest_first.first
  end

  def analyze!
    RecipeImportAnalyzer.new(self).call
  ensure
    reset_analysis_caches
  end

  def reload(*)
    reset_analysis_caches
    super
  end

  def status_counts
    @status_counts ||= begin
      counts = entries.group(:status).count
      RecipeImportEntry.statuses.keys.index_with { |s| counts[s] || 0 }
    end
  end

  # Site recipes (not already retired) that this export doesn't account for.
  # Template recipes are site-only, so never stale. Only meaningful for a full
  # export.
  def stale_recipes
    Recipe.active.concrete.where.not(id: entries.where.not(recipe_id: nil).select(:recipe_id))
  end

  # Pending entries not matched to any site recipe whose names resemble
  # +name+; likely candidates when a stale recipe was renamed in the game.
  def unmatched_entries_similar_to(name, limit: 3)
    similarity = ActiveRecord::Base.sanitize_sql_array(
      [ 'similarity(recipe_import_entries.name, ?)', name ])
    entries.pending.where(recipe_id: nil)
           .where("#{similarity} > 0.35")
           .order(Arel.sql("#{similarity} DESC"))
           .limit(limit)
  end

  def unresolved_item_names
    @unresolved_item_names ||= RecipeImportItemResolution.unresolved_names(self)
  end

  def to_s
    "Import ##{id}"
  end

  private

  def reset_analysis_caches
    @unresolved_item_names = nil
    @status_counts = nil
    entries.reset
  end
end

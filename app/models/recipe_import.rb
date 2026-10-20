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

  # A full export whose stale recipes are more than this share of the site's
  # (and more than a handful) is almost certainly not full, and retiring them
  # all is refused.
  STALE_LIMIT = 0.3
  STALE_MINIMUM = 20

  # Builds (and saves) an import from an uploaded export file. Raises
  # ArgumentError or JSON::ParserError on input that isn't a recipe export.
  #
  # Whether it's a full export ("Export all": every recipe a character knows,
  # so recipes it lacks may be gone from the game) comes from the file: an
  # "all" scope from plugin 0.5.2 or later is full; "new" and "one" never
  # are, nor is anything from before 0.5.2 (those lack ~100 recipes), nor a
  # file that doesn't say. A single recipe is never full. An import's page
  # can still mark it full or partial (see #can_be_full?).
  def self.create_from_json!(json, filename: nil, user: nil)
    export = GameRecipe.parse_export(json)
    game_recipes = export.recipes
    raise ArgumentError, 'No recipes found' if game_recipes.empty?
    if game_recipes.any? { _1.game_id.nil? }
      raise ArgumentError, 'Every recipe needs an "id"'
    end
    transaction do
      import = create!(filename: filename, api_version: export.api_version, export_scope: export.scope,
                       plugin_version: export.plugin_version,
                       full_export: full_from_file?(export) && game_recipes.size > 1,
                       uploaded_by: user,
                       groups_payload: export.groups.map(&:payload))
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

  def self.full_from_file?(export)
    export.scope == 'all' && export.plugin_version.present? && !too_old_to_be_full?(export.plugin_version)
  end
  private_class_method :full_from_file?

  # A plugin version known to be before complete full exports.
  def self.too_old_to_be_full?(version)
    version.present? && !PluginFile.at_least?(version, PluginFile::COMPLETE_FULL_EXPORTS)
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
  # Template recipes are curated on the site (the game has no recipes making
  # groups), so never stale. Only meaningful for a full export.
  def stale_recipes
    Recipe.active
          .where.not(id: entries.where.not(recipe_id: nil).select(:recipe_id))
          .where.not(id: Recipe.templates)
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

  # The export's top-level groups (see GameGroup); none for older exports
  # (and recipes pasted, back when that was possible).
  def game_groups
    @game_groups ||= groups_payload.map { GameGroup.new(_1) }
  end

  # Whether it can be marked a full export: not when the file says it holds
  # only new recipes or one, and never for a single recipe.
  def can_be_full?
    entries_count > 1 && export_scope.in?([ nil, 'all' ]) && !self.class.too_old_to_be_full?(plugin_version)
  end

  # Whether this many stale recipes means it isn't really a full export.
  def implausibly_stale?
    return false unless full_export?
    stale = stale_recipes.count
    stale > STALE_MINIMUM && stale > Recipe.active.where.not(id: Recipe.templates).count * STALE_LIMIT
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
    @game_groups = nil
    entries.reset
  end
end

# frozen_string_literal: true

# A single recipe from a RecipeImport, along with how it matched to a site
# recipe and what would change if it were applied.
#
# Statuses:
#   addition  - no matching site recipe; applying creates one
#   unchanged - matches a site recipe exactly; applying just links it
#   outdated  - matches a site recipe that differs (see #diff)
#   blocked   - can't be applied yet (see #problems), e.g. unknown items
#   applied   - has been applied to the site
#   skipped   - an admin chose to ignore it
class RecipeImportEntry < ApplicationRecord
  belongs_to :recipe_import, inverse_of: :entries
  belongs_to :recipe, optional: true

  enum :status, { addition: 0, unchanged: 1, outdated: 2, blocked: 3, applied: 4, skipped: 5 }

  FINAL_STATUSES = %w[applied skipped].freeze
  APPLICABLE_STATUSES = %w[addition unchanged outdated].freeze

  scope :pending, -> { where.not(status: FINAL_STATUSES) }
  # Entries whose ingredients or results include an item, by its game name.
  scope :using_item, ->(name) {
    line = [ { name: name } ].to_json
    where("recipe_import_entries.payload->'ingredients' @> :line::jsonb OR " \
          "recipe_import_entries.payload->'results' @> :line::jsonb", line: line)
  }
  scope :by_name, -> { order(Arel.sql('lower(recipe_import_entries.name)'), :id) }

  def game_recipe
    @game_recipe ||= GameRecipe.new(payload)
  end

  def final?
    FINAL_STATUSES.include?(status)
  end

  def applicable?
    APPLICABLE_STATUSES.include?(status)
  end

  def to_s
    name
  end
end

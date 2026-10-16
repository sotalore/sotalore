# frozen_string_literal: true

# The Item Review lists (see ItemReview): items whose kind may be wrong,
# with the evidence and suggestions.
class Api::V1::ItemReviewsController < Api::BaseController
  before_action -> { require_scope!('read') }

  # ?filter= (abstract, group, archetype, category, suspect, unkeyed,
  # recent), ?issues=true, ?q=, ?page=, ?per=
  def index
    authorize(:item_review)
    review = ItemReview.new(filter: params[:filter], issues_only: params[:issues] == 'true', query: params[:q])
    render json: paged_array(:items, review.rows) { row_json(_1) }.merge(filter: review.filter)
  end

  private

  def row_json(row)
    item_ref(row.item).merge(
      members: row.members, groups: row.groups,
      ingredient_of: row.ingredient_uses, ingredient_of_game_recipes: row.game_ingredient_uses,
      made_by: row.result_uses, made_by_game_recipes: row.game_result_uses,
      modified: row.modified?, made_from_groups: row.made_from_groups, game_keys: row.game_keys,
      issues: row.issues.map { { message: _1.message, suggest: _1.suggest } }
    )
  end
end

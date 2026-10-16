# frozen_string_literal: true

# Recipes, with what helps decide whether one belongs on the site: whether
# the game still has it (game_id, the latest full import), who relies on it
# (users who saved it, comments) and duplicates by name.
class Api::V1::RecipesController < Api::BaseController
  before_action -> { require_scope!('read') }

  STATUSES = %w[ active retired all ].freeze

  # ?q= (name contains), ?craft_skill=, ?status=active|retired|all
  # (default active), ?synced=true|false (has a game_id), ?page=, ?per=
  def index
    authorize(Recipe)
    recipes = Recipe.by_name.preload(ingredients: :item, results: :item)
    recipes =
      case params[:status].presence_in(STATUSES) || 'active'
      when 'active' then recipes.active
      when 'retired' then recipes.retired
      else recipes
      end
    if params[:q].present?
      recipes = recipes.where('recipes.name ILIKE ?', "%#{Recipe.sanitize_sql_like(params[:q])}%")
    end
    if (skill = CraftSkill.find(params[:craft_skill]))
      recipes = recipes.where(craft_skill: skill)
    end
    case params[:synced]
    when 'true' then recipes = recipes.where.not(game_id: nil)
    when 'false' then recipes = recipes.where(game_id: nil)
    end
    render json: paged(:recipes, recipes) { recipe_summary(_1) }
  end

  def show
    recipe = Recipe.find(params[:id])
    authorize(recipe)
    render json: recipe_detail(recipe)
  end
end

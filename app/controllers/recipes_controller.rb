class RecipesController < ApplicationController

  def index
    @recipes = recipe_scope.all
    authorize @recipes
    @recipes = @recipes.active unless params[:retired].present?
    if params[:rq].present?
      @recipes = @recipes.search_by_name(params[:rq])
    end
    if skill = CraftSkill.find(params[:skill])
      @recipes = @recipes.where(craft_skill: skill)
    end
    if params[:rsmin].present?
      @recipes = @recipes.where("proficiency >= ?", params[:rsmin].to_i)
    end
    if params[:rsmax].present?
      @recipes = @recipes.where("proficiency <= ?", params[:rsmax].to_i)
    end
    @recipes = @recipes.by_name.includes(results: :item).page(params[:page])
    render Views::Recipes::Index.new(recipes: @recipes)
  end

  def for_item
    @item = Item.find(params[:item_id])
    @recipes = @item.recipes
    authorize @recipes
    render Views::Recipes::ForItem.new(recipes: @recipes)
  end

  def show
    @recipe = find_recipe
    authorize @recipe
    render Views::Recipes::Show.new(recipe: @recipe)
  end

  def show_partial
    @recipe = find_recipe
    authorize @recipe
    render Components::Recipes::Card.new(recipe: @recipe), layout: false
  end

  # Preview of the items and recipes a template implies for the members of
  # its ingredient group.
  def variants
    @recipe = find_recipe
    authorize @recipe
    return redirect_to(@recipe, alert: 'Only template recipes have variants.') unless @recipe.template?
    render Views::Recipes::Variants.new(recipe: @recipe, expansion: TemplateExpansion.new(@recipe))
  end

  def create_variants
    @recipe = find_recipe
    authorize @recipe
    expansion = TemplateExpansion.new(@recipe)
    return redirect_to(@recipe, alert: expansion.error) unless expansion.valid?

    members = expansion.ingredient_group.members.where(id: params[:member_ids])
    created = expansion.apply!(Current.user, members: members, settings: variant_settings(members))
    redirect_to @recipe, notice: "Generated #{created.size} #{'recipe'.pluralize(created.size)} " \
                                 "and filled in the group's items."
  end

  def new
    @recipe = RecipeForm.new(Recipe.new, Current.user)
    authorize @recipe
    if item = Item.find_by(id: params[:item_id])
      @recipe.name = item.name
      @recipe.results.build(item: item, count: 1)
    end
    render Views::Recipes::New.new(recipe: @recipe)
  end

  def edit
    @recipe = find_recipe
    authorize @recipe
    @recipe = RecipeForm.new(@recipe, Current.user)
    render Views::Recipes::Edit.new(recipe: @recipe)
  end

  def create
    @recipe = RecipeForm.new(Recipe.new, Current.user)
    authorize @recipe
    if @recipe.save(permitted_params)
      redirect_to @recipe
    else
      render Views::Recipes::New.new(recipe: @recipe), status: :unprocessable_content
    end
  end

  def update
    @recipe = RecipeForm.new(find_recipe, Current.user)
    authorize @recipe
    if @recipe.save(permitted_params)
      redirect_to @recipe
    else
      render Views::Recipes::New.new(recipe: @recipe), status: :unprocessable_content
    end
  end

  def destroy
    @recipe = find_recipe
    authorize @recipe
    @recipe.destroy
    redirect_to action: :index
  end

  def lookup
    craft_skill = CraftSkill.find(params[:craft_skill])
    @recipe = AbstractRecipe.new(craft_skill, params[:key])
    authorize Recipe, :show
    render Views::Recipes::Show.new(recipe: @recipe)
  end

  private

  # The proficiency and teachable entered for each member on the variants page.
  def variant_settings(members)
    members.to_h do |member|
      entered = params.dig(:variants, member.id.to_s)
      teachable = entered&.[](:teachable).presence
      [ member.id, { proficiency: entered&.[](:proficiency).presence&.to_i,
                     teachable: Recipe.teachables.key?(teachable) ? teachable : nil } ]
    end
  end

  def permitted_params
    params.require(:recipe).permit(
      :item_name, :item_id, :item_count,
      :craft_skill, :proficiency, :teachable,
      :name,
      ingredients_attributes: [ :name, :item_id, :count, :id ],
      results_attributes: [ :name, :item_id, :count, :id ],
    )
  end

  def find_recipe
    recipe_scope.includes(ingredients: { item: :recipes }).find(params[:id])
  end

  def recipe_scope
    Recipe
  end

  def build_search
    RecipeSearch.new(params.slice(:q, :skill))
  end
end

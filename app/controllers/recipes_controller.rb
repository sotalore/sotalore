class RecipesController < ApplicationController

  def index
    @recipes = recipe_scope.all
    authorize @recipes
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
  end

  def show
    @recipe = find_recipe
    authorize @recipe
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  def new
    @recipe = RecipeForm.new(Recipe.new, current_user)
    authorize @recipe
    if item = Item.find_by(id: params[:item_id])
      @recipe.name = item.name
      @recipe.results.build(item: item, count: 1)
    end
  end

  def edit
    @recipe = find_recipe
    authorize @recipe
    @recipe = RecipeForm.new(@recipe, current_user)
  end

  def create
    @recipe = RecipeForm.new(Recipe.new, current_user)
    authorize @recipe
    if @recipe.save(permitted_params)
      redirect_to @recipe
    else
      render :new
    end
  end

  def update
    @recipe = RecipeForm.new(find_recipe, current_user)
    authorize @recipe
    if @recipe.save(permitted_params)
      redirect_to @recipe
    else
      render :new
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
    render :show
  end

  private
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

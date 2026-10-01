# frozen_string_literal: true

class Adm::RecipeImportEntriesController < AdmController
  before_action :find_entry

  def show
    authorize(@import)
    page_title @entry.name
    render Views::Adm::RecipeImportEntries::Show.new(import: @import, entry: @entry)
  end

  def apply
    authorize(@import, :apply?)
    if RecipeImportApplier.new(Current.user).apply(@entry)
      redirect_back_or_to entry_path, notice: "Applied #{@entry.name}."
    else
      redirect_to entry_path, alert: "Couldn't apply #{@entry.name}: #{@entry.problems.to_sentence}"
    end
  end

  def skip
    authorize(@import, :apply?)
    @entry.update!(status: 'skipped') unless @entry.applied?
    redirect_back_or_to entry_path, notice: "Skipped #{@entry.name}."
  end

  def unskip
    authorize(@import, :apply?)
    if @entry.skipped?
      @entry.update!(status: 'addition')
      @import.analyze!
    end
    redirect_back_or_to entry_path
  end

  # Manually match the entry to a site recipe (by id), or clear the match
  # with a blank recipe_id.
  def link
    authorize(@import, :apply?)
    if @entry.final?
      redirect_to entry_path, alert: 'Already applied or skipped.'
      return
    end

    recipe = Recipe.find_by(id: params[:recipe_id]) if params[:recipe_id].present?
    if params[:recipe_id].present? && recipe.nil?
      redirect_to entry_path, alert: "No recipe ##{params[:recipe_id]}."
      return
    end
    if recipe&.game_id && recipe.game_id != @entry.game_id
      redirect_to entry_path, alert: "#{recipe.name} is already synced to another game recipe."
      return
    end

    RecipeImportEntry.transaction do
      # Free the recipe from any other entry that had matched it.
      @import.entries.pending.where(recipe: recipe).where.not(id: @entry.id)
             .update_all(recipe_id: nil, manual_match: false) if recipe
      @entry.update!(recipe: recipe, manual_match: recipe.present?)
      @import.analyze!
    end
    redirect_back_or_to entry_path,
                        notice: recipe ? "Linked #{@entry.name} to #{recipe.name}." : 'Cleared the match.'
  end

  private

  def find_entry
    @import = RecipeImport.find(params[:recipe_import_id])
    @entry = @import.entries.find(params[:id])
  end

  def entry_path
    adm_recipe_import_entry_path(@import, @entry)
  end
end

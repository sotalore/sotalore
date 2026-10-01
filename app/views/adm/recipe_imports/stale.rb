# frozen_string_literal: true

class Views::Adm::RecipeImports::Stale < Views::Adm::RecipeImports::Base

  def initialize(import:, recipes:, retired:)
    @import = import
    @recipes = recipes
    @retired = retired
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      import_header(@import, :stale)
      div(class: 'p-4') do
        div(class: 'flex flex-row gap-2 mb-4') do
          a(href: stale_adm_recipe_import_path(@import),
            class: "Button Button--sm Button--#{@retired ? 'default' : 'primary'}") { 'Not in this export' }
          a(href: stale_adm_recipe_import_path(@import, retired: 1),
            class: "Button Button--sm Button--#{@retired ? 'primary' : 'default'}") { 'Retired' }
        end
        @retired ? retired_intro : stale_intro
        paginate @recipes
        recipes_table
        paginate @recipes
      end
    end
  end

  private

  def stale_intro
    unless @import.full_export?
      notice_warning('This is a partial export, so most site recipes won\'t be in it. ' \
                     'Use a full export to find recipes that are gone from the game.')
      return
    end

    unmatched = @import.entries.pending.where(recipe_id: nil).count
    p(class: 'mb-2 max-w-prose') do
      plain "Site recipes that no entry in this export matched (#{@recipes.total_count}). "
      plain 'They may be gone from the game, or renamed beyond what matching could catch. '
      if unmatched.positive?
        plain "#{unmatched} game recipes in this export aren't matched to a site recipe yet; "
        plain 'link likely renames first. Resolving unknown items also lets more recipes match.'
      end
    end
    if @recipes.total_count.positive?
      div(class: 'mb-4') do
        post_button("Retire all #{@recipes.total_count}", retire_stale_adm_recipe_import_path(@import),
                    style: 'danger',
                    confirm: "Retire #{@recipes.total_count} recipes? They'll be hidden from listings but not deleted.")
      end
    end
  end

  def retired_intro
    p(class: 'mb-4 max-w-prose') do
      plain 'Retired recipes are hidden from the recipe listing and flagged on their pages. '
      plain 'Applying an import entry that matches one un-retires it.'
    end
  end

  def recipes_table
    table(class: 'table-auto w-full') do
      thead do
        tr(class: 'border-b-2 border-grey-400 text-left') do
          th { 'Site recipe' }
          th { 'Skill' }
          th { 'Last verified' }
          th { 'Updated' }
          th { @retired ? 'Retired' : 'Possible game match' }
          th { whitespace }
        end
      end
      tbody { @recipes.each { |recipe| recipe_row(recipe) } }
    end
  end

  def recipe_row(recipe)
    tr(class: 'align-top border-b border-grey-200 dark:border-grey-700') do
      td do
        a(href: recipe_path(recipe), class: 'Link Link--primary') { recipe.name }
        span(class: 'text-xs text-grey-500') { " ##{recipe.id}" }
      end
      td(class: 'text-sm') { recipe.craft_skill&.name }
      td(class: 'text-sm') { recipe.last_verified_at ? time_ago_tag(recipe.last_verified_at) : 'never' }
      td(class: 'text-sm') { time_ago_tag recipe.updated_at }
      td(class: 'text-sm') do
        if @retired
          time_ago_tag recipe.retired_at
        else
          possible_matches(recipe)
        end
      end
      td(class: 'text-right whitespace-nowrap') do
        if @retired
          post_button('Unretire', unretire_adm_recipe_path(recipe))
        else
          post_button('Retire', retire_adm_recipe_path(recipe), style: 'danger')
        end
      end
    end
  end

  def possible_matches(recipe)
    @import.unmatched_entries_similar_to(recipe.name).each do |entry|
      div(class: 'flex flex-row items-center gap-2 mb-1') do
        a(href: adm_recipe_import_entry_path(@import, entry), class: 'Link') { entry.name }
        post_button('Link', link_adm_recipe_import_entry_path(@import, entry),
                    params: { recipe_id: recipe.id })
      end
    end
  end
end

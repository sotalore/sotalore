# frozen_string_literal: true

# The old recipes archetype recipes cover (see ArchetypeCleanup), one form
# per archetype recipe, each recipe ticked to be deleted with what it makes.
class Views::Adm::ArchetypeCleanups::Show < Views::Base

  def initialize(cleanup:)
    @cleanup = cleanup
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      div(class: 'p-4 pb-0') do
        h1(class: 'text-2xl font-bold') { 'Archetype Cleanup' }
        intro
      end
      div(class: 'p-4') do
        groups = @cleanup.by_archetype_recipe
        if groups.empty?
          notice_success('No old recipes left that an archetype recipe covers.')
        else
          groups.each { |archetype_recipe, candidates| group_form(archetype_recipe, candidates) }
        end
      end
    end
  end

  private

  def intro
    div(class: 'my-2 max-w-prose text-sm') do
      p(class: 'mb-1') do
        plain 'Old recipes with no game id, named after an archetype the game makes with one recipe '
        plain '("Bronze Shortsword with Iron Hilt" is one of the choices of the game\'s Shortsword). '
        plain 'The game has no such recipe or item, and the archetype recipe shows every choice.'
      end
      p do
        plain 'A recipe '
        strong { 'fits' }
        plain ' when every ingredient is one the archetype recipe takes, or one of its choices. '
        plain 'The rest are named like it but take things it doesn\'t, often materials the game no '
        plain 'longer has. Deleting a recipe deletes what it makes too, unless something else needs it. '
        plain "#{@cleanup.candidates.size} recipes, #{@cleanup.candidates.count(&:fits?)} of them fit."
      end
    end
  end

  def group_form(archetype_recipe, candidates)
    section(class: 'mb-6') do
      h2(class: 'text-lg font-bold') do
        a(href: recipe_path(archetype_recipe), class: 'Link Link--primary') { archetype_recipe.name }
        span(class: 'text-sm font-normal text-grey-500') do
          plain " #{archetype_recipe.craft_skill.key} · covers #{candidates.size}"
        end
      end
      form(action: adm_archetype_cleanup_path, method: 'post',
           data: { turbo_confirm: "Delete the ticked recipes covered by #{archetype_recipe.name}?" }) do
        input(type: 'hidden', name: '_method', value: 'delete')
        input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
        candidates_table(candidates)
        button(type: 'submit', class: 'mt-2 Button Button--sm Button--danger') { 'Delete ticked' }
      end
    end
  end

  def candidates_table(candidates)
    table(class: 'table-auto w-full text-sm') do
      thead do
        tr(class: 'border-b-2 border-grey-400 text-left') do
          th(class: 'pr-2') { 'Delete' }
          th(class: 'pr-2') { 'Recipe' }
          th(class: 'pr-2') { 'Ingredients' }
          th(class: 'pr-2') { 'Fit' }
          th { 'Makes' }
        end
      end
      tbody { candidates.each { candidate_row(_1) } }
    end
  end

  def candidate_row(candidate)
    recipe = candidate.recipe
    tr(class: 'align-top border-b border-grey-200 dark:border-grey-700') do
      td(class: 'pr-2') do
        input(type: 'checkbox', name: 'recipe_ids[]', value: recipe.id, checked: true,
              aria: { label: "Delete #{recipe.name}" })
      end
      td(class: 'pr-2') { a(href: recipe_path(recipe), class: 'Link Link--primary') { recipe.name } }
      td(class: 'pr-2') { plain recipe.ingredients.map { "#{_1.count} #{_1.item.name}" }.join(', ') }
      td(class: 'pr-2') do
        if candidate.fits?
          span(class: 'text-green-700 dark:text-green-400') { 'fits' }
        else
          candidate.misfits.each { |misfit| div(class: 'text-yellow-800 dark:text-yellow-300') { misfit } }
        end
      end
      td do
        candidate.items.each do |result|
          div do
            a(href: item_path(result.item), class: 'Link Link--primary') { result.item.name }
            span(class: 'text-grey-500') { result.deleted? ? ' (deleted)' : " (kept: #{result.kept_because})" }
          end
        end
      end
    end
  end

end

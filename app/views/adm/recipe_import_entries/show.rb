# frozen_string_literal: true

class Views::Adm::RecipeImportEntries::Show < Views::Adm::RecipeImports::Base

  def initialize(import:, entry:)
    @import = import
    @entry = entry
    @gr = entry.game_recipe
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      import_header(@import, nil)
      div(class: 'p-4') do
        div(class: 'flex flex-row flex-wrap items-center gap-4 mb-4') do
          h2(class: 'text-xl font-bold') { @entry.name }
          status_flair(@entry.status)
          actions
        end

        if @entry.problems.any? && !@entry.final?
          div(class: 'mb-4') do
            @entry.problems.each { |problem| notice_tag(:danger, problem) }
          end
        end

        div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-4') do
          div { game_side }
          div { site_side }
        end

        details(class: 'mt-4') do
          summary(class: 'cursor-pointer text-sm') { 'Raw export JSON' }
          pre(class: 'text-xs whitespace-pre-wrap') { JSON.pretty_generate(@entry.payload) }
        end
      end
    end
  end

  private

  def actions
    if @entry.applicable?
      post_button(@entry.unchanged? ? 'Link to site recipe' : (@entry.addition? ? 'Create recipe' : 'Apply changes'),
                  apply_adm_recipe_import_entry_path(@import, @entry), style: 'primary')
    end
    if @entry.skipped?
      post_button('Unskip', unskip_adm_recipe_import_entry_path(@import, @entry))
    elsif !@entry.applied?
      post_button('Skip', skip_adm_recipe_import_entry_path(@import, @entry))
    end
  end

  def game_side
    h3(class: 'text-lg font-bold mb-2') { 'In the game' }
    dl(class: 'grid grid-cols-[max-content_1fr] gap-x-4 gap-y-1') do
      dt(class: 'font-bold') { 'Game id' }
      dd { @gr.game_id.to_s }
      dt(class: 'font-bold') { 'Category' }
      dd { [ @gr.craft_skill&.name, "(#{@gr.category_key})" ].compact.join(' ') }
      dt(class: 'font-bold') { 'Level' }
      dd { @gr.proficiency.to_s }
      if @gr.refine?
        dt(class: 'font-bold') { 'Refine' }
        dd { 'yes' }
      end
      dt(class: 'font-bold') { 'Ingredients' }
      dd do
        ul do
          @gr.ingredients.each do |line|
            li do
              plain "#{line.count} #{line.name}"
              span(class: 'text-grey-500') { ' (tool)' } if line.tool?
            end
          end
        end
      end
      dt(class: 'font-bold') { 'Results' }
      dd do
        ul { @gr.results.each { |line| li { "#{line.count} #{line.name}" } } }
      end
    end
  end

  def site_side
    h3(class: 'text-lg font-bold mb-2') { 'On the site' }
    if @entry.recipe
      p(class: 'mb-2 text-sm') { "Matched by #{@entry.match_method}." }
      render Components::Recipes::Card.new(recipe: @entry.recipe)
      if @entry.diff.any?
        h4(class: 'font-bold mt-2') { 'Applying will change' }
        diff_table
      end
    else
      p(class: 'mb-2') { 'No matching site recipe. Applying will create one.' }
    end
    link_form unless @entry.final?
  end

  def diff_table
    table(class: 'table-auto text-sm') do
      @entry.diff.each do |key, value|
        if %w[ingredients results].include?(key)
          Array(value['added']).each { |name, count| diff_row(key, 'add', "#{count} #{name}") }
          Array(value['removed']).each { |name, count| diff_row(key, 'remove', "#{count} #{name}") }
          Array(value['changed']).each { |name, from, to| diff_row(key, 'change', "#{name}: #{from} → #{to}") }
        else
          from, to = value
          diff_row(key, 'change', "#{from.inspect} → #{to.inspect}")
        end
      end
    end
  end

  def diff_row(key, action, text)
    tr(class: 'border-t border-grey-200 dark:border-grey-700') do
      th(class: 'text-right pr-2') { key }
      td(class: 'pr-2') { em { action } }
      td { text }
    end
  end

  def link_form
    form(action: link_adm_recipe_import_entry_path(@import, @entry), method: 'post', class: 'mt-4 flex flex-row items-center gap-2') do
      input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
      label(for: 'recipe_id', class: 'text-sm') { 'Match to site recipe #' }
      input(type: 'number', id: 'recipe_id', name: 'recipe_id', value: (@entry.recipe_id if @entry.manual_match?),
            class: 'w-28 border border-grey-400 rounded px-2 py-1 dark:bg-grey-700')
      button(type: 'submit', class: 'Button Button--sm Button--default') { 'Link' }
    end
    p(class: 'text-xs text-grey-500 mt-1') { 'Leave blank to clear a manual match.' }
  end
end

# frozen_string_literal: true

class Views::Adm::RecipeImports::Show < Views::Adm::RecipeImports::Base

  BULK_ACTIONS = {
    'unchanged' => 'Link all unchanged',
    'outdated'  => 'Apply all outdated',
    'addition'  => 'Create all new',
  }.freeze

  def initialize(import:, entries:, status:)
    @import = import
    @entries = entries
    @status = status
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      import_header(@import, :recipes)
      div(class: 'p-4') do
        status_filters
        bulk_actions
        item_filter_notice
        search_form
        paginate @entries
        entries_table
        paginate @entries
      end
    end
  end

  private

  def status_filters
    counts = @import.status_counts
    div(class: 'flex flex-row flex-wrap gap-2 mb-4') do
      filter_link("All (#{counts.values.sum})", nil)
      counts.each do |status, n|
        filter_link("#{STATUS_LABELS[status]} (#{n})", status)
      end
    end
  end

  def filter_link(label, status)
    style = @status == status ? 'primary' : 'default'
    a(href: adm_recipe_import_path(@import, status: status, item: params[:item].presence), class: "Button Button--sm Button--#{style}") { label }
  end

  def bulk_actions
    counts = @import.status_counts
    div(class: 'flex flex-row flex-wrap items-center gap-2 mb-4') do
      BULK_ACTIONS.each do |status, label|
        next unless counts[status].positive?
        post_button("#{label} (#{counts[status]})", apply_all_adm_recipe_import_path(@import),
                    style: status == 'unchanged' ? 'success' : 'primary',
                    params: { status: status },
                    confirm: "#{label}? This updates the live site, recording a revision for each recipe.")
      end
      post_button('Re-analyze', analyze_adm_recipe_import_path(@import))
      if @import.analyzed_at
        span(class: 'text-sm text-grey-600 dark:text-grey-300') do
          plain 'analyzed '
          time_ago_tag @import.analyzed_at
        end
      end
    end
  end

  def item_filter_notice
    return if params[:item].blank?

    div(class: 'mb-2 flex flex-row items-center gap-2') do
      plain 'Recipes using '
      strong { params[:item] }
      a(href: adm_recipe_import_path(@import, status: @status), class: 'Link text-sm') { 'clear' }
    end
  end

  def search_form
    form(action: adm_recipe_import_path(@import), method: 'get', class: 'mb-2 flex flex-row gap-2') do
      input(type: 'hidden', name: 'status', value: @status) if @status
      input(type: 'hidden', name: 'item', value: params[:item]) if params[:item].present?
      input(type: 'search', name: 'q', value: params[:q], placeholder: 'Filter by name',
            class: 'border border-grey-400 rounded px-2 py-1 dark:bg-grey-700')
      button(type: 'submit', class: 'Button Button--sm Button--default') { 'Filter' }
    end
  end

  def entries_table
    table(class: 'table-auto w-full') do
      thead do
        tr(class: 'border-b-2 border-grey-400 text-left') do
          th { 'Game recipe' }
          th { 'Skill' }
          th(class: 'text-right') { 'Lvl' }
          th { 'Site recipe' }
          th { 'Status' }
          th { 'Details' }
          th { whitespace }
        end
      end
      tbody do
        @entries.each { |entry| entry_row(entry) }
      end
    end
  end

  def entry_row(entry)
    gr = entry.game_recipe
    tr(class: 'align-top border-b border-grey-200 dark:border-grey-700 hover:bg-grey-100 dark:hover:bg-grey-700') do
      td do
        a(href: adm_recipe_import_entry_path(@import, entry), class: 'Link Link--primary') { entry.name }
      end
      td(class: 'text-sm') { gr.craft_skill&.name || gr.category_key }
      td(class: 'text-right text-sm') { gr.proficiency }
      td(class: 'text-sm') do
        if entry.recipe
          a(href: recipe_path(entry.recipe), class: 'Link') { entry.recipe.name }
          span(class: 'text-grey-500') { " (#{entry.match_method})" }
        else
          span(class: 'text-grey-500') { '—' }
        end
      end
      td { status_flair(entry.status) }
      td(class: 'text-sm') { details(entry) }
      td(class: 'text-right whitespace-nowrap') { row_actions(entry) }
    end
  end

  def details(entry)
    if entry.blocked?
      entry.problems.each { |problem| div(class: 'text-red-600 dark:text-red-300') { problem } }
    elsif entry.outdated?
      diff_summary(entry.diff)
    elsif entry.addition?
      plain counted_lines(entry.game_recipe.ingredients.map { [ _1.name, _1.count ] })
    end
  end

  def diff_summary(diff)
    diff.each do |key, value|
      div do
        strong { "#{key}: " }
        case key
        when 'ingredients', 'results'
          parts = []
          parts << "+ #{counted_lines(value['added'])}" if value['added']
          parts << "− #{counted_lines(value['removed'])}" if value['removed']
          Array(value['changed']).each { |name, from, to| parts << "#{name} #{from}→#{to}" }
          plain parts.join('; ')
        else
          from, to = value
          plain "#{from.inspect} → #{to.inspect}"
        end
      end
    end
  end

  def row_actions(entry)
    if entry.applicable?
      post_button(entry.unchanged? ? 'Link' : 'Apply', apply_adm_recipe_import_entry_path(@import, entry), style: 'primary')
    end
    if entry.skipped?
      post_button('Unskip', unskip_adm_recipe_import_entry_path(@import, entry))
    elsif !entry.applied?
      post_button('Skip', skip_adm_recipe_import_entry_path(@import, entry))
    end
  end
end

# frozen_string_literal: true

class Views::Adm::ItemReviews::Index < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  FILTER_LABELS = {
    'abstract'  => 'All abstract',
    'group'     => 'Groups',
    'archetype' => 'Archetypes',
    'category'  => 'Categories',
    'suspect'   => 'Concrete suspects',
    'recent'    => 'Created since imports',
  }.freeze

  KIND_HINTS = {
    'concrete'  => 'a real thing in the game',
    'group'     => 'a material choice: a complete set of concrete items, any of which a recipe will take',
    'archetype' => 'a kind of thing; which one a recipe makes depends on its ingredients',
    'category'  => 'anything that qualifies; any members are just examples',
  }.freeze

  TABS = Views::Adm::RecipeImports::Base

  def initialize(review:, rows:, counts:)
    @review = review
    @rows = rows
    @counts = counts
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      div(class: 'p-4 pb-0') do
        h1(class: 'text-2xl font-bold') { 'Item Review' }
        intro
        filter_tabs
      end
      div(class: 'p-4') do
        search_form
        if @rows.empty?
          notice_success('Nothing to review here.')
        else
          paginate @rows
          rows_table
          paginate @rows
        end
      end
    end
  end

  private

  def intro
    div(class: 'my-2 max-w-prose text-sm') do
      p(class: 'mb-1') { 'What each item name stands for:' }
      ul(class: 'list-disc ml-6 mb-1') do
        KIND_HINTS.each do |kind, hint|
          li do
            strong { kind }
            plain " - #{hint}"
          end
        end
      end
      p do
        plain 'Items with likely problems are listed first, with a suggested kind where the '
        plain 'evidence points to one. Changes are recorded in each item\'s history.'
      end
    end
  end

  def filter_tabs
    nav(class: 'mt-2 flex flex-row flex-wrap gap-x-1 border-b border-grey-300 dark:border-grey-600') do
      FILTER_LABELS.each do |filter, label|
        next unless @counts.key?(filter)
        a(href: adm_item_reviews_path(filter: filter, issues: params[:issues].presence),
          class: filter == @review.filter ? TABS::ACTIVE_TAB_CSS : TABS::INACTIVE_TAB_CSS) do
          "#{label} (#{@counts[filter]})"
        end
      end
    end
  end

  def search_form
    form(action: adm_item_reviews_path, method: 'get', class: 'mb-2 flex flex-row flex-wrap items-center gap-2') do
      input(type: 'hidden', name: 'filter', value: @review.filter)
      input(type: 'search', name: 'q', value: params[:q], placeholder: 'Filter by name',
            class: 'border border-grey-400 rounded px-2 py-1 dark:bg-grey-700')
      label(class: 'text-sm flex flex-row items-center gap-1') do
        input(type: 'checkbox', name: 'issues', value: '1', checked: params[:issues].present?)
        plain 'Only items with issues'
      end
      button(type: 'submit', class: 'Button Button--sm Button--default') { 'Filter' }
    end
  end

  def rows_table
    table(class: 'table-auto w-full') do
      thead do
        tr(class: 'border-b-2 border-grey-400 text-left') do
          th { 'Item' }
          th { 'Evidence' }
          th { 'Issues' }
          th { 'Kind' }
        end
      end
      tbody { @rows.each { |row| item_row(row) } }
    end
  end

  def item_row(row)
    item = row.item
    tr(class: 'align-top border-b border-grey-200 dark:border-grey-700') do
      td(class: 'pr-2') do
        a(href: item_path(item), class: 'Link Link--primary font-bold') { item.name }
        div(class: 'text-xs text-grey-500') do
          plain item.kind
          if @review.filter == 'recent'
            plain ' · created '
            time_ago_tag item.created_at
          end
        end
      end
      td(class: 'pr-2 text-sm') { evidence(row) }
      td(class: 'pr-2 text-sm') { issues(row) }
      td(class: 'text-sm') { kind_form(item) }
    end
  end

  def evidence(row)
    lines = []
    lines << uses('ingredient in', row.ingredient_uses, row.game_ingredient_uses) if row.ingredient_uses.positive?
    lines << uses('made by', row.result_uses, row.game_result_uses) if row.result_uses.positive?
    lines << 'taken and given back by a modification recipe' if row.modified?
    lines << "made from #{row.made_from_groups.to_sentence}" if row.made_from_groups.any?
    if row.members.positive?
      noun = row.item.category? ? 'example' : 'member'
      lines << "#{row.members} #{noun.pluralize(row.members)}"
    end
    lines << "in #{row.groups} #{row.groups == 1 ? 'group or category' : 'groups or categories'}" if row.groups.positive?
    if lines.empty?
      span(class: 'text-grey-500') { 'unused' }
    else
      lines.each { |line| div { line } }
    end
  end

  def uses(prefix, count, from_game)
    text = "#{prefix} #{count} #{'recipe'.pluralize(count)}"
    from_game.positive? ? "#{text} (#{from_game} from the game)" : text
  end

  def issues(row)
    row.issues.each do |issue|
      div(class: 'mb-1 flex flex-row flex-wrap items-center gap-2') do
        span(class: 'text-yellow-800 dark:text-yellow-300') { issue.message }
        if issue.suggest
          kind_button("Make #{issue.suggest}", row.item, issue.suggest, style: 'primary')
        end
      end
    end
  end

  def kind_form(item)
    form(action: adm_item_review_path(item), method: 'post', class: 'flex flex-row items-center gap-1') do
      input(type: 'hidden', name: '_method', value: 'patch')
      input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
      select(name: 'kind', class: 'border border-grey-400 rounded px-1 py-1 text-sm dark:bg-grey-700') do
        Item.kinds.each_key do |kind|
          option(value: kind, selected: kind == item.kind) { kind }
        end
      end
      button(type: 'submit', class: 'Button Button--sm Button--default') { 'Set' }
    end
  end

  def kind_button(label, item, kind, style: 'default')
    button_to(label, adm_item_review_path(item), method: :patch, params: { kind: kind },
              class: "Button Button--sm Button--#{style}", form: { class: 'inline-block' })
  end
end

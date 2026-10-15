# frozen_string_literal: true

# The export's item weights beside the site's (see GameWeights).
class Views::Adm::RecipeImports::Weights < Views::Adm::RecipeImports::Base

  def initialize(import:, weights:)
    @import = import
    @weights = weights
    @counts = weights.counts
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      import_header(@import, :weights)
      div(class: 'p-4') do
        intro
        if @weights.rows.empty?
          notice_warning('No weights to compare: the export has none, or its items\' keys aren\'t recorded yet.')
        else
          summary_list
          section('different', 'Different on the site',
                  'Often the site\'s is rounded. Updating takes the game\'s.')
          section('conflict', 'Several game keys, different weights',
                  'The site has these as one item, but the game weighs its variants differently. ' \
                  'Set the weight by hand.')
          section('missing', 'Missing on the site', nil, collapsed: true)
        end
      end
    end
  end

  private

  def intro
    p(class: 'mb-4 max-w-prose') do
      plain 'The game gives every item\'s weight. Items are matched by their recorded game keys, so '
      plain 'record keys first. Each change is recorded in the item\'s history.'
    end
  end

  def summary_list
    ul(class: 'mb-4 text-sm') do
      li { "#{@counts['missing']} missing on the site" }
      li { "#{@counts['different']} different on the site" }
      li { "#{@counts['conflict']} with game keys that disagree" }
      li { "#{@counts['same']} the same" }
    end
    div(class: 'mb-4 flex flex-row flex-wrap gap-2') do
      if @counts['missing'].positive?
        post_button("Fill #{@counts['missing']} missing #{'weight'.pluralize(@counts['missing'])}",
                    set_weights_adm_recipe_import_path(@import), style: 'primary', params: { status: 'missing' })
      end
      if @counts['different'].positive?
        post_button("Update #{@counts['different']} different #{'weight'.pluralize(@counts['different'])}",
                    set_weights_adm_recipe_import_path(@import), style: 'warning', params: { status: 'different' },
                    confirm: "Replace #{@counts['different']} site weights with the game's?")
      end
    end
  end

  def section(status, title, hint, collapsed: false)
    rows = @weights.rows.select { _1.status == status }
    return if rows.empty?

    if collapsed
      details(class: 'mt-4') do
        summary(class: 'cursor-pointer text-lg font-bold') { "#{title} (#{rows.size})" }
        weights_table(rows)
      end
    else
      h2(class: 'mt-4 mb-1 text-lg font-bold') { "#{title} (#{rows.size})" }
      p(class: 'mb-1 text-sm max-w-prose') { hint } if hint
      weights_table(rows)
    end
  end

  def weights_table(rows)
    table(class: 'table-auto text-sm') do
      thead do
        tr(class: 'border-b-2 border-grey-400 text-left') do
          th(class: 'pr-6') { 'Item' }
          th(class: 'pr-6 text-right') { 'Site' }
          th(class: 'text-right') { 'Game' }
        end
      end
      tbody do
        rows.each do |row|
          tr(class: 'border-b border-grey-200 dark:border-grey-700') do
            td(class: 'pr-6') { a(href: item_path(row.item), class: 'Link Link--primary') { row.item.name } }
            td(class: 'pr-6 text-right') { format_weight(row.item.weight) }
            td(class: 'text-right') { row.weights.map { format_weight(_1) }.join(' / ') }
          end
        end
      end
    end
  end

  def format_weight(weight)
    weight.nil? ? '-' : weight.to_s('F')
  end

end

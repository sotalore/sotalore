# frozen_string_literal: true

# Review of an item catalog import (see ItemCatalogAnalysis), and applying it.
class Views::Adm::ItemCatalogImports::Show < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  # +open+ names a list section to show expanded (after acting on it).
  def initialize(import:, analysis:, open: nil)
    @import = import
    @analysis = analysis
    @counts = analysis.counts
    @open = open
  end

  def view_template
    div(class: 'm-2 p-4 bg-white dark:bg-grey-800') do
      header
      summary_list
      next unless @import.supported?

      unknown_items('components', 'Salvage components the site doesn\'t know', @analysis.unknown_components,
                    'Their salvage is left out until they\'re resolved.')
      changes
      unknown_items('catalog', 'Catalog items the site doesn\'t know', @analysis.unknown_catalog_items,
                    'Often quest notes and keys; only add the ones worth having on the site.', collapsed: true)
      skipped_crafted
    end
  end

  private

  def header
    div(class: 'flex flex-row flex-wrap items-baseline gap-x-4') do
      h1(class: 'text-2xl font-bold') { @import.to_s }
      span(class: 'text-sm text-grey-600 dark:text-grey-300') do
        plain [ @import.filename, ("plugin #{@import.plugin_version}" if @import.plugin_version),
                ("scope: #{@import.catalog.scope}" if @import.catalog.scope),
                ("api v#{@import.api_version}" if @import.api_version) ].compact.join(' · ')
        plain ' · uploaded '
        time_ago_tag @import.created_at
        if @import.applied_at
          plain ' · applied '
          time_ago_tag @import.applied_at
        end
      end
      a(href: adm_item_catalog_imports_path, class: 'Link text-sm') { 'All item catalogs' }
    end
    p(class: 'my-2 max-w-prose text-sm') do
      plain 'Applying records the game\'s key and tooltip for each item the site knows, fills weights the site '
      plain 'lacks, makes "Tool" items of unknown use tools, and adds or updates salvage. It doesn\'t remove '
      plain 'salvage, or change weights the site already has unless you ask. A crafted item (its '
      plain 'tooltip says "Crafted by") only gives its salvage, and only when it\'s the plain base item (materials '
      plain 'change what it salvages into).'
    end
  end

  def summary_list
    unless @import.supported?
      notice_warning("This file is from a plugin before #{GameCatalog::MINIMUM_VERSION}, whose weights and prices are " \
                     'for whole stacks, so it can\'t be applied. Delete it and import a new export.')
      button_to('Delete this import', adm_item_catalog_import_path(@import), method: :delete,
                class: 'Button Button--sm Button--danger',
                form: { class: 'inline-block mb-4', data: { turbo_confirm: "Delete #{@import}?" } })
      return
    end
    ul(class: 'mb-2 text-sm') do
      li { "#{@counts[:known]} items the site knows, #{@counts[:unknown]} it doesn't" }
      li { "#{@counts[:missing_weights]} weights to fill, #{@counts[:different_weights]} that differ (updated only on request)" }
      li { "#{@counts[:tools]} to make tools" }
      li { "Salvage: #{@counts[:salvage_to_add]} to add and #{@counts[:salvage_to_update]} to update, on #{@counts[:salvage_items]} items; #{@counts[:extra_salvage]} on the site the game doesn't list" }
    end
    div(class: 'mb-4 flex flex-row flex-wrap gap-2') do
      button_to(@import.applied_at ? 'Apply again' : 'Apply', apply_adm_item_catalog_import_path(@import), method: :post,
                class: 'Button Button--sm Button--primary', form: { class: 'inline-block' })
      if @counts[:different_weights].positive?
        n = @counts[:different_weights]
        button_to("Update #{n} different #{'weight'.pluralize(n)}", update_weights_adm_item_catalog_import_path(@import),
                  method: :post, class: 'Button Button--sm Button--warning',
                  form: { class: 'inline-block', data: { turbo_confirm: "Replace #{n} site #{'weight'.pluralize(n)} with the game's?" } })
      end
    end
  end

  def changes
    rows = @analysis.rows.select(&:interesting?)
    return if rows.empty?
    h2(class: 'mt-4 mb-1 text-lg font-bold') { "Changes (#{rows.size} items)" }
    table(class: 'table-auto w-full text-sm') do
      thead do
        tr(class: 'border-b-2 border-grey-400 text-left') do
          th { 'Item' }
          th { 'Weight' }
          th { 'Salvage' }
          th { 'Merchant pays / price' }
        end
      end
      tbody do
        rows.each { change_row(_1) }
      end
    end
  end

  def change_row(row)
    tr(class: 'align-top border-b border-grey-200 dark:border-grey-700') do
      td(class: 'pr-3 py-1') do
        a(href: item_path(row.item), class: 'Link Link--primary') { row.item.name }
        div(class: 'text-xs text-grey-500') { row.entry.name } unless row.entry.name.casecmp?(row.item.name)
        div(class: 'text-xs') { 'becomes a tool' } if row.tool?
      end
      td(class: 'pr-3 py-1') do
        if row.missing_weight? then plain "– → #{row.entry.weight}"
        elsif row.different_weight? then plain "#{row.item.weight.to_s('F')} (game: #{row.entry.weight})"
        end
      end
      td(class: 'pr-3 py-1') { salvage_cell(row) }
      td(class: 'py-1') do
        pays = row.entry.merchant_pays
        plain [ pays && pays.uniq.join('–'), row.item.price ].map { _1 || '–' }.join(' / ') if pays || row.item.price
      end
    end
  end

  def salvage_cell(row)
    row.salvage.each do |s|
      div do
        plain "#{s.game.name} #{amount(s.game.min, s.game.max)}#{" #{s.game.chance}%" if s.game.chance}"
        span(class: 'text-xs text-grey-500') { salvage_status(s) }
      end
    end
    return if row.extra_salvage.empty?
    div(class: 'mt-1') do
      plain "Not in the game's list: #{row.extra_salvage.map { _1.salvage_to.name }.join(', ')} "
      button_to('Remove', remove_salvage_adm_item_catalog_import_path(@import), method: :post,
                params: { item_id: row.item.id }, class: 'Button Button--sm Button--danger',
                form: { class: 'inline-block', data: { turbo_confirm: "Remove these from #{row.item.name}'s salvage?" } })
    end
  end

  def salvage_status(salvage)
    if !salvage.known? then ' (unknown)'
    elsif salvage.missing? then ' new'
    elsif salvage.changed? then ' changed'
    else ''
    end
  end

  def amount(min, max)
    min == max ? min.to_s : "#{min}–#{max}"
  end

  def unknown_items(section, title, items, hint, collapsed: false)
    render Components::Imports::UnknownItems.new(
      section: section, title: title, items: items, hint: hint, collapsed: collapsed, open: @open == section,
      action: resolve_adm_item_catalog_import_path(@import), describe: ->(unknown) { unknown.uses }
    )
  end

  def skipped_crafted
    skipped = @analysis.skipped_crafted
    return if skipped.empty?
    details(class: 'mt-4') do
      summary(class: 'cursor-pointer text-lg font-bold') { "Crafted items left out (#{skipped.size})" }
      p(class: 'text-sm mb-1') { 'Crafted items share their base item\'s key, and the site doesn\'t have one for these:' }
      ul(class: 'text-sm list-disc ml-6') { skipped.each { |entry| li { entry.name } } }
    end
  end
end

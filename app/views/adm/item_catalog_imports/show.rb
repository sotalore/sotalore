# frozen_string_literal: true

# Review of an item catalog import (see ItemCatalogAnalysis), and applying it.
class Views::Adm::ItemCatalogImports::Show < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  INPUT_CSS = 'border border-grey-400 rounded px-2 py-1 text-sm dark:bg-grey-700'

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

  # A list of unknown items, each with Create and Use, and a "Create
  # selected" for many at once (checkboxes tied to a form of their own, as
  # each row has its own Use form). The forms skip Turbo, which drops the
  # redirect's #anchor, so the page comes back at the list.
  def unknown_items(section, title, items, hint, collapsed: false)
    return if items.empty?
    form_id = "create-#{section}"
    body = lambda do
      p(class: 'mb-2 text-sm max-w-prose') { hint }
      form(id: form_id, action: resolve_adm_item_catalog_import_path(@import, anchor: section), method: 'post',
           class: 'mb-2 flex flex-row flex-wrap items-center gap-3', data: { turbo: 'false' }) do
        hidden_fields(section)
        input(type: 'hidden', name: 'resolution', value: 'create_many')
        label(class: 'flex flex-row items-center gap-1 text-sm') do
          input(type: 'checkbox', data: { action: 'check-all#toggle' })
          plain 'Select all'
        end
        button(type: 'submit', class: 'Button Button--sm Button--primary') { 'Create selected' }
      end
      table(class: 'table-auto text-sm') { items.each { unknown_row(section, form_id, _1) } }
    end
    div(id: section, data: { controller: 'check-all' }) do
      if collapsed
        details(class: 'mt-4', open: @open == section) do
          summary(class: 'cursor-pointer text-lg font-bold') { "#{title} (#{items.size})" }
          body.call
        end
      else
        h2(class: 'mt-4 mb-1 text-lg font-bold') { "#{title} (#{items.size})" }
        body.call
      end
    end
  end

  def unknown_row(section, form_id, unknown)
    tr(class: 'border-b border-grey-200 dark:border-grey-700 align-top') do
      td(class: 'pr-2 py-1') do
        input(type: 'checkbox', name: 'selected[]', form: form_id, value: { name: unknown.name, key: unknown.key }.to_json,
              data: { check_all_target: 'box' }, aria: { label: "Select #{unknown.name}" })
      end
      td(class: 'pr-3 py-1') do
        strong { unknown.name }
        div(class: 'text-xs text-grey-500') { [ unknown.key || 'no key', unknown.uses ].join(' · ') }
      end
      td(class: 'py-1') do
        form(action: resolve_adm_item_catalog_import_path(@import, anchor: section), method: 'post',
             class: 'flex flex-row flex-wrap items-center gap-1', data: { turbo: 'false' }) do
          hidden_fields(section)
          input(type: 'hidden', name: 'name', value: unknown.name)
          input(type: 'hidden', name: 'key', value: unknown.key) if unknown.key
          button(type: 'submit', name: 'resolution', value: 'create', class: 'Button Button--sm Button--default') { 'Create' }
          input(type: 'text', name: 'item_name', placeholder: 'or an existing item', class: "#{INPUT_CSS} w-48")
          button(type: 'submit', name: 'resolution', value: 'use', class: 'Button Button--sm Button--default') { 'Use' }
        end
      end
    end
  end

  def hidden_fields(section)
    input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
    input(type: 'hidden', name: 'open', value: section)
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

# frozen_string_literal: true

# Review of a finds import (see FindsImportAnalysis), and applying it.
class Views::Adm::FindsImports::Show < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  INPUT_CSS = 'border border-grey-400 rounded px-2 py-1 text-sm dark:bg-grey-700'

  # +open+ names the section acted on, to come back to.
  def initialize(import:, analysis:, scenes:, open: nil)
    @import = import
    @analysis = analysis
    @unlinked_scenes = scenes
    @open = open
  end

  def view_template
    div(class: 'm-2 p-4 bg-white dark:bg-grey-800') do
      header
      unmatched_scenes
      unknown_items
      new_things
      @analysis.scenes.each { scene_section(_1) }
    end
  end

  private

  def header
    div(class: 'flex flex-row flex-wrap items-baseline gap-x-4') do
      h1(class: 'text-2xl font-bold') { @import.to_s }
      span(class: 'text-sm text-grey-600 dark:text-grey-300') do
        plain [ @import.filename, ("plugin #{@import.plugin_version}" if @import.plugin_version),
                ("api v#{@import.api_version}" if @import.api_version) ].compact.join(' · ')
        plain ' · uploaded '
        time_ago_tag @import.created_at
        if @import.applied_at
          plain ' · applied '
          time_ago_tag @import.applied_at
        end
      end
      a(href: adm_finds_imports_path, class: 'Link text-sm') { 'All finds imports' }
    end
    p(class: 'my-2 max-w-prose text-sm') do
      plain 'Applying records, for each matched scene, the items found there, its creatures and gathering '
      plain 'nodes, and what field dressing a creature or harvesting a node gives. A node named like a creature '
      plain 'is field dressing. Unmatched scenes and unknown items are left out until resolved below; applying '
      plain 'again later adds them.'
    end
    post_button(@import.applied_at ? 'Apply again' : 'Apply', apply_adm_finds_import_path(@import), style: 'primary')
  end

  def unmatched_scenes
    rows = @analysis.unmatched_scenes
    return if rows.empty?
    h2(id: 'scenes', class: 'mt-6 mb-1 text-lg font-bold') { "Scenes not on the site (#{rows.size})" }
    p(class: 'mb-2 text-sm max-w-prose') do
      plain 'Link each to the site\'s scene (recording the game\'s internal name for it), or add the scene on '
      plain 'the Scenes page first.'
    end
    rows.each do |row|
      form(action: resolve_adm_finds_import_path(@import), method: 'post',
           class: 'mb-2 flex flex-row flex-wrap items-center gap-2', data: { turbo_action: 'replace' }) do
        authenticity_token_field
        input(type: 'hidden', name: 'open', value: 'scenes')
        input(type: 'hidden', name: 'resolution', value: 'scene')
        input(type: 'hidden', name: 'name', value: row.game.name)
        strong { row.game.name }
        span(class: 'text-xs text-grey-500') { row.game.raw_name.to_s }
        select(name: 'scene_id', class: INPUT_CSS) do
          option(value: '') { 'choose a scene...' }
          @unlinked_scenes.each { |scene| option(value: scene.id) { scene.name } }
        end
        button(type: 'submit', class: 'Button Button--sm Button--default') { 'Link' }
      end
    end
  end

  def unknown_items
    render Components::Imports::UnknownItems.new(
      section: 'items', title: 'Items the site doesn\'t know', items: @analysis.unknown_items,
      hint: 'Create each as a new concrete item, or use an existing item (which gets the game\'s key, or the ' \
            'game\'s name as an alias when there\'s no key).',
      action: resolve_adm_finds_import_path(@import),
      describe: ->(unknown) { "in #{unknown.scene_names.to_sentence}" }
    )
  end

  def new_things
    creatures = @analysis.new_creatures
    nodes = @analysis.new_nodes
    return if creatures.empty? && nodes.empty?
    h2(class: 'mt-6 mb-1 text-lg font-bold') { 'New to the site' }
    p(class: 'text-sm') { "Creatures (#{creatures.size}): #{creatures.join(', ')}" } if creatures.any?
    p(class: 'text-sm') { "Gathering nodes (#{nodes.size}): #{nodes.join(', ')}" } if nodes.any?
  end

  def scene_section(row)
    details(class: 'mt-4 border border-grey-300 dark:border-grey-600 rounded p-2') do
      summary(class: 'cursor-pointer') do
        strong { row.game.name }
        plain " → #{row.scene ? row.scene.name : 'not on the site'}"
        span(class: 'text-sm text-grey-500') do
          plain " · #{row.items.size} items (#{row.unknown_items.size} unknown), #{row.creatures.size} creatures, " \
                "#{row.nodes.size} nodes"
        end
      end
      if row.differences.any?
        p(class: 'text-sm text-yellow-800 dark:text-yellow-300') do
          plain 'The game disagrees: '
          plain row.differences.map { |what, site, game| "#{what}: site #{site ? 'yes' : 'no'}, game #{game ? 'yes' : 'no'}" }.join('; ')
        end
      end
      labelled('Items', row.items.map { |f| f.item ? f.item.name : "#{f.game_item.name} (unknown)" })
      labelled('Creatures', row.creatures.map { |c| [ c.name, level_text(c) ].compact.join(' ') })
      row.nodes.each do |node|
        labelled("#{node.creature? ? 'Field dressing' : 'Node'} #{node.name}",
                 node.items.map { |f| f.item ? f.item.name : "#{f.game_item.name} (unknown)" })
      end
    end
  end

  def level_text(creature)
    return if creature.level_min.nil?
    creature.level_min == creature.level_max ? "(level #{creature.level_min})" : "(levels #{creature.level_min}–#{creature.level_max})"
  end

  def labelled(label, names)
    return if names.empty?
    p(class: 'text-sm my-1') do
      strong { "#{label}: " }
      plain names.join(', ')
    end
  end

  def post_button(label, path, style: 'default')
    button_to(label, path, method: :post, class: "Button Button--sm Button--#{style}", form: { class: 'inline-block my-2' })
  end

  def authenticity_token_field
    input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
  end
end

# frozen_string_literal: true

# ADM → Scenes: every scene, with which still need their finds imported (to
# choose where to play next) and what each has. A name opens the scene's ADM
# page, where it's managed.
class Views::Adm::Scenes::Index < Views::Base

  SELECT_CSS = 'border border-grey-400 rounded px-2 py-1 text-sm dark:bg-grey-700'

  def initialize(report:)
    @report = report
  end

  def view_template
    scenes = @report.scenes.to_a
    div(class: 'm-2 p-4 bg-white dark:bg-grey-800') do
      div(class: 'flex flex-row flex-wrap items-baseline gap-x-4') do
        h1(class: 'text-2xl font-bold') { 'Scenes' }
        a(href: new_adm_scene_path, class: 'Button Button--sm Button--primary') { 'New scene' }
      end
      p(class: 'my-2 max-w-prose text-sm') do
        plain 'Which scenes have had their items, creatures and gathering nodes imported from a finds file, '
        plain 'and when it was last done, with how many images and notes each has. Play the ones not imported '
        plain 'yet (lower tiers are easiest) and upload the finds. A name opens the scene, to manage it.'
      end
      search
      filters
      done, total = @report.progress
      p(class: 'my-2 text-sm') { "#{done} of #{total} scenes have finds imported. Showing #{scenes.size}." }
      table(class: 'table-auto w-full text-sm') do
        thead do
          tr(class: 'border-b-2 border-grey-400 text-left') do
            th(class: 'pr-3') { 'Scene' }
            th(class: 'pr-3') { 'Tier' }
            th(class: 'pr-3') { 'Region' }
            th(class: 'pr-3') { 'Type' }
            th(class: 'pr-3') { 'Finds imported' }
            th(class: 'pr-3 text-right') { 'Items' }
            th(class: 'pr-3 text-right') { 'Creatures' }
            th(class: 'pr-3 text-right') { 'Nodes' }
            th(class: 'pr-3 text-right') { 'Images' }
            th(class: 'text-right') { 'Notes' }
          end
        end
        tbody { scenes.each { scene_row(_1) } }
      end
    end
  end

  private

  # On its own, so a search shows every status (see SceneFindsReport).
  def search
    form(action: adm_scenes_path, method: 'get', class: 'my-4 flex flex-row items-end gap-2') do
      label(class: 'flex flex-col text-xs font-bold') do
        plain 'Name'
        input(type: 'search', name: 'q', value: @report.q, placeholder: 'Part of a name', class: SELECT_CSS)
      end
      button(type: 'submit', class: 'Button Button--sm Button--default') { 'Search' }
    end
  end

  def filters
    form(action: adm_scenes_path, method: 'get', class: 'my-4 flex flex-row flex-wrap items-end gap-4') do
      filter('Region', 'region', Scene::REGIONS.sort_by(&:first), @report.region, blank: 'Any region')
      filter('Type', 'scene_type', Scene::SCENE_TYPES, @report.scene_type, blank: 'Any type')
      filter('Show', 'status', SceneFindsReport::STATUSES.invert, @report.status)
      filter('Sort by', 'sort', SceneFindsReport::SORTS.invert, @report.sort)
      input(type: 'hidden', name: 'q', value: @report.q) if @report.q
      button(type: 'submit', class: 'Button Button--sm Button--primary') { 'Filter' }
    end
  end

  # +choices+ is [[label, value], ...].
  def filter(title, name, choices, selected, blank: nil)
    label(class: 'flex flex-col text-xs font-bold') do
      plain title
      select(name: name, class: SELECT_CSS) do
        option(value: '') { blank } if blank
        choices.each do |text, value|
          option(value: value, selected: value == selected) { text }
        end
      end
    end
  end

  def scene_row(scene)
    tr(class: "border-b border-grey-200 dark:border-grey-700#{' bg-slorange-50 dark:bg-grey-900' unless scene.finds_imported_at}") do
      td(class: 'pr-3 py-1') do
        a(href: adm_scene_path(scene), class: 'Link Link--primary') { scene.name }
      end
      td(class: 'pr-3') { scene.level_id.nil? ? '–' : scene.level_id.to_s }
      td(class: 'pr-3 whitespace-nowrap') { Scene::REGION_NAMES[scene.region_id] || '–' }
      td(class: 'pr-3 whitespace-nowrap') { Scene::SCENE_TYPE_NAMES[scene.scene_type_id] || '–' }
      td(class: 'pr-3') { scene.finds_imported_at ? time_ago_tag(scene.finds_imported_at) : plain('never') }
      td(class: 'pr-3 text-right') { count(scene.items_count) }
      td(class: 'pr-3 text-right') { count(scene.creatures_count) }
      td(class: 'pr-3 text-right') { count(scene.nodes_count) }
      td(class: 'pr-3 text-right') { count(scene.images_count) }
      td(class: 'text-right') { count(scene.notes_count) }
    end
  end

  def count(n)
    n.zero? ? '' : n.to_s
  end

end

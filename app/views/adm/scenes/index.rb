# frozen_string_literal: true

# Which scenes still need their finds imported, to choose where to play next.
# The scene links open the public site in a new tab, where scenes are edited.
class Views::Adm::Scenes::Index < Views::Base

  SELECT_CSS = 'border border-grey-400 rounded px-2 py-1 text-sm dark:bg-grey-700'

  def initialize(report:)
    @report = report
  end

  def view_template
    scenes = @report.scenes.to_a
    div(class: 'm-2 p-4 bg-white dark:bg-grey-800') do
      h1(class: 'text-2xl font-bold') { 'Scene Finds' }
      p(class: 'my-2 max-w-prose text-sm') do
        plain 'Which scenes have had their items, creatures and gathering nodes imported from a finds file, '
        plain 'and when it was last done. Play the ones not imported yet (lower tiers are easiest) and upload '
        plain 'the finds. Scene names open the scene on the site in a new tab, to edit it there.'
      end
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
            th(class: 'text-right') { 'Nodes' }
          end
        end
        tbody { scenes.each { scene_row(_1) } }
      end
    end
  end

  private

  def filters
    form(action: adm_scenes_path, method: 'get', class: 'my-4 flex flex-row flex-wrap items-end gap-4') do
      filter('Region', 'region', Scene::REGIONS.sort_by(&:first), @report.region, blank: 'Any region')
      filter('Type', 'scene_type', Scene::SCENE_TYPES, @report.scene_type, blank: 'Any type')
      filter('Show', 'status', SceneFindsReport::STATUSES.invert, @report.status)
      filter('Sort by', 'sort', SceneFindsReport::SORTS.invert, @report.sort)
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
        a(href: scene_path(scene), target: '_blank', rel: 'noopener', class: 'Link Link--primary') { scene.name }
        a(href: edit_scene_path(scene), target: '_blank', rel: 'noopener', class: 'Link ml-2 text-xs') { 'edit' }
      end
      td(class: 'pr-3') { scene.level_id.nil? ? '–' : scene.level_id.to_s }
      td(class: 'pr-3 whitespace-nowrap') { Scene::REGION_NAMES[scene.region_id] || '–' }
      td(class: 'pr-3 whitespace-nowrap') { Scene::SCENE_TYPE_NAMES[scene.scene_type_id] || '–' }
      td(class: 'pr-3') { scene.finds_imported_at ? time_ago_tag(scene.finds_imported_at) : plain('never') }
      td(class: 'pr-3 text-right') { count(scene.items_count) }
      td(class: 'pr-3 text-right') { count(scene.creatures_count) }
      td(class: 'text-right') { count(scene.nodes_count) }
    end
  end

  def count(n)
    n.zero? ? '' : n.to_s
  end

end

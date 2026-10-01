# frozen_string_literal: true

# Shared helpers for the recipe import admin pages.
class Views::Adm::RecipeImports::Base < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  STATUS_FLAIRS = {
    'addition'  => [ :primary, 'new' ],
    'unchanged' => [ :success, 'unchanged' ],
    'outdated'  => [ :warning, 'outdated' ],
    'blocked'   => [ :danger,  'blocked' ],
    'applied'   => [ :success, 'applied' ],
    'skipped'   => [ :info,    'skipped' ],
  }.freeze

  STATUS_LABELS = {
    'addition'  => 'New',
    'unchanged' => 'Unchanged',
    'outdated'  => 'Outdated',
    'blocked'   => 'Blocked',
    'applied'   => 'Applied',
    'skipped'   => 'Skipped',
  }.freeze

  TAB_CSS = 'px-3 py-2 border-b-2 text-sm'
  ACTIVE_TAB_CSS = "#{TAB_CSS} border-slorange-600 font-bold"
  INACTIVE_TAB_CSS = "#{TAB_CSS} border-transparent text-grey-600 dark:text-grey-300 hover:border-grey-400"

  private

  def status_flair(status)
    modifier, text = STATUS_FLAIRS.fetch(status)
    flair_tag(modifier, flair_icon(modifier), text)
  end

  def flair_icon(modifier)
    { primary: :eye, success: :badge_check, warning: :warning, danger: :warning, info: :information_circle }[modifier]
  end

  def post_button(label, path, style: 'default', confirm: nil, params: {})
    data = confirm ? { turbo_confirm: confirm } : {}
    button_to(label, path, method: :post, params: params,
              class: "Button Button--sm Button--#{style}",
              form: { class: 'inline-block', data: data })
  end

  def import_header(import, current)
    div(class: 'p-4 pb-0') do
      div(class: 'flex flex-row flex-wrap items-baseline gap-x-4') do
        h1(class: 'text-2xl font-bold') { import.to_s }
        span(class: 'text-sm text-grey-600 dark:text-grey-300') do
          plain [ import.filename, import.full_export? ? 'full export' : 'partial export',
                  ("api v#{import.api_version}" if import.api_version) ].compact.join(' · ')
          plain ' · uploaded '
          time_ago_tag import.created_at
        end
      end
      nav(class: 'mt-2 flex flex-row flex-wrap gap-x-1 border-b border-grey-300 dark:border-grey-600') do
        tab('Recipes', adm_recipe_import_path(import), current == :recipes)
        tab("Unknown items (#{import.unresolved_item_names.size})", items_adm_recipe_import_path(import), current == :items)
        tab('Stale recipes', stale_adm_recipe_import_path(import), current == :stale)
        tab('All imports', adm_recipe_imports_path, false)
      end
    end
  end

  def tab(label, path, active)
    a(href: path, class: active ? ACTIVE_TAB_CSS : INACTIVE_TAB_CSS) { label }
  end

  def counted_lines(lines)
    Array(lines).map { |name, count| "#{count} #{name}" }.join(', ')
  end
end

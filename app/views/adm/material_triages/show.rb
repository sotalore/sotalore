# frozen_string_literal: true

# The materials (see MaterialTriage) by the refining skill that makes or
# takes them: what the site records about each next to what's stored on it,
# and a button for each fix the evidence suggests. Shows only items with
# something to fix, unless +all+.
class Views::Adm::MaterialTriages::Show < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(triage:, all:)
    @triage = triage
    @all = all
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      div(class: 'p-4 pb-0') do
        h1(class: 'text-2xl font-bold') { 'Material Triage' }
        intro
        tabs
      end
      div(class: 'p-4') do
        rows = @all ? @triage.rows : @triage.with_issues
        if rows.empty?
          notice_success('Nothing stored disagrees with what the site records.')
        else
          @triage.by_skill(rows).each { |skill, skill_rows| section_for(skill.name, skill_rows) }
          tools = @triage.tools_and_fuel(rows)
          section_for('Tools and fuel', tools) if tools.any?
        end
      end
    end
  end

  private

  def intro
    div(class: 'my-2 max-w-prose text-sm') do
      p(class: 'mb-1') do
        plain 'Everything refining takes or makes on its way to production. Each item shows what the site records '
        plain '(the recipes that make and take it, finds imports, salvage and merchant prices) next to the use, '
        plain 'source and gathering skill stored on it by hand, which are old and often wrong.'
      end
      p do
        plain 'Where they disagree, the button sets what the evidence suggests. Notes in grey are stored values '
        plain "nothing confirms yet, which may still be right: finds don't cover every scene, or fishing. "
        plain 'A merchant price is taken to mean a merchant sells it, so clear any that are wrong.'
      end
    end
  end

  def tabs
    nav(class: 'flex flex-row gap-4 border-b border-grey-300 dark:border-grey-600 text-sm') do
      tab("To fix (#{@triage.with_issues.size})", adm_material_triage_path, !@all)
      tab("All materials (#{@triage.rows.size})", adm_material_triage_path(show: 'all'), @all)
    end
  end

  def tab(label, path, current)
    css = current ? 'border-b-2 border-orange-600 font-semibold' : 'text-grey-600 dark:text-grey-300'
    a(href: path, class: "pb-1 #{css}", aria: { current: current ? 'page' : nil }) { label }
  end

  def section_for(title, rows)
    section(class: 'mb-6') do
      h2(class: 'text-lg font-bold') do
        plain title
        span(class: 'text-sm font-normal text-grey-500') { " #{rows.size}" }
      end
      table(class: 'table-auto w-full text-sm') do
        thead do
          tr(class: 'border-b-2 border-grey-400 text-left') do
            %w[ Item How\ to\ get\ it Used\ for Stored Merchant\ price ].each { |heading| th(class: 'pr-3') { heading } }
            th { 'To fix' }
          end
        end
        tbody { rows.each { |material| row(material) } }
      end
    end
  end

  def row(row)
    item = row.item
    tr(id: "item-#{item.id}", class: 'align-top border-b border-grey-200 dark:border-grey-700') do
      td(class: 'pr-3 py-1') { a(href: item_path(item), class: 'Link Link--primary') { item.name } }
      td(class: 'pr-3 py-1') { sources(row.sources) }
      td(class: 'pr-3 py-1') { roles(row.roles) }
      td(class: 'pr-3 py-1 whitespace-nowrap') { stored(item) }
      td(class: 'pr-3 py-1') { merchant_price_form(item) }
      td(class: 'py-1') { row.issues.each { |found| issue(item, found) } }
    end
  end

  def sources(sources)
    parts = sources.kinds.map do |kind|
      case kind
      when :crafted then "made (#{sources.crafting_skills.map(&:name).join(', ')})"
      when :gathered then "gathered (#{sources.gathering_skills.map(&:name).join(', ')})"
      when :salvaged then "salvaged from #{sources.salvaged_from.size}"
      when :bought then 'bought'
      when :found then "found in #{sources.scene_count} #{'scene'.pluralize(sources.scene_count)}"
      end
    end
    parts.empty? ? em(class: 'text-grey-500') { 'nothing recorded' } : plain(parts.join('; '))
  end

  def roles(roles)
    counts = roles.refining_counts.merge(roles.production_counts)
    plain counts.map { |skill, n| "#{skill.name} #{n}" }.join(', ')
    plain(counts.empty? ? 'tool' : ', tool') if roles.tool?
  end

  def stored(item)
    div { "use: #{item.use}" }
    div { "source: #{item.source}" }
    div { "gathering: #{item.gathering_skill&.name || '–'}" }
  end

  def merchant_price_form(item)
    form(action: adm_material_triage_path, method: 'post', class: 'flex flex-row items-center gap-1') do
      hidden_fields(item, 'merchant_price')
      input(type: 'number', name: 'value', min: 1, value: item.merchant_price, aria: { label: "Merchant price of #{item.name}" },
            class: 'w-20 border border-grey-400 rounded px-1 py-0.5 dark:bg-grey-700')
      button(type: 'submit', class: 'Button Button--sm Button--default') { 'Save' }
    end
  end

  def issue(item, issue)
    div(class: "mb-1 #{issue.note ? 'text-grey-500' : 'text-yellow-800 dark:text-yellow-300'}") do
      plain issue.message
      next unless issue.fixable?

      plain ' '
      button_to(issue.fix_label, adm_material_triage_path, method: :patch,
                params: { item_id: item.id, field: issue.field, value: issue.fix.to_s, show: show_param },
                class: 'Button Button--sm Button--default', form: { class: 'inline-block' })
    end
  end

  def hidden_fields(item, field)
    input(type: 'hidden', name: '_method', value: 'patch')
    input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
    input(type: 'hidden', name: 'item_id', value: item.id)
    input(type: 'hidden', name: 'field', value: field)
    input(type: 'hidden', name: 'show', value: show_param) if show_param
  end

  def show_param = @all ? 'all' : nil
end

# frozen_string_literal: true

# What gear components add by material and kind (see ComponentBonuses): a
# table per family of kinds, with each kind's captured bonus for each
# material, and how the families compare. For working out how to keep
# this, once it's clearer which kinds go together.
class Views::Adm::ComponentBonuses::Show < Views::Base

  def initialize(bonuses:)
    @bonuses = bonuses
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      div(class: 'p-4') do
        h1(class: 'text-2xl font-bold') { 'Component Bonuses' }
        intro
        coverage
        @bonuses.families.each { family(_1) }
        family_comparisons
      end
    end
  end

  private

  def intro
    div(class: 'my-2 max-w-prose text-sm') do
      p(class: 'mb-1') do
        plain "A component's kind is a group an archetype recipe takes, and its material the one its recipe "
        plain 'takes (or its name starts with). Kinds go together when their captured bonuses agree for at least '
        plain "#{ComponentBonuses::MIN_AGREEING} materials and disagree for none, so one captured tooltip covers "
        plain 'the whole family.'
      end
      p { 'Grey bonuses come from another kind in the family; a ? is one nobody has captured.' }
    end
  end

  def coverage
    items = @bonuses.kinds.flat_map(&:components).map(&:item).uniq
    counts = items.map { status(_1) }.tally
    p(class: 'mb-4 text-sm') do
      plain "#{items.size} components: "
      plain %w[ captured inferred unknown ].map { "#{counts.fetch(_1, 0)} #{_1}" }.join(', ')
      plain '.'
    end
  end

  def status(item)
    bonus = @bonuses.for_item(item)
    if bonus.nil? then 'unknown'
    elsif !bonus.inferred?(item) then 'captured'
    else 'inferred'
    end
  end

  def family(family)
    materials = family.kinds.flat_map { |k| k.components.map(&:material) }.uniq
    section(class: 'mb-6') do
      h2(class: 'text-lg font-bold') { family.kinds.map(&:name).to_sentence }
      table(class: 'table-auto w-full text-sm') do
        thead do
          tr(class: 'border-b-2 border-grey-400 text-left align-bottom') do
            th(class: 'pr-3') { 'Material' }
            family.kinds.each { |kind| th(class: 'pr-3') { kind.name } }
          end
        end
        tbody do
          materials.each do |material|
            tr(class: 'align-top border-b border-grey-200 dark:border-grey-700') do
              td(class: 'pr-3 py-1 whitespace-nowrap') { a(href: item_path(material), class: 'Link Link--primary') { material.name } }
              family.kinds.each { |kind| td(class: 'pr-3 py-1') { cell(kind, material) } }
            end
          end
        end
      end
    end
  end

  def cell(kind, material)
    component = kind.components.find { _1.material == material } or return plain('–')
    bonus = @bonuses.for_item(component.item)
    return span(class: 'text-grey-500') { '?' } unless bonus

    inferred = bonus.inferred?(component.item)
    div(class: inferred ? 'text-grey-500' : nil, title: inferred ? "From #{bonus.from.item.name}" : component.item.name) do
      bonus.lines.empty? ? em { 'none' } : bonus.lines.each { |line| div { line } }
    end
  end

  def family_comparisons
    same, different = @bonuses.family_comparisons.partition(&:same_stats?)
    section do
      h2(class: 'text-lg font-bold') { 'How families compare' }
      p(class: 'text-sm mb-1') do
        plain 'Each pair of families sharing captured materials, by the stats they add for them. Families '
        plain 'adding the same stats in other amounts may be one kind of part at different sizes.'
      end
      h3(class: 'font-semibold mt-2') { 'Same stats' }
      ul(class: 'list-disc ml-5 text-sm') { same.each { |comparison| li { same_stats(comparison) } } }
      h3(class: 'font-semibold mt-2') { 'Different stats' }
      ul(class: 'list-disc ml-5 text-sm') { different.each { |comparison| li { different_stats(comparison) } } }
    end
  end

  # Family names in bold, as a family's name lists its kinds.
  def same_stats(comparison)
    first, second = comparison.families
    case comparison.size
    when 'larger' then (strong { first.name }; plain ' adds more than '; strong { second.name })
    when 'equal' then (strong { first.name }; plain ' adds the same as '; strong { second.name })
    else (strong { first.name }; plain ' and '; strong { second.name }; plain ': some amounts larger, some smaller')
    end
    plain " (#{materials(comparison.materials.size)})"
  end

  def different_stats(comparison)
    first, second = comparison.families
    strong { first.name }
    plain ' and '
    strong { second.name }
    same = comparison.same_stats.size
    plain ": the same stats for #{same} of #{materials(comparison.materials.size)}" if same.positive?
  end

  def materials(count) = "#{count} #{'material'.pluralize(count)}"
end

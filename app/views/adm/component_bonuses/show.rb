# frozen_string_literal: true

# What gear components add by material and kind (see ComponentBonuses): a
# table per family of kinds, with each kind's captured bonus for each
# material, and the comparisons the families come from. For working out how
# to keep this, once it's clearer which kinds go together.
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
        agreements
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
        plain 'the whole family. Kinds with nothing captured are guessed to go with another; a captured bonus '
        plain 'that disagrees ends the guess.'
      end
      p { 'Grey bonuses come from another kind in the family; a ? is one nobody has captured.' }
    end
  end

  def coverage
    items = @bonuses.kinds.flat_map(&:components).map(&:item).uniq
    counts = items.map { status(_1) }.tally
    p(class: 'mb-4 text-sm') do
      plain "#{items.size} components: "
      plain %w[ captured inferred guessed unknown ].map { "#{counts.fetch(_1, 0)} #{_1}" }.join(', ')
      plain '.'
    end
  end

  def status(item)
    bonus = @bonuses.for_item(item)
    if bonus.nil? then 'unknown'
    elsif !bonus.inferred?(item) then 'captured'
    elsif bonus.guessed then 'guessed'
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
            family.kinds.each do |kind|
              th(class: 'pr-3') do
                plain kind.name
                span(class: 'ml-1 text-xs font-normal text-yellow-800 dark:text-yellow-300') { 'guess' } if family.guessed.include?(kind)
              end
            end
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

  def agreements
    comparisons = @bonuses.comparisons.select { _1.agree.any? }
    section do
      h2(class: 'text-lg font-bold') { 'Kinds that agree' }
      p(class: 'text-sm mb-1') { 'Each pair of kinds whose captured bonuses agree for some material. Every other pair sharing a captured material differs.' }
      ul(class: 'list-disc ml-5 text-sm') do
        comparisons.each do |comparison|
          li do
            plain "#{comparison.kinds.map(&:name).join(' and ')}: agree for #{comparison.agree.map(&:name).to_sentence}"
            plain "; differ for #{comparison.differ.map(&:name).to_sentence}" if comparison.differ.any?
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# For an archetype recipe ("Longsword"): every choice it offers, one table
# per group it takes, with what each choice adds to what's made (its
# crafting bonus, else any effects written for it) and what it costs the
# user (see ArchetypeOptions).
#
#   render Components::Recipes::Options.new(options: ArchetypeOptions.new(recipe, cost))
class Components::Recipes::Options < Components::Recipes::Base

  TH_CSS = "py-1 pr-4 text-left align-bottom"
  TD_CSS = "py-1 pr-4 align-top"

  def initialize(options:)
    @options = options
  end

  def render?
    @options.any?
  end

  def view_template
    section(class: "my-2") do
      h3(class: "font-bold") { "Options" }
      p(class: "mb-2") { summary }
      @options.slots.each { slot_table(_1) }
    end
  end

  private

  def summary
    slots = @options.slots
    if slots.one?
      "Choose one #{slots.first.group.name}: #{slots.first.choices.size} options."
    else
      "Choose one of each: #{slots.map { "#{_1.choices.size} #{_1.group.name}" }.join(' × ')}, " \
        "#{@options.combinations} combinations."
    end
  end

  def slot_table(slot)
    cheapest = slot.cheapest
    effects = slot.choices.any? { adds(_1.item).present? || _1.item.crafting_bonus_known? }
    div(class: "mt-3 font-semibold") do
      plain "#{slot.count} "
      link_to(slot.group.name, slot.group)
    end
    if slot.choices.empty?
      p { em(class: "text-grey-500") { "No members listed yet." } }
      return
    end

    table(class: "w-full table-auto text-sm") do
      thead do
        tr(class: "border-b-2 border-grey-300 dark:border-grey-600") do
          th(class: TH_CSS) { "Choice" }
          th(class: TH_CSS) { "Adds" } if effects
          th(class: "#{TH_CSS} text-right") { "Cost" } if @options.costed?
        end
      end
      tbody do
        slot.choices.each do |choice|
          tr(class: "border-t border-parchment-300 dark:border-grey-700") do
            td(class: "#{TD_CSS} whitespace-nowrap") do
              link_to(choice.item.name, choice.item)
              if choice.equal?(cheapest)
                whitespace
                flair_success("cheapest")
              end
            end
            td(class: TD_CSS) { effects_cell(choice.item) } if effects
            td(class: "#{TD_CSS} text-right whitespace-nowrap") { gold(choice.total) } if @options.costed?
          end
        end
      end
    end
  end

  def effects_cell(item)
    bonus = item.crafting_bonus
    if bonus.any?
      ul(class: "text-xs") { bonus.each { |line| li { line } } }
    elsif item.effects
      div(class: "text-xs") { formatted_body(item.effects) }
    elsif item.crafting_bonus_known?
      span(class: "text-grey-500") { "nothing" }
    else
      span(class: "text-xs text-grey-500") { "not captured yet" }
    end
  end

  def adds(item) = item.crafting_bonus.presence || item.effects

  def gold(amount)
    amount ? amount.round(2).to_s("F").delete_suffix(".0") : "-"
  end
end

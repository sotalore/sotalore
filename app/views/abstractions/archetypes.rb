# frozen_string_literal: true

# Archetypes by the craft skill whose recipes make them, with the groups those
# recipes call for: the choices that decide which one you get.
class Views::Abstractions::Archetypes < Views::Abstractions::Base

  private

  def kind = 'archetype'

  def intro
    p do
      plain "An "
      strong { "archetype" }
      plain " is a kind of crafted item, like a Dagger, where which one you get depends on "
      plain "the ingredients you use: a recipe for a Dagger made with a Bronze Dagger Blade "
      plain "makes a bronze dagger."
    end
    p do
      plain "They're listed by the crafting skill that makes them, along with the groups "
      plain "whose choice decides the result."
    end
  end

  def content
    by_skill.each do |skill, items|
      h3(class: "mt-4 mb-1 text-lg font-bold") do
        skill ? craft_skill_tag(skill, large: true) : plain("Not made by any recipe yet")
      end
      table(class: "w-full") do
        thead do
          tr(class: "border-b-2 border-grey-300 dark:border-grey-600") do
            th(class: "#{TH_CSS} w-1/3") { "Archetype" }
            th(class: TH_CSS) { "Choose from" }
          end
        end
        tbody do
          items.each do |item|
            tr(class: ROW_CSS) do
              td(class: "#{TD_CSS} font-semibold") { link_to(item.name, item) }
              td(class: TD_CSS) { choices_cell(choices(item, skill)) }
            end
          end
        end
      end
    end
  end

  # [ [skill or nil, [archetypes]] ], in craft skill order, then those no
  # recipe makes.
  def by_skill
    groups = Hash.new { |h, k| h[k] = [] }
    @items.each do |item|
      skills = recipes(item).map(&:craft_skill).uniq
      skills = [ nil ] if skills.empty?
      skills.each { groups[_1] << item }
    end
    order = CraftSkill::ALL
    groups.sort_by { |skill, _| skill ? order.index(skill) || order.size : order.size + 1 }
  end

  def recipes(item)
    item.recipes.reject(&:retired?)
  end

  def choices_cell(groups)
    if groups.empty?
      em(class: "text-grey-500") { "no groups" }
    else
      item_links(groups)
    end
  end

  def choices(item, skill)
    recipes(item).select { _1.craft_skill == skill }
                  .flat_map { |r| r.ingredients.map(&:item) }
                  .select(&:group?).uniq.sort_by(&:name)
  end

end

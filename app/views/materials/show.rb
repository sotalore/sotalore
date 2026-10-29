# frozen_string_literal: true

# How one family of materials is gathered and refined (see MaterialFamily):
# what's gathered, by skill; the common materials refined from it; the
# uncommon ones refined from those with an additive. Picking an item (a
# link, so one request) marks its path and shows it in full: its recipe,
# what one takes in gathered goods, what it's refined into, and what
# production does with it.
class Views::Materials::Show < Views::Base

  # +item+ is the one picked, if any; +bonuses+ what components add by
  # material (see ComponentBonuses), when it's a material.
  def initialize(family:, item:, bonuses:)
    @family = family
    @item = item
    @bonuses = bonuses
    @path = item ? family.path(item) : []
  end

  def view_template
    page_title("#{@family.name.capitalize} Materials")

    tile do
      tile_heading("Gathering and Refining") { render Views::Items::ItemNav.new }

      tile_body do
        intro
        family_tabs
        div(class: "grid grid-cols-1 lg:grid-cols-3 gap-4") do
          div(class: "lg:col-span-2 grid grid-cols-1 sm:grid-cols-3 gap-4") do
            column("Gathered") { gathered }
            column("Common") { @family.commons.each { |material| entry(material.item) { from_raw(material) } } }
            column("Uncommon") { @family.uncommons.each { |material| entry(material.item) { from_base(material) } } }
          end
          div { @item ? detail : p(class: "text-sm") { em { "Pick anything to trace its path." } } }
        end
      end
    end
  end

  private

  def intro
    p(class: "max-w-prose mb-2 text-sm") do
      plain "Gathering brings in the raw goods. Refining makes the common materials from them, and refining a "
      plain "common one again with an additive makes the uncommon ones. Production takes them from there."
    end
  end

  def family_tabs
    nav(class: "flex flex-row gap-4 mb-3 border-b border-grey-300 dark:border-grey-600") do
      Materials::FAMILIES.each_value do |family|
        current = family == @family.name
        a(href: materials_path(family:), aria: { current: current ? "page" : nil },
          class: current ? "pb-1 border-b-2 border-orange-600 font-semibold" : "pb-1 Link Link--primary") { family.capitalize }
      end
    end
  end

  def column(heading, &)
    section do
      h3(class: "font-semibold mb-1") { heading }
      ul(class: "space-y-2 text-sm", &)
    end
  end

  def gathered
    @family.by_skill.each do |gathering|
      li do
        div(class: "text-xs uppercase text-grey-600 dark:text-grey-300") { gathering.skill&.name || "Not seen gathered" }
        ul(class: "space-y-1") { gathering.items.each { |item| entry(item) { where_gathered(item) } } }
      end
    end
  end

  # One item to pick, marked when it's on the picked one's path.
  def entry(item, &)
    on_path = @path.include?(item)
    li(class: on_path ? "rounded bg-orange-100 dark:bg-orange-900 px-1" : "px-1") do
      a(href: materials_path(family: @family.name, item: item.id),
        class: item == @item ? "font-bold" : "Link Link--primary") { item.name }
      span(class: "ml-1 text-xs text-grey-600 dark:text-grey-300") { "additive" } if @family.additive?(item)
      div(class: "text-xs text-grey-600 dark:text-grey-300", &) if block_given?
    end
  end

  # Where it's gathered, for those who may see finds.
  def where_gathered(item)
    return unless policy(:finds).show?
    nodes, creatures = @family.sources(item).harvest_sources.partition { _1.is_a?(GatheringNode) }
    parts = nodes.map(&:name)
    parts << "#{creatures.size} #{'creature'.pluralize(creatures.size)}" if creatures.any?
    plain parts.join(", ")
  end

  def from_raw(material) = plain("from #{material.raw.map(&:name).to_sentence}")
  def from_base(material) = plain("#{material.base.name} + #{material.additives.map(&:name).join(' + ')}")

  def detail
    material = @family.materials.find(@item)
    section(class: "text-sm space-y-2") do
      h3(class: "text-lg font-semibold") { link_to(@item.name, @item) }
      material ? material_detail(material) : gathered_detail
    end
  end

  def material_detail(material)
    p do
      plain "#{material.tier.capitalize} #{material.family}, refined from "
      material.uncommon? ? (links([ material.base ]); plain(" with "); links(material.additives)) : links(material.raw)
      if (recipe = @family.materials.recipe_for(material))
        plain " by #{recipe.craft_skill.name}"
        plain " at level #{recipe.proficiency}" if recipe.proficiency
        plain " ("
        link_to("recipe", recipe_path(recipe))
        plain ")"
      end
      plain "."
    end
    takes = @family.materials.takes_per_unit(material)
    p { "One #{@item.name} takes #{takes.sort_by { |item, _| item.use_is_fuel? ? 1 : 0 }.map { |item, n| "#{count(n)} #{item.name}" }.to_sentence}." } if takes.any?
    uncommon = @family.materials.uncommon_of(material).map(&:item)
    p { plain "Uncommon versions: "; links(uncommon) } if uncommon.any?
    forms(material) if material.forms.any?
    production(material)
  end

  def forms(material)
    div do
      p { "Refined further into:" }
      ul(class: "list-disc ml-5") do
        material.forms.each do |form|
          li do
            link_to(form.name, form)
            groups = form.groups.to_a
            if groups.any?
              plain " (any "
              links(groups, " or ")
              plain ")"
            end
          end
        end
      end
    end
  end

  def production(material)
    counts = [ material.item, *material.forms ].map { ItemRoles.new(_1).production_counts }
                                               .reduce({}) { |all, counts| all.merge(counts) { |_, a, b| a + b } }
    if counts.any?
      p { "Production takes it, or its forms, in #{counts.map { |skill, n| "#{n} #{skill.name}" }.to_sentence} #{'recipe'.pluralize(counts.values.sum)}." }
    end
    bonuses = @bonuses&.for_material(@item) || []
    return if bonuses.empty?
    div do
      p { "What it adds to gear parts made from it:" }
      ul(class: "list-disc ml-5") do
        bonuses.each { |family, bonus| li { "#{family.name}: #{bonus.lines.join(', ')}" } }
      end
    end
  end

  def gathered_detail
    sources = @family.sources(@item)
    skills = sources.gathering_skills
    p { skills.any? ? "Gathered by #{skills.map(&:name).to_sentence}." : "Nobody has seen it gathered yet." }
    if policy(:finds).show?
      nodes, creatures = sources.harvest_sources.partition { _1.is_a?(GatheringNode) }
      p { plain "From "; links(nodes) } if nodes.any?
      p { plain "From creatures: "; links(creatures) } if creatures.any?
    end
    raw, additive = @family.materials.refined_into(@item).partition { _1.raw.include?(@item) }
    p { plain "Refined into "; links(raw.map(&:item)) } if raw.any?
    p { plain "An additive to "; links(additive.map(&:item)) } if additive.any?
  end

  def links(records, last = " and ")
    records.each_with_index do |record, i|
      plain(i == records.size - 1 ? last : ", ") if i.positive?
      link_to(record.name, record)
    end
  end

  def count(n) = n.denominator == 1 ? n.to_i : n.to_f.round(2)
end

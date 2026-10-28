# frozen_string_literal: true

# On an item page: where it stands among the crafting materials (see
# Materials). A material says its tier and family, what it's refined from
# and into; a form says what it's a form of; a raw good or additive says
# which materials it goes into. With +bonuses+ (see ComponentBonuses), a
# material also says what the components made from it add.
class Components::Items::Material < Components::Base

  def initialize(item:, materials:, bonuses: nil)
    @item = item
    @materials = materials
    @bonuses = bonuses
    @material = materials.find(item)
    @form_of = materials.form_of(item)
    @refined_into = materials.refined_into(item)
  end

  def render?
    @material || @form_of || @refined_into.any?
  end

  def view_template
    tile_with_heading("Material") do
      ul(class: "list-disc ml-5") do
        material if @material
        li { plain "A form of "; material_link(@form_of) } if @form_of
        refined_into if @refined_into.any?
      end
      crafting_bonuses if @material && @bonuses
    end
  end

  private

  def material
    li do
      plain "#{@material.tier.capitalize} #{@material.family}, refined from "
      if @material.uncommon?
        link_to(@material.base.name, @material.base)
        plain " with "
        links(@material.additives)
      else
        links(@material.raw)
      end
    end
    uncommon = @materials.uncommon_of(@material).map(&:item)
    li { plain "Uncommon versions: "; links(uncommon) } if uncommon.any?
    li { plain "Refined into "; links(@material.forms) } if @material.forms.any?
  end

  def crafting_bonuses
    bonuses = @bonuses.for_material(@item)
    return if bonuses.empty?

    h4(class: "mt-2 font-semibold") { "Crafting bonus" }
    ul(class: "list-disc ml-5 text-sm") do
      bonuses.each do |family, bonus|
        li do
          plain "#{family.name}: #{bonus.lines.join(', ')} ("
          link_to(bonus.from.item.name, bonus.from.item)
          plain ")"
        end
      end
    end
  end

  def refined_into
    raw, additive = @refined_into.partition { _1.raw.include?(@item) }
    li { plain "Refined into "; materials_links(raw) } if raw.any?
    li { plain "An additive to "; materials_links(additive) } if additive.any?
  end

  def material_link(material)
    link_to(material.item.name, material.item)
    plain " (#{material.tier} #{material.family})"
  end

  def materials_links(materials)
    materials.each_with_index do |material, i|
      plain(i == materials.size - 1 ? " and " : ", ") if i.positive?
      material_link(material)
    end
  end

  def links(items)
    items.each_with_index do |item, i|
      plain(i == items.size - 1 ? " and " : ", ") if i.positive?
      link_to(item.name, item)
    end
  end
end

# frozen_string_literal: true

# On an item page: what it's used for, from the recipes that take it,
# directly or as one of a group's items (see ItemRoles).
class Components::Items::Roles < Components::Base

  def initialize(roles:)
    @roles = roles
  end

  def render?
    @roles.kinds.any?
  end

  def view_template
    tile_with_heading("Used For") do
      ul(class: "list-disc ml-5") do
        li { counts("Refining", @roles.refining_counts) } if @roles.refining?
        li { counts("Production", @roles.production_counts) } if @roles.production?
        li { "A tool, by its tooltip" } if @roles.tool?
      end
      through if @roles.through.any?
    end
  end

  private

  def counts(label, counts)
    plain "#{label}: "
    plain counts.map { |skill, n| "#{skill.name} (#{n})" }.join(", ")
  end

  def through
    p(class: "mt-1 text-sm") do
      plain "Counting recipes that take any "
      @roles.through.each_with_index do |through, i|
        plain(i == @roles.through.size - 1 ? " or " : ", ") if i.positive?
        link_to(through.group.name, through.group)
        plain " (#{through.count})"
      end
      plain "."
    end
  end
end

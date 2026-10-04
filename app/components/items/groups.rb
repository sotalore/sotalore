# frozen_string_literal: true

# On an item page: the members of a group (the complete set it stands for),
# shown in place of salvage info since groups can't be salvaged; the examples
# of a category; or, for a concrete item, the groups and categories it
# belongs to. Archetypes have none. Editable by those who can edit items.
class Components::Items::Groups < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(item:)
    @item = item
  end

  def view_template
    if @item.group?
      p { "Any of these can be used where a recipe calls for #{@item.name}." }
      members_list("No members yet.", "add an item to this group...")
    elsif @item.category?
      p { "Some examples of #{@item.name}. There are likely others." }
      members_list("No examples yet.", "add an example...")
    elsif @item.concrete?
      memberships
    end
  end

  private

  def editable?
    policy(@item).edit?
  end

  def members_list(empty, placeholder)
    memberships = @item.member_memberships.includes(:member).sort_by { _1.member.name }
    if memberships.empty?
      p { em { empty } }
    else
      ul(class: 'flex flex-row flex-wrap gap-x-4 gap-y-2') do
        memberships.each do |membership|
          li do
            link_to(membership.member.name, membership.member)
            if editable?
              whitespace
              destroy_icon_to(item_membership_path(membership), size: :small,
                              data: { turbo_confirm: "Remove #{membership.member.name} from #{@item.name}?" })
            end
          end
        end
      end
    end
    add_form(:member, placeholder) if editable?
  end

  # For a concrete item: the groups it's a member of, and the categories it's
  # an example of.
  def memberships
    all = @item.group_memberships.includes(:group).sort_by { _1.group.name }
    return if all.empty? && !editable?

    categories, groups = all.partition { _1.group.category? }
    div(class: "mt-2") do
      section("Member of", groups) if groups.any? || categories.empty?
      section("Example of", categories) if categories.any?
      add_form(:group, "add to a group or category...") if editable?
    end
  end

  def section(title, memberships)
    div do
      strong { "#{title}:" }
      whitespace
      if memberships.empty?
        em { "nothing yet" }
      else
        memberships.each_with_index do |membership, i|
          plain ", " if i.positive?
          link_to(membership.group.name, membership.group)
          remove_button(membership) if editable?
        end
      end
    end
  end

  def remove_button(membership)
    button_to(item_membership_path(membership), method: :delete,
              class: "inline-flex align-middle text-red-600", title: "remove",
              form: { class: "inline", data: { turbo_confirm: "Remove from #{membership.group.name}?" } }) do
      render_icon(:trash, size: :sm)
    end
  end

  def add_form(field, placeholder)
    own_field = field == :member ? :group_id : :member_id
    form(action: item_memberships_path, method: "post", class: "mt-1 flex flex-row items-start gap-2") do
      input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
      input(type: "hidden", name: "item_membership[#{own_field}]", value: @item.id)
      div(class: "grow", data: { controller: "autocomplete", "autocomplete-url-value": search_items_path }) do
        input(type: "text", class: "field-input", name: "item_membership[#{field}_name]",
              placeholder: placeholder, data: { "autocomplete-target": "input" })
        input(type: "hidden", name: "item_membership[#{field}_id]", data: { "autocomplete-target": "hidden" })
        ul(class: "autocomplete-suggestions", data: { "autocomplete-target": "results" })
      end
      button(type: "submit", class: "Button Button--sm Button--default") { "Add" }
    end
  end
end

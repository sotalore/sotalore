# frozen_string_literal: true

# On an item page: the members of a group (abstract item), shown in place of
# salvage info since groups can't be salvaged; or, for a concrete item, the
# groups it belongs to. Editable by those who can edit items.
class Components::Items::Groups < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(item:)
    @item = item
  end

  def view_template
    if @item.abstract?
      members_list
    elsif @item.group_memberships.any? || editable?
      section("Member of", nil,
              @item.group_memberships.includes(:group).sort_by { _1.group.name }, :group,
              field: :group, placeholder: "add to a group...")
    end
  end

  private

  def editable?
    policy(@item).edit?
  end

  def members_list
    memberships = @item.member_memberships.includes(:member).sort_by { _1.member.name }
    p { "Any of these can be used where a recipe calls for #{@item.name}." }
    if memberships.empty?
      p { em { "No members yet." } }
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
    add_form(:member, "add an item to this group...") if editable?
  end

  def section(title, hint, memberships, other, field:, placeholder:)
    div(class: "mt-2") do
      strong { "#{title}:" }
      whitespace
      if memberships.empty?
        em { "nothing yet" }
      else
        memberships.each_with_index do |membership, i|
          plain ", " if i.positive?
          item = membership.public_send(other)
          link_to(item.name, item)
          remove_button(membership) if editable?
        end
      end
      p(class: "text-sm text-grey-600 dark:text-grey-300") { hint } if hint
      add_form(field, placeholder) if editable?
    end
  end

  def remove_button(membership)
    button_to(item_membership_path(membership), method: :delete,
              class: "inline-flex align-middle text-red-600", title: "remove",
              form: { class: "inline", data: { turbo_confirm: "Remove from group?" } }) do
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

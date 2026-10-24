# frozen_string_literal: true

# A collection: what it is, where it sits, what's inside it, and every item
# it holds, counting those of the collections inside it.
class Views::Collections::Show < Views::Base

  # +items+: { item => [ collections it's listed in ] } (see Collection#all_items)
  def initialize(collection:, items:)
    @collection = collection
    @items = items
  end

  def view_template
    page_title(@collection.name)
    tile do
      tile_heading(@collection.name) do
        destroy_button_to("Delete", @collection) if policy(@collection).destroy?
        edit_button_to("Edit", edit_collection_path(@collection)) if editable?
      end
      tile_body do
        breadcrumbs
        formatted_body(@collection.description)
        inside
        items_section
      end
    end
  end

  private

  def editable? = policy(@collection).update?

  def breadcrumbs
    parents = @collection.parents.to_a
    p(class: "text-sm mb-2") do
      link_to("Collections", collections_path)
      if parents.any?
        plain " · inside "
        parents.each_with_index do |parent, i|
          plain ", " if i.positive?
          link_to(parent.name, parent)
        end
      end
    end
  end

  def inside
    children = @collection.children.to_a
    return if children.empty? && !editable?

    div(class: "my-2") do
      strong { "Contains: " }
      if children.empty?
        em { "no other collections" }
      else
        children.each_with_index do |child, i|
          plain ", " if i.positive?
          link_to(child.name, child)
        end
      end
      if editable?
        whitespace
        link_to("add one", new_collection_path(parent_id: @collection.id), class: "text-sm")
      end
    end
  end

  def items_section
    h3(class: "mt-4 font-bold") { pluralize(@items.size, "Item") }
    if @items.empty?
      p { em { "No items yet." } }
    else
      items_table
    end
    add_form if editable?
  end

  def items_table
    via_others = @items.values.flatten.uniq != [ @collection ]
    table(class: "w-full table-auto text-sm") do
      thead do
        tr(class: "border-b-2 border-grey-300 dark:border-grey-600") do
          th(class: "py-1 pr-4 text-left") { "Item" }
          th(class: "py-1 pr-4 text-left") { "Use" }
          th(class: "py-1 pr-4 text-left") { "Listed in" } if via_others
          th if editable?
        end
      end
      tbody do
        @items.each do |item, collections|
          tr(class: "border-t border-parchment-300 dark:border-grey-700 align-top") do
            td(class: "py-1 pr-4") do
              link_to(item.name, item)
              whitespace
              item_abstract_tag(item)
            end
            td(class: "py-1 pr-4") { item_use_tag(item, hide_unknown: true) }
            td(class: "py-1 pr-4") { listed_in(collections) } if via_others
            td(class: "py-1 text-right") { remove_button(item) } if editable?
          end
        end
      end
    end
  end

  def listed_in(collections)
    collections.reject { _1 == @collection }.each_with_index do |collection, i|
      plain ", " if i.positive?
      link_to(collection.name, collection)
    end
  end

  # Only items listed here directly can be taken out here.
  def remove_button(item)
    entry = @collection.collection_items.find { _1.item_id == item.id }
    return unless entry

    button_to(collection_item_path(entry), method: :delete, class: "inline-flex text-red-600", title: "remove",
              form: { class: "inline", data: { turbo_confirm: "Remove #{item.name} from #{@collection.name}?" } }) do
      render_icon(:trash, size: :sm)
    end
  end

  def add_form
    form(action: collection_items_path, method: "post", class: "mt-2 flex flex-row items-start gap-2 max-w-md") do
      input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
      input(type: "hidden", name: "collection_item[collection_id]", value: @collection.id)
      div(class: "grow", data: { controller: "autocomplete", "autocomplete-url-value": search_items_path }) do
        input(type: "text", class: "field-input", name: "collection_item[item_name]",
              placeholder: "add an item...", data: { "autocomplete-target": "input" })
        input(type: "hidden", name: "collection_item[item_id]", data: { "autocomplete-target": "hidden" })
        ul(class: "autocomplete-suggestions", data: { "autocomplete-target": "results" })
      end
      button(type: "submit", class: "Button Button--sm Button--default") { "Add" }
    end
  end

end

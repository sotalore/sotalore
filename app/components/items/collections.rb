# frozen_string_literal: true

# On an item page: the collections it's listed in (see Collection), and
# those they're inside, which hold it too. Editors can list it in another
# or take it out.
#
#   render Components::Items::Collections.new(item: item, choices: Collection.by_name)
class Components::Items::Collections < Components::Base

  # +choices+ are the collections it could be added to.
  def initialize(item:, choices:)
    @item = item
    @choices = choices
  end

  def render?
    @item.collection_items.any? || (editable? && @choices.any?)
  end

  def view_template
    entries = @item.collection_items.includes(:collection).sort_by { _1.collection.name }
    div(class: "mt-2") do
      strong { "Collections:" }
      whitespace
      if entries.empty?
        em { "none yet" }
      else
        entries.each_with_index do |entry, i|
          plain ", " if i.positive?
          link_to(entry.collection.name, entry.collection)
          remove_button(entry) if editable?
        end
        also_in(entries.map(&:collection))
      end
      add_form(entries.map(&:collection_id)) if editable?
    end
  end

  private

  def editable? = policy(Collection).update?

  def also_in(collections)
    map = Collection.parents_map
    listed = collections.map(&:id)
    ancestors = Collection.where(id: collections.flat_map { _1.ancestor_ids(map) } - listed).by_name.to_a
    return if ancestors.empty?

    span(class: "text-sm text-grey-600 dark:text-grey-300") do
      plain " (so also "
      ancestors.each_with_index do |collection, i|
        plain ", " if i.positive?
        link_to(collection.name, collection)
      end
      plain ")"
    end
  end

  def remove_button(entry)
    button_to(collection_item_path(entry), method: :delete, class: "inline-flex align-middle text-red-600",
              title: "remove",
              form: { class: "inline", data: { turbo_confirm: "Remove from #{entry.collection.name}?" } }) do
      render_icon(:trash, size: :sm)
    end
  end

  def add_form(listed_ids)
    choices = @choices.reject { listed_ids.include?(_1.id) }
    return if choices.empty?

    form(action: collection_items_path, method: "post", class: "mt-1 flex flex-row items-center gap-2") do
      input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
      input(type: "hidden", name: "collection_item[item_id]", value: @item.id)
      select(name: "collection_item[collection_id]", class: "field-input", aria: { label: "Collection" }) do
        option(value: "") { "add to a collection..." }
        choices.each { |collection| option(value: collection.id) { collection.name } }
      end
      button(type: "submit", class: "Button Button--sm Button--default") { "Add" }
    end
  end
end

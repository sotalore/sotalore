# frozen_string_literal: true

# Layout for the abstract item tabs: one per kind (see Item::ITEM_KINDS), each
# with its own explanation and design.
class Views::Abstractions::Base < Views::Base

  TABS = {
    'group'     => [ 'Groups', :groups_abstractions_path ],
    'category'  => [ 'Categories', :categories_abstractions_path ],
    'archetype' => [ 'Archetypes', :archetypes_abstractions_path ],
  }.freeze

  TH_CSS = "py-1 pr-4 text-left align-bottom"
  TD_CSS = "py-1.5 pr-4 align-top"
  ROW_CSS = "border-b border-grey-200 dark:border-grey-700"

  def initialize(items:, counts:)
    @items = items
    @counts = counts
  end

  def view_template
    page_title("#{TABS[kind].first} - Abstract Items")

    div(class: "mx-2 mt-2 mb-12") do
      div(class: "flex flex-col md:flex-row md:justify-between md:items-end") do
        div(class: "PageTabs") { TABS.each_key { tab(_1) } }
        div(class: "pb-2") { new_button_to("New Item", new_item_path) } if policy(Item).edit?
      end

      div(class: "bg-white dark:bg-grey-800 p-2 md:p-4") do
        div(class: "Callout Callout-primary max-w-prose") { intro }
        if @items.empty?
          p { em { "None yet." } }
        else
          content
        end
      end
    end
  end

  private

  def tab(tab_kind)
    label, path = TABS.fetch(tab_kind)
    text = "#{label} (#{@counts[tab_kind].to_i})"
    if tab_kind == kind
      span(class: "PageTabs-tab PageTabs-current", aria: { current: "page" }) { text }
    else
      a(href: send(path), class: "PageTabs-tab") { text }
    end
  end

  def item_links(items)
    items.each_with_index do |item, i|
      plain ", " if i.positive?
      link_to(item.name, item)
    end
  end

  # Name and members (or examples) of groups or categories.
  def members_table(heading, limit: nil)
    table(class: "w-full") do
      thead do
        tr(class: "border-b-2 border-grey-300 dark:border-grey-600") do
          th(class: "#{TH_CSS} w-1/3") { "Name" }
          th(class: TH_CSS) { heading }
        end
      end
      tbody do
        @items.each do |item|
          tr(class: ROW_CSS) do
            td(class: "#{TD_CSS} font-semibold") { link_to(item.name, item) }
            td(class: TD_CSS) { members_cell(item, limit) }
          end
        end
      end
    end
  end

  def members_cell(item, limit)
    members = item.members.to_a
    if members.empty?
      em(class: "text-grey-500") { "none yet" }
      return
    end
    shown = limit ? members.first(limit) : members
    item_links(shown)
    if shown.size < members.size
      plain ", "
      link_to("and #{members.size - shown.size} more", item)
    end
  end

end

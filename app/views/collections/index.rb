# frozen_string_literal: true

# Every collection, as a tree: those inside no other at the top, each with
# what's inside it. One inside several shows up under each.
class Views::Collections::Index < Views::Base

  # +item_counts+: { collection id => items, counting those inside }
  def initialize(collections:, item_counts:)
    @collections = collections
    @item_counts = item_counts
  end

  def view_template
    page_title("Collections")
    tile do
      tile_heading("Collections") do
        new_button_to("New Collection", new_collection_path) if policy(Collection).new?
      end
      tile_body do
        p(class: "max-w-prose mb-2") do
          plain "Ways of grouping items to answer questions like \"what are the heavy armors?\". "
          plain "A collection can sit inside others, and holds everything inside it."
        end
        top = @collections.reject { |c| child_ids.include?(c.id) }
        if top.empty?
          p { em { "None yet." } }
        else
          tree(top, Set.new)
        end
      end
    end
  end

  private

  def child_ids
    @child_ids ||= @collections.flat_map(&:child_ids).to_set
  end

  # +seen+ guards against a loop, which links never allow but a tree must
  # never follow round.
  def tree(collections, seen)
    ul(class: seen.empty? ? "space-y-1" : "ml-6 mt-1 space-y-1") do
      collections.each do |collection|
        li do
          link_to(collection.name, collection, class: "Link Link--primary font-semibold")
          span(class: "text-sm text-grey-600 dark:text-grey-300") { " #{pluralize(@item_counts[collection.id].to_i, 'item')}" }
          children = collection.children.reject { seen.include?(_1.id) }
          tree(children, seen + [ collection.id ]) if children.any?
        end
      end
    end
  end

end

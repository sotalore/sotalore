# frozen_string_literal: true

# On a scene page: what can be found there, rarest first (found in the
# fewest scenes), its creatures and its gathering nodes.
class Components::Finds::ForScene < Components::Base

  # Items found in at most this many scenes are worth pointing out.
  RARE = 3

  def initialize(scene:)
    @scene = scene
    @items = scene.found_items.to_a
    @spread = SceneFind.where(item_id: @items.map(&:id)).group(:item_id).count
    @items.sort_by! { [ @spread[_1.id], _1.name ] }
    @creatures = scene.scene_creatures.includes(:creature).sort_by { _1.creature.name }
    @nodes = scene.gathering_nodes.to_a
  end

  def render?
    @items.any? || @creatures.any? || @nodes.any?
  end

  def view_template
    tile_with_heading("Found Here", class: "col-span-6") do
      if @creatures.any?
        p do
          strong { "Creatures: " }
          @creatures.each_with_index do |link, i|
            plain ", " if i.positive?
            link_to(link.creature.name, link.creature)
            plain " (#{link.levels})" if link.levels
          end
        end
      end
      if @nodes.any?
        p do
          strong { "Gathering: " }
          @nodes.each_with_index do |node, i|
            plain ", " if i.positive?
            link_to(node.name, node)
          end
        end
      end
      items_list if @items.any?
    end
  end

  private

  def items_list
    p(class: "mt-2") { strong { "Items, rarest first:" } }
    ul(class: "flex flex-row flex-wrap gap-x-4 gap-y-1") do
      @items.each do |item|
        scenes = @spread[item.id]
        li do
          link_to(item.name, item, class: (scenes <= RARE ? "font-bold" : nil))
          span(class: "text-xs text-grey-500") { " #{scenes == 1 ? 'only here' : "in #{scenes} scenes"}" }
        end
      end
    end
  end
end

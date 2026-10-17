# frozen_string_literal: true

# On an item page: the scenes it can be found in, and the creatures (field
# dressing) and gathering nodes that give it.
class Components::Finds::ForItem < Components::Base

  def initialize(item:)
    @item = item
    @scenes = item.found_in_scenes.to_a
    yields = HarvestYield.where(item: item).includes(:source).map(&:source)
    @creatures = yields.grep(Creature).sort_by(&:name)
    @nodes = yields.grep(GatheringNode).sort_by(&:name)
  end

  def render?
    @scenes.any? || @creatures.any? || @nodes.any?
  end

  def view_template
    tile_with_heading("Where to Find It") do
      if @scenes.any?
        p do
          plain "Found in #{@scenes.size} #{'scene'.pluralize(@scenes.size)}: "
          links(@scenes)
        end
      end
      if @creatures.any?
        p do
          plain "Field dressing gives it from: "
          links(@creatures)
        end
      end
      if @nodes.any?
        p do
          plain "Gathered from: "
          links(@nodes)
        end
      end
    end
  end

  private

  def links(records)
    records.each_with_index do |record, i|
      plain ", " if i.positive?
      link_to(record.name, record)
    end
  end
end

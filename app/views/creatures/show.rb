# frozen_string_literal: true

# A creature or gathering node: the scenes it's in, and what gathering from
# it (field dressing, harvesting) gives. +links+ are SceneCreatures (with
# levels) or SceneNodes.
class Views::Creatures::Show < Views::Base

  def initialize(record:, links:)
    @record = record
    @links = links
  end

  def view_template
    page_title(@record.name)
    creature = @record.is_a?(Creature)
    tile do
      tile_heading(@record.name) do
        node_buttons unless creature
        default_button_to("All", creature ? creatures_path : gathering_nodes_path)
      end
      tile_body do
        skill_line unless creature
        p { formatted_body(@record.notes) } if @record.notes.present?
        h3(class: "font-bold mt-2") { creature ? "Lives in" : "Found in" }
        if @links.empty?
          p { em { "nowhere yet" } }
        else
          ul do
            @links.each do |link|
              li do
                link_to(link.scene.name, link.scene)
                plain " (level #{link.levels})" if link.respond_to?(:levels) && link.levels
              end
            end
          end
        end
        h3(class: "font-bold mt-2") { creature ? "Field dressing gives" : "Harvesting gives" }
        if @record.yields.empty?
          p { em { "nothing recorded yet" } }
        else
          ul(class: "flex flex-row flex-wrap gap-x-4") { @record.yields.each { |item| li { link_to(item.name, item) } } }
        end
      end
    end
  end

  private

  def skill_line
    p do
      plain "Gathered by "
      if @record.gathering_skill
        strong { @record.gathering_skill.name }
      else
        em(class: "text-red-700 dark:text-red-400") { "skill not set" }
      end
    end
  end

  # Editing, and moving a creature recorded as a node to the creatures.
  def node_buttons
    if policy(@record).move_to_creatures?
      default_button_to("Move to creatures", move_to_creatures_gathering_node_path(@record),
                        method: :post, data: { turbo_confirm: "Make #{@record.name} a creature, with its scenes and what it gives?" })
    end
    edit_button_to("Edit", edit_gathering_node_path(@record)) if policy(@record).edit?
  end
end

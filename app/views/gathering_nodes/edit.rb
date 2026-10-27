# frozen_string_literal: true

# Which skill gathers from a node, and notes about it.
class Views::GatheringNodes::Edit < Views::Form

  def initialize(node:)
    @node = node
  end

  def view_template
    page_title("Edit #{@node.name}")
    tile_with_heading("Edit #{@node.name}") do
      render form_builder(model: @node) do |f|
        f.select_field(:gathering_skill, value: @node.gathering_skill&.key,
                                         hint: "The skill that gathers from it. A creature is field dressed; move it to the creatures instead.") do |select|
          select.options(GatheringNode.skills, display: :name, value: :key, include_blank: :blank)
        end
        f.text_area_field(:notes, optional: true)
        f.form_actions do
          f.cancel_button
          f.submit_button
        end
      end
    end
  end

end

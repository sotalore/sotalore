# frozen_string_literal: true

# A recipe's card on its own, for the frame under an ingredient that shows
# one of its recipes (Components::Recipes::Card) when +frame_id+ is given.
class Views::Recipes::ShowPartial < Views::Base

  def initialize(recipe:, frame_id: nil)
    @recipe = recipe
    @frame_id = frame_id
  end

  def view_template
    if @frame_id
      turbo_frame_tag(@frame_id) { card }
    else
      card
    end
  end

  private

  def card
    render Components::Recipes::Card.new(recipe: @recipe)
  end

end

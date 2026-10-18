# frozen_string_literal: true

# For admin import controllers whose imports include GameItemResolution:
# creating the unknown items selected on the review page (see
# Components::Imports::UnknownItems).
module ResolvesGameItems
  private

  # Creates the selected items (+selected+, JSON { name:, key: } each),
  # putting any failures in the flash. Returns the notice.
  def create_selected_items(import)
    selected = Array(params[:selected]).filter_map do |json|
      JSON.parse(json)
    rescue JSON::ParserError
      nil
    end
    raise GameItemResolution::Error, 'Select the items to create.' if selected.empty?
    created, failed = import.create_items!(selected)
    flash[:alert] = "Couldn't create #{failed.to_sentence}." if failed.any?
    "Created #{created.size} #{'item'.pluralize(created.size)}."
  end

  # The open list section to come back to.
  def open_section
    params[:open].presence
  end
end

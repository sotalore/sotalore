# frozen_string_literal: true

class Views::Verifications::Controls < Views::Base

  register_output_helper :verify_button

  def initialize(verifiable)
    @verifiable = verifiable
  end

  def view_template
    return unless policy(:verification).index?

    div(class: 'px-4 inline-flex flex-row items-center gap-4 justify-end') do
      span(class: 'font-bold') { 'Last Verified:' }
      if @verifiable.verified?
        span(class: 'text-grey-500 font-bold') { l(@verifiable.last_verified_at, format: :long) }
      else
        span(class: 'text-red-600 font-bold') { 'Never' }
      end
      verify_button(@verifiable)
      a(href: relevant_collection_path, class: 'link') { 'all' }
    end
  end

  private

  def relevant_collection_path
    case @verifiable
    when Item
      item_verifications_path
    when Recipe
      recipe_verifications_path
    end
  end


end

# frozen_string_literal: true

class Views::Authentication::Base < Views::Base
  include Views::TurnstileHelper

  def auth_columns(&block)
    div(class: "flex flex-col md:flex-row gap-x-4 justify-center", &block)
  end

  def auth_card(heading, &block)
    div(class: "my-4 bg-white border border-grey-300 rounded p-4") do
      h3(class: "py-2 border-b border-grey-300 text-2xl m-0 mb-4") { heading }
      yield
    end
  end

  def auth_message_card(&block)
    div(class: "my-4 bg-white border border-grey-300 rounded p-4 text-center", &block)
  end

end

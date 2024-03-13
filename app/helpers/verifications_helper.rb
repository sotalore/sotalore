# frozen_string_literal: true

module VerificationsHelper

  def verify_button(verifiable)
    tag.div(class: 'inline-block') do
      button_to('Verify', verify_path(verifiable), class: 'Button Button-default', method: :patch)
    end
  end
end

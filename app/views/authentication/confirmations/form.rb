# frozen_string_literal: true

class Views::Authentication::Confirmations::Form < Views::Authentication::Base
  include Grav::Views::Forms::Base

  def initialize(user:)
    super(model: user)
  end

  def form_action
    user_confirmation_path
  end

  def view_template
    super do
      email_field(:email, hint: "The email you registered with.")

      div(class: "flex flex-row justify-around") do
        submit_button("Send Confirmation Instructions")
      end
    end
  end

end

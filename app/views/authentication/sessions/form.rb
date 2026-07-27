# frozen_string_literal: true

class Views::Authentication::Sessions::Form < Views::Authentication::Base
  include Grav::Views::Forms::Base

  def initialize(user:)
    super(model: user)
  end

  def form_action
    user_session_path
  end

  def view_template
    super do
      email_field(:email, hint: "")
      password_field(:password, autocomplete: "off", hint: "")

      div(class: "flex flex-row justify-around") do
        submit_button("Sign In", class: "text-xl px-4 py-2 rounded-lg")
      end
    end
  end

end

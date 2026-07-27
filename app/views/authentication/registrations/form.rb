# frozen_string_literal: true

class Views::Authentication::Registrations::Form < Views::Authentication::Base
  include Grav::Views::Forms::Base

  def initialize(user:)
    super(model: user, data: { turbo: "false" })
  end

  def form_action
    user_registration_path
  end

  def view_template
    super do
      email_field(:email, autofocus: true, required: true)
      text_field(:name, required: true)
      password_field(:password)
      password_field(:password_confirmation)

      div(class: "flex flex-row justify-around my-4") { turnstile_tag }
      div(class: "flex flex-row justify-around") do
        submit_button("Register for SotA Lore!", class: "text-xl px-4 py-2 rounded-lg")
      end
    end
  end

end

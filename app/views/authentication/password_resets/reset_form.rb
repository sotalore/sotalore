# frozen_string_literal: true

class Views::Authentication::PasswordResets::ResetForm < Views::Authentication::Base
  include Grav::Views::Forms::Base

  def initialize(password_reset_form:, token:)
    @token = token
    super(model: password_reset_form)
  end

  def form_action
    user_password_reset_path
  end

  def view_template
    super do
      input(type: "hidden", name: "token", value: @token, autocomplete: "off")

      password_field(:password, hint: "At least 8 characters.")
      password_field(:password_confirmation, hint: "Must match the password above.")

      div(class: "flex flex-row justify-around") do
        submit_button("Change Password")
      end
    end
  end

end

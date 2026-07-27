# frozen_string_literal: true

class Views::Authentication::PasswordResets::Edit < Views::Authentication::Base

  def initialize(password_reset_form:, token:)
    @password_reset_form = password_reset_form
    @token = token
  end

  def view_template
    auth_columns do
      div(class: "basis-full md:basis-1_2 lg:basis-1_3") do
        auth_card("Set New Password") do
          render Views::Authentication::PasswordResets::ResetForm.new(password_reset_form: @password_reset_form, token: @token)

          div(class: "mt-8 flex flex-col gap-1") do
            p(class: "text-center") { link_to "Need to sign in?", new_user_session_path }
          end
        end
      end
    end
  end

end

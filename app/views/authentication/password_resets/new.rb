# frozen_string_literal: true

class Views::Authentication::PasswordResets::New < Views::Authentication::Base

  def initialize(user:)
    @user = user
  end

  def view_template
    auth_columns do
      div(class: "basis-full md:basis-1_2 lg:basis-1_3") do
        auth_card("Reset Your Password") do
          render Views::Authentication::PasswordResets::RequestForm.new(user: @user)

          div(class: "mt-8 flex flex-col gap-2") do
            div(class: "text-center") { link_to "Need to confirm your account?", new_user_confirmation_path }
            div(class: "text-center") { link_to "Need to sign in?", new_user_session_path }
            div(class: "text-center") { link_to "Need to create an account?", new_user_registration_path }
          end
        end
      end
    end
  end

end

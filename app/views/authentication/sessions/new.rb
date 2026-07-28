# frozen_string_literal: true

class Views::Authentication::Sessions::New < Views::Authentication::Base

  def initialize(user:)
    @user = user
  end

  def view_template
    auth_columns do
      div(class: "basis-full md:basis-1_2 lg:basis-1_3 order-2 md:order-1") do
        auth_card("Sign In with Email") do
          render Views::Authentication::Sessions::Form.new(user: @user)

          div(class: "flex flex-col gap-2 my-4") do
            div(class: "text-center") { link_to "Forgot your password?", new_user_password_reset_path }
            div(class: "text-center") { link_to "Need to confirm your account?", new_user_confirmation_path }
            div(class: "text-center") { link_to "Need to create an account?", new_user_registration_path }
          end
        end
      end

      div(class: "basis-full md:basis-1_2 lg:basis-1_3 order-1 md:order-2") do
        auth_card("Sign In with Provider") do
          render Components::Authentication::DiscordButton.new
        end
      end
    end
  end

end

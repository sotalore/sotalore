# frozen_string_literal: true

class Views::Authentication::Registrations::New < Views::Authentication::Base

  def initialize(user:)
    @user = user
  end

  def view_template
    auth_columns do
      div(class: "basis-full lg:basis-2_3") do
        notice_info do
          div(class: "p-4 text-xl") do
            plain "Registering allows you to leave comments on things as well as " \
                  "saving your skill levels for your avatars."
          end
        end
      end
    end

    auth_columns do
      div(class: "basis-full md:basis-1_2 lg:basis-1_3 order-2 md:order-1") do
        auth_card("Register with Email") do
          render Views::Authentication::Registrations::Form.new(user: @user)

          div(class: "flex flex-col gap-2 my-8") do
            div(class: "text-center") { link_to "Need to sign in?", new_user_session_path }
            div(class: "text-center") { link_to "Forgot your password?", new_user_password_reset_path }
            div(class: "text-center") { link_to "Need to confirm your account?", new_user_confirmation_path }
          end
        end
      end

      div(class: "basis-full md:basis-1_2 lg:basis-1_3 order-1 md:order-2") do
        auth_card("Register with Provider") do
          render Components::Authentication::DiscordButton.new
        end
      end
    end
  end

end

# frozen_string_literal: true

class Views::Authentication::Registrations::NeedConfirmation < Views::Authentication::Base

  def view_template
    auth_columns do
      div(class: "basis-full md:basis-2_3") do
        auth_message_card do
          h1(class: "text-slorange-700") { "Thank you for registering!" }

          p(class: "text-2xl p-4") { "We've sent you an email to confirm your account. You should receive it within a few minutes." }
          p(class: "text-2xl p-4") { "Please check your email and click the link provided to confirm your account." }
          p(class: "pb-4") { link_to "Resend the confirmation email?", new_user_confirmation_path }
        end
      end
    end
  end

end

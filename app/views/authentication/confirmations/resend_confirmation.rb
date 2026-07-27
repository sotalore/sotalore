# frozen_string_literal: true

class Views::Authentication::Confirmations::ResendConfirmation < Views::Authentication::Base

  def view_template
    auth_columns do
      div(class: "basis-full md:basis-2_3") do
        auth_message_card do
          h1 { "Sending Confirmation Email" }

          p(class: "text-2xl p-4") { "We've sent you an email to confirm your account. You should receive it within a few minutes." }
          p(class: "text-2xl p-4") { "Please check your email and click the link provided to confirm your account." }
        end
      end
    end
  end

end

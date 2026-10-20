# frozen_string_literal: true

module Views::TurnstileHelper

  def require_turnstile?
    Current.user.null?
  end

  def turnstile_tag
    div(class: "mx-2", data: { controller: 'turnstile', turnstile_sitekey_value: CloudflareTurnstile.site_key })
  end

end

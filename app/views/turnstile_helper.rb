# frozen_string_literal: true

module Views::TurnstileHelper

  def require_turnstile?
    Current.user.null?
  end

  def turnstile_tag
    data_attr = { sitekey: CloudflareTurnstile.site_key, theme: 'light', controller: 'turnstile' }
    div(class: "cf-turnstile mx-2", data: data_attr)
  end

end

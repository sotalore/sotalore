module TurnstileHelper
  def require_turnstile?
    current_user.null?
  end

  def turnstile_tag
    data_attr = { sitekey: CloudflareTurnstile.site_key, theme: 'light', controller: 'turnstile' }
    content_tag(:div, class: "cf-turnstile mx-2", data: data_attr) do
      ""
    end
  end
end

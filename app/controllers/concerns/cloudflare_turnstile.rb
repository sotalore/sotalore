# frozen-string-literal: true

module CloudflareTurnstile
  extend ActiveSupport::Concern

  def self.site_key
    ENV['TURNSTILE_SITE_KEY']
  end

  def self.secret_key
    ENV['TURNSTILE_SECRET_KEY']
  end

  def verify_turnstile(params)
    token = params['cf-turnstile-response']

    verify_params = {
      secret: CloudflareTurnstile.secret_key,
      response: token,
    }

    conn = Faraday.new(url: 'https://challenges.cloudflare.com')
    response = conn.post('/turnstile/v0/siteverify', verify_params)
    result = JSON.parse(response.body)
    result['success']
  end

end

# frozen-string-literal: true

module CloudflareTurnstile
  extend ActiveSupport::Concern

  def self.site_key
    Rails.application.credentials.turnstile&.site_key
  end

  def self.secret_key
    Rails.application.credentials.turnstile&.secret_key
  end

  if Rails.env.test?
    def verify_turnstile(params)
      true
    end
  else
    def verify_turnstile(params)
      token = params['cf-turnstile-response']

      verify_params = {
        secret: CloudflareTurnstile.secret_key,
        response: token,
      }

      conn = Faraday.new(url: 'https://challenges.cloudflare.com')
      response = conn.post('/turnstile/v0/siteverify', verify_params)
      result = JSON.parse(response.body)
      if !result['success']
        Rails.logger.warn("Turnstile verification failed: #{result['error-codes']}")
      end
      result['success']
    end
  end
end

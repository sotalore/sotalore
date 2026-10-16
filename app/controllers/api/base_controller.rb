# frozen_string_literal: true

# The site's API, for AI accounts using tokens an admin issued them (see
# ApiToken). Requests send "Authorization: Bearer <token>" and act as the
# token's account, through the same policies as the site. There are no
# cookies or sessions here, so no CSRF.
class Api::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include Pundit::Authorization

  before_action :authenticate_token!
  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  protected

  def pundit_user
    Current.user
  end

  # Refuses the request unless the token has +scope+.
  def require_scope!(scope)
    return if Current.api_token.allows?(scope)
    render json: { error: "This token doesn't have the #{scope} scope" }, status: :forbidden
  end

  private

  def authenticate_token!
    api_token = authenticate_with_http_token { |token, _| ApiToken.authenticate(token) }
    unless api_token
      request_http_token_authentication('SotA Lore API', 'A valid, unexpired token is required')
      return
    end
    api_token.record_use!
    Current.api_token = api_token
    Current.user = api_token.user
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
  end

  def request_http_token_authentication(realm, message)
    headers['WWW-Authenticate'] = %(Bearer realm="#{realm}")
    render json: { error: message }, status: :unauthorized
  end

  def forbidden
    render json: { error: 'Not allowed' }, status: :forbidden
  end

  def not_found
    render json: { error: 'Not found' }, status: :not_found
  end
end

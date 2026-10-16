# frozen_string_literal: true

# Who a token acts as, and what it may do: a way to check a token works.
class Api::V1::MeController < Api::BaseController
  def show
    authorize Current.api_token, :show?
    token = Current.api_token
    render json: {
      account: { id: token.user.id, name: token.user.name },
      token: { name: token.name, scopes: token.scopes, expires_at: token.expires_at&.iso8601 },
    }
  end
end

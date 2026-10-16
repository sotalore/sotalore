# frozen_string_literal: true

# Tokens for AI accounts (see ApiToken). A new token is shown once, in the
# response that makes it, and never again.
class Adm::ApiTokensController < AdmController
  EXPIRY_DAYS = [ 30, 90, 365 ].freeze

  def index
    authorize(ApiToken)
    render_index
  end

  def create
    authorize(ApiToken)
    user = User.ai_accounts.find_by(id: params[:user_id])
    days = params[:expires_in_days].to_i.presence_in(EXPIRY_DAYS)
    api_token, token = ApiToken.issue!(user: user, name: params[:name].to_s.strip,
                                       scopes: Array(params[:scopes]), created_by: Current.user,
                                       expires_at: days&.days&.from_now)
    render_index(new_token: token, new_api_token: api_token)
  rescue ActiveRecord::RecordInvalid => e
    flash.now.alert = "Couldn't make that token: #{e.record.errors.full_messages.to_sentence}"
    render_index(status: :unprocessable_content)
  end

  def revoke
    api_token = ApiToken.find(params[:id])
    authorize(api_token)
    api_token.revoke!
    redirect_to adm_api_tokens_path, notice: "Revoked #{api_token.name}."
  end

  private

  def render_index(new_token: nil, new_api_token: nil, status: :ok)
    page_title 'AI Access'
    render Views::Adm::ApiTokens::Index.new(
      accounts: User.ai_accounts.order(:name),
      tokens: ApiToken.newest_first.includes(:user, :created_by),
      new_token: new_token, new_api_token: new_api_token
    ), status: status
  end
end

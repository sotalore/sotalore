require 'rails_helper'

RSpec.describe "Adm::ApiTokens", type: :request do
  let(:admin) { create(:user, :root) }
  before { sign_in admin }

  it 'makes AI accounts and tokens, showing a token once' do
    post adm_ai_accounts_path, params: { name: 'Claude' }
    expect(response).to redirect_to(adm_api_tokens_path)
    account = User.ai_accounts.sole
    expect(account.name).to eq 'Claude'

    post adm_api_tokens_path, params: { user_id: account.id, name: 'laptop', scopes: %w[ read ],
                                        expires_in_days: '90' }
    expect(response).to have_http_status(:ok)
    api_token = ApiToken.sole
    token = response.body[/#{ApiToken::PREFIX}[1-9A-Za-z]+/o]
    expect(ApiToken.authenticate(token)).to eq api_token
    expect(api_token.expires_at).to be_within(1.minute).of(90.days.from_now)
    expect(api_token.created_by).to eq admin

    get adm_api_tokens_path
    expect(response.body).to include('data-turbo="false"')
    expect(response.body).to include('laptop', 'Claude')
    expect(response.body).not_to include(token)
  end

  it 'refuses a token for a person' do
    post adm_api_tokens_path, params: { user_id: admin.id, name: 'mine', scopes: %w[ read ] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(ApiToken.count).to eq 0
  end

  it 'revokes tokens' do
    api_token, = ApiToken.issue!(user: User.create_ai_account!(name: 'Claude'), name: 'laptop',
                                 scopes: [ 'read' ], created_by: admin)
    post revoke_adm_api_token_path(api_token)
    expect(api_token.reload).to be_revoked
  end

  it 'is only for root users' do
    sign_in create(:user, :editor)
    get adm_api_tokens_path
    expect(response).to redirect_to(root_path)
    post adm_ai_accounts_path, params: { name: 'Sneaky' }
    expect(User.ai_accounts).to be_empty
  end
end

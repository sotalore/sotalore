require 'rails_helper'

RSpec.describe "Api::V1::Me", type: :request do
  let(:admin)   { create(:user, :root) }
  let(:account) { User.create_ai_account!(name: 'Claude') }
  let(:issued)  { ApiToken.issue!(user: account, name: 'laptop', scopes: %w[ read propose ], created_by: admin) }

  def get_me(token)
    get api_v1_me_path, headers: (token ? { 'Authorization' => "Bearer #{token}" } : {})
  end

  it 'says who a token acts as' do
    api_token, token = issued
    get_me(token)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      'account' => { 'id' => account.id, 'name' => 'Claude' },
      'token' => { 'name' => 'laptop', 'scopes' => %w[ read propose ], 'expires_at' => nil })
    expect(api_token.reload.last_used_at).to be_present
  end

  it 'refuses requests without a valid token' do
    get_me(nil)
    expect(response).to have_http_status(:unauthorized)
    expect(response.headers['WWW-Authenticate']).to include 'Bearer'

    api_token, token = issued
    api_token.revoke!
    get_me(token)
    expect(response).to have_http_status(:unauthorized)
    get_me('slt_made-up')
    expect(response).to have_http_status(:unauthorized)
  end
end

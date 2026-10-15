require 'rails_helper'

RSpec.describe ApiToken do
  let(:admin)   { create(:user, :root) }
  let(:account) { User.create_ai_account!(name: 'Claude') }

  def issue(**options)
    ApiToken.issue!(user: account, name: 'laptop', scopes: [ 'read' ], created_by: admin, **options)
  end

  it 'makes AI accounts with no password, which can never sign in' do
    expect(account).to have_attributes(bot: true, roles: [], confirmed_at: be_present)
    expect(account.email).to end_with "@#{User::AI_EMAIL_DOMAIN}"
    expect(account).not_to be_can_sign_in
    account.password = 'password1'
    expect(account).not_to be_valid
  end

  it 'stores only a digest, and authenticates by the token' do
    api_token, token = issue
    expect(token).to start_with ApiToken::PREFIX
    expect(api_token.token_digest).to eq ApiToken.digest(token)
    expect(ApiToken.where(token_digest: token)).to be_empty
    expect(ApiToken.authenticate(token)).to eq api_token
    expect(ApiToken.authenticate("#{token}x")).to be_nil
    expect(ApiToken.authenticate(nil)).to be_nil
  end

  it "won't authenticate revoked or expired tokens, or ones whose account is disabled" do
    revoked, revoked_token = issue
    revoked.revoke!
    _, expired_token = issue(expires_at: 1.minute.ago)
    _, token = issue(expires_at: 1.day.from_now)
    expect(ApiToken.authenticate(revoked_token)).to be_nil
    expect(ApiToken.authenticate(expired_token)).to be_nil
    expect(ApiToken.authenticate(token)).to be_present

    account.update!(disabled: true)
    expect(ApiToken.authenticate(token)).to be_nil
  end

  it 'only belongs to AI accounts, with known scopes' do
    expect { ApiToken.issue!(user: admin, name: 'mine', scopes: [ 'read' ], created_by: admin) }
      .to raise_error(ActiveRecord::RecordInvalid, /must be an AI account/)
    expect { issue(scopes: []) }.to raise_error(ActiveRecord::RecordInvalid, /at least one/)
    expect { ApiToken.issue!(user: account, name: 'x', scopes: [ 'write' ], created_by: admin) }
      .to raise_error(ActiveRecord::RecordInvalid, /unknown write/)
  end

  it 'records use at most once a minute' do
    api_token, = issue
    api_token.record_use!
    first = api_token.reload.last_used_at
    api_token.record_use!
    expect(api_token.reload.last_used_at).to eq first
    api_token.update_column(:last_used_at, 2.minutes.ago)
    api_token.record_use!
    expect(api_token.reload.last_used_at).to be >= first
  end
end

# frozen_string_literal: true

require 'rails_helper'

# In production, Cloudflare appends the visitor to X-Forwarded-For and the
# cloudflare-rails gem trusts Cloudflare's ranges. That gem only loads in
# production, so these headers leave out Cloudflare's hop; the rest is copied
# from real scanner requests, fake headers included.
RSpec.describe "Remote IP with faked headers", type: :request do
  let!(:user) { create(:user, email: 'alice@example.com', password: 'password') }

  def sign_in_with(headers)
    post user_session_path,
      params: { user: { email: user.email, password: 'password' } },
      headers: headers
  end

  it "ignores the fake headers a scanner sends" do
    sign_in_with(
      'X-Forwarded-For' => '127.0.0.1,195.178.110.135',
      'Client-IP' => '104.55.26.204',
      'Forwarded' => 'for=localhost')

    expect(response).to redirect_to(root_path)
    expect(user.reload.last_sign_in_ip).to eq('195.178.110.135')
  end

  it "ignores a Forwarded header, which nothing in front of the app sets" do
    sign_in_with(
      'X-Forwarded-For' => '195.178.110.135',
      'Forwarded' => 'for=113.253.214.168')

    expect(response).to redirect_to(root_path)
    expect(user.reload.last_sign_in_ip).to eq('195.178.110.135')
  end
end

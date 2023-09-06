require 'rails_helper'

RSpec.describe User, type: :model do
  it 'is not null' do
    # i.e., it is not the NullUser
    expect(User.new).not_to be_null
  end

  context 'Given the root role' do
    subject { build :user, :root }
    it { is_expected.to be_moderator }
    it { is_expected.to be_root }
    it { is_expected.to be_editor }
  end

  # The oauth2 support method
  describe ".from_discord" do

    let(:email) { 'test-user@example.com' }
    let(:params) do
      {
        email: email,
        name: "Test User",
        uid: "12345",
      }
    end

    subject { User.from_discord(**params) }

    context "Given no matching email" do
      it 'creates a new user' do
        expect { subject }.to change(User, :count).by(1)
      end
    end

    context "Given a matching email, with no uid" do
      let!(:existing) { create(:user, email: email) }
      it { is_expected.to eq(existing) }
    end

    context "Given a matching email, with a different uid" do
      let!(:existing) { create(:user, email: email, uid: 'different-uid') }
      it { is_expected.to be_nil }
    end
  end
end

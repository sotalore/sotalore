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
end

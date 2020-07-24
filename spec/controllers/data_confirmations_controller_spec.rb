require 'rails_helper'

RSpec.describe DataConfirmationsController, type: :controller do

  let(:user) { create :user, :editor }
  before { sign_in user }

  describe 'POST create' do
    let(:item) { create :item }
    it 'confirms the item' do
      post :create, params: { item_id: item }
      item.reload
      expect(item.last_confirmed_at)
        .to be_within(2).of(Time.zone.now)
      expect(item.last_confirmed_by).to eq user
    end
  end
end

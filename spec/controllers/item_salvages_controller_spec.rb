require 'rails_helper'

RSpec.describe ItemSalvagesController, type: :controller do

  let!(:user)  { create :user, :root }
  before       { sign_in user }

  let(:item1) { create :item }
  let(:item2) { create :item }

  describe 'POST create' do
    it 'adds an ItemSalvage' do
      expect {
        post :create, params: { item_salvage: {
          salvage_from_id: item1.id,
          salvage_to_name: 'Ignore',
          salvage_to_id: item2.id,
        } }
      }.to change { ItemSalvage.count }.by(1)
      expect(response).to redirect_to item1
    end

    it 'handles invalid params' do
      expect {
        post :create, params: { item_salvage: {
          salvage_from_id: item1.id,
          salvage_to_name: 'Ignore',
          salvage_to_id: item1.id,
        } }
      }.to_not change { ItemSalvage.count }
      expect(response).to redirect_to item1
    end
  end

end
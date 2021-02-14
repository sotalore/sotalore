require 'rails_helper'

RSpec.describe Avatar, type: :model do

  describe 'making avatar a default' do

    let!(:user) { create :user }
    let!(:av1) { create :avatar, user: user }
    let!(:av2) { create :avatar, user: user }


    it 'unsets the previous default' do
      av1.update!(is_default: true)
      av2.update!(is_default: true)
      av1.reload
      assert !av1.is_default
    end
  end
end

require 'rails_helper'

RSpec.describe UserRecipe, type: :model do

  let(:user) { create :user }
  let(:recipe) { create :recipe }

  it 'creates' do
    expect { UserRecipe.create user: user, recipe: recipe }.to change { UserRecipe.count }.by(1)
  end

end

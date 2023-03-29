require 'rails_helper'

RSpec.describe Result, type: :model do
  let!(:item) { create :item }
  let!(:recipe) { create :recipe }
  it 'creates' do
    expect { recipe.results << Result.new(item: item, count: 1) }.to change { Result.count }.by(1)
  end
end

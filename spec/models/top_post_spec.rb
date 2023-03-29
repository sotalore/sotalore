require 'rails_helper'

RSpec.describe TopPost, type: :model do
  it 'creates' do
    expect { create :top_post, key: 'the-key' }.to change { TopPost.count }.by(1)
  end
end

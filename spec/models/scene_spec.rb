require 'rails_helper'

RSpec.describe Scene, type: :model do
  let!(:overworld) { create :scene, :overworld }
  it 'creates' do
    expect { create :scene }.to change { Scene.count }.by(1)
  end
end
